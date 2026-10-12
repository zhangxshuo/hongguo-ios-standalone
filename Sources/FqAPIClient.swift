import CryptoKit
import Foundation

enum FqAPIError: LocalizedError {
    case invalidURL
    case badStatus(Int)
    case upstream(String)
    case invalidData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "接口地址无效"
        case .badStatus(let code):
            return "接口 HTTP \(code)"
        case .upstream(let message):
            return message
        case .invalidData:
            return "接口返回格式异常"
        }
    }
}

struct FqVideoTrack {
    let url: String
    let spadeA: String
    let definition: String
    let size: Int
    let backupURL: String?
}

final class FqAPIClient {
    static let shared = FqAPIClient()

    private let host = "api5-normal-sinfonlinea.fqnovel.com"
    private var baseQuery: [(String, String)] {
        [
            ("aid", "8662"),
            ("app_name", "novelread"),
            ("version_code", "72232"),
            ("version_name", "7.2.2.32"),
            ("channel", "audit"),
            ("device_platform", "android"),
            ("device_type", "audit-windows"),
            ("os_version", "12"),
            ("update_version_code", "72232"),
        ]
    }

    private var sessionHeaders: [(String, String)] {
        [
            ("user-agent", "hongguo-route-audit/1.0"),
            ("x-tt-store-region", "cn-sh"),
            ("x-tt-store-region-src", "uid"),
            ("passport-sdk-version", "5051452"),
            ("sdk-version", "2"),
        ]
    }

    func rank(board: String = "hot", limit: Int = 20) async throws -> [Series] {
        let sub: String
        switch board {
        case "recommend":
            sub = "comic_series_hot_rank"
        case "new":
            sub = "comic_series_new_rank"
        default:
            sub = "comic_series_hot_play"
        }
        let session = UUID().uuidString
        let query: [(String, String)] = [
            ("cell_id", "7470092475068071998"),
            ("tab_type", "26"),
            ("client_req_type", "2"),
            ("client_template", "2"),
            ("screen_width_px", "1350"),
            ("selected_items", "comic_series_rank"),
            ("sub_selected_items", sub),
            ("session_uuid", session),
        ]
        let json = try await request(
            method: "GET",
            path: "/reading/bookapi/bookmall/cell/change/v",
            query: query,
            signed: false
        )
        guard let data = json["data"] as? [String: Any],
              let cellView = data["cell_view"] as? [String: Any],
              let cells = cellView["cell_data"] as? [[String: Any]] else {
            return []
        }
        var result: [Series] = []
        for cell in cells {
            let video: [String: Any]
            if let list = cell["video_data"] as? [[String: Any]] {
                video = list.first ?? [:]
            } else if let value = cell["video_data"] as? [String: Any] {
                video = value
            } else {
                continue
            }
            guard let sid = string(video["series_id"]) ?? string(video["book_id"]) else {
                continue
            }
            result.append(Series(
                seriesId: sid,
                title: string(video["title"]) ?? "未命名",
                cover: string(video["cover"]),
                intro: string(video["video_desc"]),
                episodeCount: int(video["episode_cnt"]),
                vid: string(video["vid"]) ?? string(video["video_id"])
            ))
            if result.count >= limit { break }
        }
        return result
    }

    func latest(genre: String = "short_play", onlyToday: Bool = false, limit: Int = 20) async throws -> [Series] {
        try await rank(board: "new", limit: limit)
    }

