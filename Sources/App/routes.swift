import Vapor

func routes(_ app: Application) throws {
  app.get { req async in
    "It works!"
  }

  app.get("feed.xml") { req async -> String in
    var podcastFeedContent = """
<rss xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:sy="http://purl.org/rss/1.0/modules/syndication/" xmlns:admin="http://webns.net/mvcb/" xmlns:atom="http://www.w3.org/2005/Atom/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:content="http://purl.org/rss/1.0/modules/content/" xmlns:googleplay="http://www.google.com/schemas/play-podcasts/1.0" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" xmlns:podcast="https://github.com/Podcastindex-org/podcast-namespace/blob/main/docs/1.0.md" version="2.0" encoding="UTF-8">
  <channel>
    <title>塞壬唱片所有音乐</title>
    <link>https://thatisbiz.fireside.fm</link>
    <description>塞壬唱片所有音乐（非官方馈送）</description>
    <language>zh-cn</language>
    <itunes:type>episodic</itunes:type>
    <itunes:subtitle>塞壬唱片所有音乐（非官方馈送）</itunes:subtitle>
    <itunes:author>塞壬唱片</itunes:author>
    <itunes:summary>塞壬唱片所有音乐（非官方馈送）</itunes:summary>
    <itunes:image href="\(String(describing: Environment.get("DOMAIN")))/cover.png"/>
    <itunes:explicit>no</itunes:explicit>
    <itunes:keywords>塞壬唱片,Monster Siren Records,明日方舟</itunes:keywords>
    <itunes:owner>
      <itunes:name>Astrian</itunes:name>
      <itunes:email>msr-podcast@fakemail.astrian.moe</itunes:email>
    </itunes:owner>
    <itunes:category text="Music"/>
"""
    do {
      let albumList = try await Album.query(on: req.db).sort(\.$pubTime, .descending).all()
      for album in albumList {
        let songList = album.song
        for song in songList {
          podcastFeedContent = """
    \(podcastFeedContent)
    <item>
      <title>\(song.name)</title>
    </item>
    """
        }
      }
    } catch {
      print("error")
    }
    
    podcastFeedContent = """
    \(podcastFeedContent)
  </channel>
</rss>
"""
    return podcastFeedContent
  }
}
