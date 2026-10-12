import SwiftUI

struct SeriesDetailView: View {
    let series: Series

    @EnvironmentObject private var model: AppModel
    @State private var episodes: [Episode] = []
    @State private var loading = true
    @State private var errorText: String?

    var body: some View {
        List {
            Section {
                HStack(alignment: .top, spacing: 12) {
                    AsyncImage(url: series.cover.flatMap(URL.init(string:))) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            Color.secondary.opacity(0.15)
                                .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                        }
                    }
                    .frame(width: 90, height: 126)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 8) {
                        Text(series.title)
                            .font(.title3.weight(.semibold))
                        if let intro = series.intro {
                            Text(intro)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(4)
                        }
                        if let count = series.episodeCount {
                            Text("\(count) 集")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if let vid = series.vid, !vid.isEmpty {
                Section {
                    NavigationLink(destination: PlayerView(vid: vid, title: series.title)) {
                        Label("播放第一集", systemImage: "play.fill")
                    }
                }
            }

            Section("剧集") {
                if loading {
                    ProgressView()
                } else if let errorText {
                    Text(errorText).foregroundStyle(.red)
                } else if episodes.isEmpty {
                    Text("没有可播放剧集").foregroundStyle(.secondary)
                } else {
                    ForEach(episodes) { episode in
                        NavigationLink(destination: PlayerView(vid: episode.vid, title: episode.title)) {
                            HStack {
                                Text(episode.title)
                                Spacer()
                                if let duration = episode.duration, duration > 0 {
                                    Text("\(duration)s")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(series.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loading = true
            errorText = nil
            let loaded = await model.loadEpisodes(series)
            episodes = loaded
            loading = false
            errorText = loaded.isEmpty ? model.errorMessage : nil
        }
    }
}
