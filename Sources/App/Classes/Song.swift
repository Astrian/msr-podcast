//
//  File.swift
//  
//
//  Created by Astrian Zheng on 10/5/2023.
//

import Foundation
import Fluent
import FluentSQLiteDriver

final class Song: Model {
  init() {}
  
  init(_ song: SongEndpointEntity, _ duration: Double = 0.0) {
    self.id = UUID()
    
    self.cid = song.cid
    self.lyricUrl = song.lyricUrl ?? ""
    self.mvCoverUrl = song.mvCoverUrl ?? ""
    self.mvUrl = song.mvUrl ?? ""
    self.name = song.name
    self.sourceUrl = song.sourceUrl
    self.duration = duration
    
    self.artists = ""
    if song.artists.count > 0 {
      for i in 0...(song.artists.count - 1) {
        if i == 0 {
          self.artists = song.artists[i]
        } else {
          self.artists = "\(self.artists), \(song.artists[i])"
        }
      }
    }
  }

  static let schema = "song"
  @ID var id: UUID?
  
  @Field(key: "cid") var cid: String
  @Field(key: "artists") var artists: String
  @Field(key: "lyricUrl") var lyricUrl: String
  @Field(key: "mvCoverUrl") var mvCoverUrl: String
  @Field(key: "mvUrl") var mvUrl: String
  @Field(key: "name") var name: String
  @Field(key: "sourceUrl") var sourceUrl: String
  @Field(key: "duration") var duration: Double
  
  @Parent(key: "album") var album: Album
}

struct CreateSong: AsyncMigration {
  // 为存储 Galaxy 模型准备数据库。
  func prepare(on database: Database) async throws {
    try await database.schema("song")
      .id()
      .field("cid", .string)
      .field("artists", .string)
      .field("lyricUrl", .string)
      .field("mvUrl", .string)
      .field("mvCoverUrl", .string)
      .field("name", .string)
      .field("sourceUrl", .string)
      .field("duration", .double)
      .field("album", .uuid, .required, .references("album", "id"))
      .create()
  }
  
  // 可选地恢复 prepare 方法中所做的更改。
  func revert(on database: Database) async throws {
    try await database.schema("song").delete()
  }
}
