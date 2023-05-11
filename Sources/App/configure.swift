import Vapor
import Fluent
import FluentSQLiteDriver
import Jobs

// configures your application
public func configure(_ app: Application) async throws {
  // uncomment to serve files from /Public folder
  app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

  // register routes
  try routes(app)
  
  app.databases.use(.sqlite(.file("data.db")), as: .sqlite)
  app.migrations.add(CreateSong())
  app.migrations.add(CreateAlbum())
  
  app.http.server.configuration.port = Int(String(Environment.get("PORT") ?? "3000")) ?? 3000
  
  Jobs.add(interval: .hours(1)) {
    Task {
      let now = Date()
      let startTime: TimeInterval = now.timeIntervalSince1970
      print("refresh start")
      await refresh(app.db, app.client)
      let end = Date()
      let endTime: TimeInterval = end.timeIntervalSince1970
      print("refresh complete, time spent: \(endTime - startTime)")
    }
  }
}


