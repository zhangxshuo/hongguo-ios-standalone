import Foundation

extension KeyedDecodingContainer {
    func firstString(_ keys: [Key]) -> String? {
        for key in keys {
            if let value = try? decodeIfPresent(String.self, forKey: key), !value.isEmpty {
                return value
            }
            if let value = try? decodeIfPresent(Int.self, forKey: key) {
                return String(value)
            }
        }
        return nil
    }

    func firstInt(_ keys: [Key]) -> Int? {
        for key in keys {
            if let value = try? decodeIfPresent(Int.self, forKey: key) {
                return value
            }
            if let text = try? decodeIfPresent(String.self, forKey: key), let value = Int(text) {
                return value
            }
        }
        return nil
    }
}

struct Series: Identifiable, Decodable {
    let seriesId: String
    let title: String
    let cover: String?
    let intro: String?
    let episodeCount: Int?
    let vid: String?

    var id: String { seriesId }

    init(seriesId: String, title: String, cover: String?, intro: String?, episodeCount: Int?, vid: String?) {
        self.seriesId = seriesId
        self.title = title
        self.cover = cover
        self.intro = intro
        self.episodeCount = episodeCount
        self.vid = vid
    }

    enum CodingKeys: String, CodingKey {
        case seriesId
        case series_id
        case book_id
        case id
        case title
        case series_title
        case cover
        case cover_url
        case poster
        case intro
        case description
        case series_intro
        case episodeCount
        case episode_cnt
        case vid
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        seriesId = c.firstString([.seriesId, .series_id, .book_id, .id]) ?? UUID().uuidString
        title = c.firstString([.title, .series_title]) ?? "未命名"
        cover = c.firstString([.cover, .cover_url, .poster])
        intro = c.firstString([.intro, .description, .series_intro])
        episodeCount = c.firstInt([.episodeCount, .episode_cnt])
        vid = c.firstString([.vid])
    }
}

struct SeriesMeta: Decodable {
    let seriesId: String
    let title: String
    let cover: String?
    let intro: String?
    let episodeCount: Int?

    enum CodingKeys: String, CodingKey {
        case seriesId
        case series_id
        case title
        case series_title
        case cover
        case intro
        case series_intro
        case episodeCount
        case episode_cnt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        seriesId = c.firstString([.seriesId, .series_id]) ?? UUID().uuidString
        title = c.firstString([.title, .series_title]) ?? "未命名"
        cover = c.firstString([.cover])
        intro = c.firstString([.intro, .series_intro])
        episodeCount = c.firstInt([.episodeCount, .episode_cnt])
    }
}

struct Episode: Identifiable, Decodable {
    let index: Int
    let vid: String
    let title: String
    let duration: Int?
    let cover: String?

    var id: String { vid.isEmpty ? "\(index)" : vid }

    init(index: Int, vid: String, title: String, duration: Int?, cover: String?) {
        self.index = index
        self.vid = vid
        self.title = title
        self.duration = duration
        self.cover = cover
    }

    enum CodingKeys: String, CodingKey {
        case index
        case episode
        case ep
        case vid
        case video_id
        case title
        case duration
        case cover
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        index = c.firstInt([.index, .episode, .ep]) ?? 0
        vid = c.firstString([.vid, .video_id]) ?? ""
        title = c.firstString([.title]) ?? "第\(index)集"
        duration = c.firstInt([.duration])
        cover = c.firstString([.cover])
    }
}

struct SearchResponse: Decodable {
    let results: [Series]

    enum CodingKeys: String, CodingKey {
        case results
        case items
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        results = (try? c.decodeIfPresent([Series].self, forKey: .results))
            ?? (try? c.decodeIfPresent([Series].self, forKey: .items))
            ?? []
    }
}

struct EpisodesResponse: Decodable {
    let meta: SeriesMeta?
    let episodes: [Episode]

    enum CodingKeys: String, CodingKey {
        case meta
        case episodes
        case items
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        meta = try? c.decodeIfPresent(SeriesMeta.self, forKey: .meta)
        episodes = (try? c.decodeIfPresent([Episode].self, forKey: .episodes))
            ?? (try? c.decodeIfPresent([Episode].self, forKey: .items))
            ?? []
    }
}

struct RankResponse: Decodable {
    let items: [Series]

    enum CodingKeys: String, CodingKey {
        case items
        case results
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        items = (try? c.decodeIfPresent([Series].self, forKey: .items))
            ?? (try? c.decodeIfPresent([Series].self, forKey: .results))
            ?? []
    }
}

struct LatestResponse: Decodable {
    let items: [Series]

    enum CodingKeys: String, CodingKey {
        case items
        case results
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        items = (try? c.decodeIfPresent([Series].self, forKey: .items))
            ?? (try? c.decodeIfPresent([Series].self, forKey: .results))
            ?? []
    }
}
