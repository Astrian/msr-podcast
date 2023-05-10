import SwiftAsyncNetwork
import FluentKit
import Foundation
import FluentSQLiteDriver
import Vapor


func refresh(_ req: Request) async {
  do {
    let (data, _) = try await SAN.GET("https://monster-siren.hypergryph.com/api/albums")
    let albumList = try JSONDecoder().decode(AlbumsEndpoint.self, from: data)
    for album in albumList.data {
      var albumEntity = try await Album.query(on: req.db).filter(\.$cid == album.cid).first()
      if albumEntity == nil {
        let (albumEndpointData, _) = try await SAN.GET("https://monster-siren.hypergryph.com/api/album/\(album.cid)/detail")
        let albumDetail = try JSONDecoder().decode(AlbumEndpoint.self, from: albumEndpointData)
        albumEntity = Album(albumDetail.data)
        try await albumEntity?.create(on: req.db)
        
        for song in albumDetail.data.songs {
          let (songEndpoingData, _) = try await SAN.GET("https://monster-siren.hypergryph.com/api/song/\(song.cid)")
          let songDetail = try JSONDecoder().decode(SongEndpoint.self, from: songEndpoingData)
          let songEntity = Song(songDetail.data)
          songEntity.$album.id = albumEntity!.id!
          try await songEntity.create(on: req.db)
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