    func search(_ query: String) async throws -> [Series] {
        let extra: [(String, String)] = [
            ("query", query),
            ("tab_name", "feed"),
            ("search_source", "1"),
            ("offset", "0"),
            ("count", "0"),
            ("use_correct", "true"),
        ]
        let json = try await request(
            method: "GET",
            path: "/reading/bookapi/search/tab/v",
            query: extra,
            signed: false
        )
        guard let tabs = json["search_tabs"] as? [[String: Any]],
              let data = tabs.first?["data"] as? [[String: Any]] else {
            return []
        }
        return data.compactMap { cell in
            let item = cell["video_data"] as? [String: Any] ?? cell
            guard let sid = string(item["series_id"]) ?? string(item["book_id"]) else { return nil }
            return Series(
                seriesId: sid,
                title: string(item["title"]) ?? "未命名",
                cover: string(item["cover"]),
                intro: string(item["video_desc"]),
                episodeCount: int(item["episode_cnt"]),
                vid: string(item["vid"]) ?? string(item["video_id"])
            )
        }
    }

    func episodes(seriesId: String) async throws -> [Episode] {
        let body: [String: Any] = [
            "biz_param": [
                "detail_page_version": 0,
                "disable_digg_stat": false,
                "disable_video_relate_book": false,
                "image_shrink_datas_str": "W3siaW1hZ2VfdHlwZSI6MywiaW1hZ2Vfd2lkdGgiOjkwMCwic2hyaW5rX3R5cGUiOjN9LHsiaW1hZ2VfdHlwZSI6NCwiaW1hZ2Vfd2lkdGgiOjU0LCJzaHJpbmtfdHlwZSI6NH1d\n",
                "need_all_video_definition": false,
                "need_mp4_align": false,
                "screen_width_px": "900",
                "source": 7,
                "use_os_player": false,
                "use_server_dns": false,
            ],
            "series_id": seriesId,
        ]
        let json = try await request(method: "POST", path: "/novel/player/multi_video_detail/v1/", body: body)
        guard let data = json["data"] as? [String: Any],
              let record = data[seriesId] as? [String: Any],
              let videoData = record["video_data"] as? [String: Any],
              let videos = videoData["video_list"] as? [[String: Any]] else {
            return []
        }
        return videos.compactMap { video in
            guard let vid = string(video["vid"]) else { return nil }
            return Episode(
                index: int(video["vid_index"]) ?? 0,
                vid: vid,
                title: string(video["title"]) ?? "未命名",
                duration: int(video["duration"]),
                cover: string(video["episode_cover"]) ?? string(video["cover"])
            )
        }.sorted { $0.index < $1.index }
    }

    func videoTrack(vid: String) async throws -> FqVideoTrack {
        let body: [String: Any] = [
            "biz_param": [
                "detail_page_version": 0,
                "device_level": 3,
                "disable_digg_stat": false,
                "disable_video_relate_book": false,
                "need_all_video_definition": true,
                "need_mp4_align": false,
                "use_os_player": false,
                "use_server_dns": false,
                "video_platform": 1024,
            ],
            "mixed_video_id_map": ["1": [vid]],
        ]
        let json = try await request(method: "POST", path: "/novel/player/multi_video_model/v1/", body: body)
        guard let data = json["data"] as? [String: Any],
              let record = data[vid] as? [String: Any],
              let modelText = record["video_model"] as? String,
              let modelData = modelText.data(using: .utf8),
              let model = try JSONSerialization.jsonObject(with: modelData) as? [String: Any] else {
            throw FqAPIError.invalidData
        }
        let values: [[String: Any]]
        if let list = model["video_list"] as? [[String: Any]] {
            values = list
        } else if let dict = model["video_list"] as? [String: Any] {
            values = dict.values.compactMap { $0 as? [String: Any] }
        } else {
            values = []
        }
        let candidates = values.compactMap { item -> FqVideoTrack? in
            guard let url = string(item["main_url"]),
                  let spade = string((item["encrypt_info"] as? [String: Any])?["spade_a"])
                    ?? string(item["spade_a"]) else { return nil }
            let meta = item["video_meta"] as? [String: Any] ?? [:]
            return FqVideoTrack(
                url: url,
                spadeA: spade,
                definition: string(meta["definition"]) ?? string(item["definition"]) ?? "?",
                size: int(meta["size"]) ?? int(item["size"]) ?? 0,
                backupURL: string(item["backup_url"]) ?? string(item["backup_url_1"])
            )
        }
        guard let best = candidates.max(by: { $0.size < $1.size }) else {
            throw FqAPIError.invalidData
        }
        return best
    }

