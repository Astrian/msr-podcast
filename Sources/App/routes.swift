import Vapor

func routes(_ app: Application) throws {
  app.get { req async in
    "It works!"
  }

  app.get("refresh") { req async -> String in
    await refresh(req)
    return "Hello, world!"
  }
}
