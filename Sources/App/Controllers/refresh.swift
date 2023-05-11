import FluentKit
import Foundation
import FluentSQLiteDriver
import Vapor
import AVFoundation


func refresh(_ db: Database, _ client: Client) async {
  do {
    let data = try await client.get("https://monster-siren.hypergryph.com/api/albums")
    let albumList = try data.content.decode(AlbumsEndpoint.self)
    for album in albumList.data {
      var albumEntity = try await Album.query(on: db).filter(\.$cid == album.cid).first()
      if albumEntity == nil {
        let albumEndpointData = try await client.get("https://monster-siren.hypergryph.com/api/album/\(album.cid)/detail")
        let albumDetail = try albumEndpointData.content.decode(AlbumEndpoint.self)
        albumEntity = Album(albumDetail.data)
        try await albumEntity?.create(on: db)
        try await albumEntity?.save(on: db)
        
        for song in albumDetail.data.songs {
          let songEndpoingData = try await client.get("https://monster-siren.hypergryph.com/api/song/\(song.cid)")
          let songDetail = try songEndpoingData.content.decode(SongEndpoint.self)
          let duration = getAudioFileDuration(url: URL(string: songDetail.data.sourceUrl)!)
          let size = 0
          let songEntity = Song(songDetail.data, duration ?? 0.0, size)
          try await albumEntity?.$song.create(songEntity, on: db)
          try await songEntity.save(on: db)
        }
      }
    }
  } catch {
    print(error)
  }
}

struct SongsEndpoint: Decodable {
  let code: Int
  let msg: String
  let data: SongsEndpointData
}

struct SongsEndpointData: Decodable {
  let autoplay: Bool?
  let list: [SongsEndpointEntity]
}

struct SongEndpoint: Decodable {
  let code: Int
  let msg: String
  let data: SongEndpointEntity
}

struct SongEndpointEntity: Decodable {
  let cid: String
  let name: String
  let albumCid: String
  let sourceUrl: String
  let lyricUrl: String?
  let mvUrl: String?
  let mvCoverUrl: String?
  let artists: [String]
}

struct SongsEndpointEntity: Decodable {
  let cid: String
  let name: String
  let albumCid: String
  let artists: [String]
}

struct AlbumEndpoint: Decodable {
  let code: Int
  let msg: String
  let data: AlbumEndpointEntity
}

struct AlbumsEndpoint: Decodable {
  let code: Int
  let msg: String
  let data: [AlbumsEndpointEntity]
}

struct AlbumsEndpointEntity: Decodable {
  let cid: String
  let name: String
  let coverUrl: String
  let artistes: [String]
}

struct AlbumsEndpointEntitySongs: Decodable {
  let cid: String
  let name: String
  let artistes: [String]
}

struct AlbumEndpointEntity: Decodable {
  let cid: String
  let name: String
  let intro: String
  let belong: String
  let coverUrl: String
  let coverDeUrl: String
  let songs: [AlbumsEndpointEntitySongs]
}

func getAudioFileDuration(url: URL) -> Double? {
  let asset = AVURLAsset(url: url)
  let audioDuration = asset.duration
  return CMTimeGetSeconds(audioDuration)
}