    func downloadAndDecrypt(vid: String) async throws -> URL {
        let track = try await videoTrack(vid: vid)
        guard let remoteURL = URL(string: track.url) else { throw FqAPIError.invalidURL }
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let dir = caches.appendingPathComponent("hongguo-media", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let encryptedURL = dir.appendingPathComponent("\(vid)-\(track.definition).enc.mp4")
        let decryptedURL = dir.appendingPathComponent("\(vid)-\(track.definition).mp4")
        if FileManager.default.fileExists(atPath: decryptedURL.path) {
            return decryptedURL
        }
        if !FileManager.default.fileExists(atPath: encryptedURL.path) {
            let (temp, response) = try await URLSession.shared.download(from: remoteURL)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw FqAPIError.badStatus((response as? HTTPURLResponse)?.statusCode ?? -1)
            }
            try? FileManager.default.removeItem(at: encryptedURL)
            try FileManager.default.moveItem(at: temp, to: encryptedURL)
        }
        let code = track.spadeA.withCString { spade in
            encryptedURL.path.withCString { input in
                decryptedURL.path.withCString { output in
                    hongguo_decrypt_file(spade, input, output, 0)
                }
            }
        }
        guard code == 0 else {
            throw FqAPIError.upstream("离线解密失败 (\(code))")
        }
        return decryptedURL
    }

    private func request(
        method: String,
        path: String,
        query: [(String, String)] = [],
        body: [String: Any]? = nil,
        signed: Bool = true
    ) async throws -> [String: Any] {
        let allQuery = baseQuery + query + [("_rticket", String(Int64(Date().timeIntervalSince1970 * 1000)))]
        let queryText = allQuery.map { "\($0.0)=\(percentEncode($0.1))" }.joined(separator: "&")
        guard let url = URL(string: "https://\(host)\(path)?\(queryText)") else {
            throw FqAPIError.invalidURL
        }

        var headerMap: [String: String] = [:]
        var headerOrder: [String] = []
        for (name, value) in sessionHeaders {
            headerMap[name] = value
            headerOrder.append(name)
        }
        headerMap["content-type"] = "application/json; charset=utf-8"
        headerOrder.append("content-type")

        let bodyData: Data?
        if let body {
            let data = try JSONSerialization.data(withJSONObject: body, options: [])
            bodyData = data
            headerMap["x-ss-stub"] = md5Hex(data).uppercased()
            headerOrder.append("x-ss-stub")
        } else {
            bodyData = nil
        }

        if signed {
            let signatures = try FqSigner.shared.sign(
                url: url.absoluteString,
                headers: headerMap,
                order: headerOrder
            )
            for (name, value) in signatures {
                headerMap[name.lowercased()] = value
            }
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = bodyData
        request.timeoutInterval = 30
        for (name, value) in headerMap {
            request.setValue(value, forHTTPHeaderField: name)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw FqAPIError.invalidData }
        guard (200..<300).contains(http.statusCode) else { throw FqAPIError.badStatus(http.statusCode) }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw FqAPIError.invalidData
        }
        if let code = json["code"] as? Int, code != 0 {
            throw FqAPIError.upstream(string(json["message"]) ?? "上游错误 \(code)")
        }
        return json
    }

    private func percentEncode(_ value: String) -> String {
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }

    private func md5Hex(_ data: Data) -> String {
        Insecure.MD5.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private func string(_ value: Any?) -> String? {
        if let text = value as? String, !text.isEmpty { return text }
        if let number = value as? NSNumber { return number.stringValue }
        return nil
    }

    private func int(_ value: Any?) -> Int? {
        if let number = value as? Int { return number }
        if let number = value as? NSNumber { return number.intValue }
        if let text = value as? String { return Int(text) }
        return nil
    }
}
