import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published var rankItems: [Series] = []
    @Published var latestItems: [Series] = []
    @Published var searchResults: [Series] = []
    @Published var episodes: [Episode] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var statusText = "内置签名器就绪"

    private let client = FqAPIClient.shared

    func saveSettings() {
        errorMessage = nil
    }

    func search(_ query: String) async {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            searchResults = try await client.search(text)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadDiscovery() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            rankItems = try await client.rank(board: "hot", limit: 20)
            statusText = "签名器与数据接口正常"
        } catch {
            errorMessage = error.localizedDescription
        }
        do {
            latestItems = try await client.rank(board: "new", limit: 20)
        } catch {
            latestItems = []
        }
    }

    func loadEpisodes(_ series: Series) async -> [Episode] {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            episodes = try await client.episodes(seriesId: series.seriesId)
            return episodes
        } catch {
            errorMessage = error.localizedDescription
            return []
        }
    }

    func playbackURL(vid: String) async throws -> URL {
        statusText = "下载并离线解密中..."
        let url = try await client.downloadAndDecrypt(vid: vid)
        statusText = "已离线解密"
        return url
    }
}
