//
//  File.swift
//  
//
//  Created by Astrian Zheng on 10/5/2023.
//

import Foundation
import Fluent
import FluentSQLiteDriver

final class Album: Model {
  static let schema = "album"
  @ID var id: UUID?
  
  @Field(key: "cid") var cid: String
  @Field(key: "name") var name: String
  @Field(key: "intro") var intro: String
  @Field(key: "belong") var belong: String
  @Field(key: "coverUrl") var coverUrl: String
  @Field(key: "coverDeUrl") var coverDeUrl: String
  @Field(key: "pubTime") var pubTime: Int
  
  @Children(for: \.$album) var song: [Song]
  
  init() {}
  
  init(_ album: AlbumEndpointEntity) {
    self.cid = album.cid
    self.name = album.name
    self.intro = album.intro
    self.belong = album.belong
    self.coverUrl = album.coverUrl
    self.coverDeUrl = album.coverDeUrl
    
    // Get now timestamp
    let now = Date()
    let timeInterval: TimeInterval = now.timeIntervalSince1970
    self.pubTime = Int(timeInterval)
  }
}

struct CreateAlbum: AsyncMigration {
  // 为存储 Galaxy 模型准备数据库。
  func prepare(on database: Database) async throws {
    try await database.schema("album")
      .id()
      .field("cid", .string)
      .field("name", .string)
      .field("intro", .string)
      .field("belong", .string)
      .field("coverUrl", .string)
      .field("coverDeUrl", .string)
      .field("pubTime", .int)
      .create()
  }
  
  // 可选地恢复 prepare 方法中所做的更改。
  func revert(on database: Database) async throws {
    try await database.schema("album").delete()
  }
}
