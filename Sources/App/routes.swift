import Vapor

func routes(_ app: Application) throws {
  app.get { req async in
    "It works!"
  }

  app.get("feed.xml") { req async in
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "E, dd MMM yyyy HH:mm:ss Z"
    dateFormatter.locale = Locale(identifier: "en_US")
    
    var podcastFeedContent = """
<rss xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:sy="http://purl.org/rss/1.0/modules/syndication/" xmlns:admin="http://webns.net/mvcb/" xmlns:atom="http://www.w3.org/2005/Atom/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:content="http://purl.org/rss/1.0/modules/content/" xmlns:googleplay="http://www.google.com/schemas/play-podcasts/1.0" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" xmlns:podcast="https://github.com/Podcastindex-org/podcast-namespace/blob/main/docs/1.0.md" version="2.0" encoding="UTF-8">
  <channel>
    <title>塞壬唱片所有音乐</title>
    <link>https://monster-siren.hypergryph.com/</link>
    <description>塞壬唱片所有音乐（非官方馈送）</description>
    <language>zh-cn</language>
    <itunes:type>episodic</itunes:type>
    <itunes:subtitle>塞壬唱片所有音乐（非官方馈送）</itunes:subtitle>
    <itunes:author>塞壬唱片</itunes:author>
    <itunes:summary>塞壬唱片所有音乐（非官方馈送）</itunes:summary>
    <itunes:image href="\(String(describing: Environment.get("DOMAIN") ?? "http://localhost:3000"))/cover.jpg"/>
    <itunes:explicit>no</itunes:explicit>
    <itunes:keywords>塞壬唱片,Monster Siren Records,明日方舟</itunes:keywords>
    <itunes:owner>
      <itunes:name>Astrian</itunes:name>
      <itunes:email>msr-podcast@fakemail.astrian.moe</itunes:email>
    </itunes:owner>
    <itunes:category text="Music"/>
"""
    let limit = Int(String(describing: Environment.get("LIMIT") ?? "0")) ?? 0
    var i = 0
    do {
      let albumList = try await Album.query(on: req.db).sort(\.$pubTime, .descending).all()
      for album in albumList {
        if i > limit && limit != 0 {
          break
        }
        let songList = try await album.$song.get(on: req.db)
        for song in songList {
          if i >= limit && limit != 0 {
            break
          }
          i = i + 1
          podcastFeedContent = """
    \(podcastFeedContent)
    
    <item>
      <title>\(song.name)</title>
      <link>https://monster-siren.hypergryph.com/music/\(song.cid)</link>
      <guid isPermaLink="false">\(song.cid)</guid>
      <pubDate>\(dateFormatter.string(from: album.pubTime))</pubDate>
      <author>\(song.artists)</author>
      <enclosure url="\(song.sourceUrl)" type="\(String(song.sourceUrl.suffix(3)) == "mp3" ? "audio/mpeg" : "audio/wav")"/>
      <itunes:episodeType>full</itunes:episodeType>
      <itunes:author>\(song.artists)</itunes:author>
      <itunes:subtitle/>
      <itunes:duration>\(formatTime(seconds: song.duration))</itunes:duration>
      <itunes:explicit>no</itunes:explicit>
      <description>收录于「\(album.name)」专辑，专辑介绍：\(album.intro.replacingOccurrences(of: "\n", with: " "))</description>
      <content:encoded><![CDATA[<p>收录于「\(album.name)」专辑。</p><blockquote>\(album.intro.replacingOccurrences(of: "\n", with: "<br>"))</blockquote><p><a href="https://monster-siren.hypergryph.com/music/\(song.cid)">在塞壬唱片官网查看</a></p>]]></content:encoded>
      <itunes:summary><![CDATA[<p>收录于「\(album.name)」专辑。</p><blockquote>\(album.intro.replacingOccurrences(of: "\n", with: "<br>"))</blockquote><p><a href="https://monster-siren.hypergryph.com/music/\(song.cid)">在塞壬唱片官网查看</a></p>]]></itunes:summary>
      <itunes:image href="\(album.coverUrl)"/>
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
    return RSSFeed(value: podcastFeedContent)
  }
}

func formatTime(seconds: Double) -> String {
  let processedMin = Int(seconds) / 60
  let processedSec = Int(seconds) % 60
  return "\(processedMin):\(processedSec < 10 ? "0" : "")\(processedSec)"
}

struct RSSFeed {
  let value: String
}

extension RSSFeed: AsyncResponseEncodable {
  public func encodeResponse(for request: Request) async throws -> Response {
    var headers = HTTPHeaders()
    headers.add(name: .contentType, value: "application/xml; charset=utf-8")
    return .init(status: .ok, headers: headers, body: .init(string: value))
  }
}
