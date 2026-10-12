import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        TabView {
            DiscoverView()
                .tabItem {
                    Label("发现", systemImage: "flame")
                }
            SearchView()
                .tabItem {
                    Label("搜索", systemImage: "magnifyingglass")
                }
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape")
                }
        }
    }
}

private struct DiscoverView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        NavigationView {
            ZStack {
                List {
                    if !model.rankItems.isEmpty {
                        Section("热播榜") {
                            ForEach(model.rankItems) { series in
                                NavigationLink(destination: SeriesDetailView(series: series)) {
                                    SeriesRow(series: series)
                                }
                            }
                        }
                    }
                    if !model.latestItems.isEmpty {
                        Section("最新上架") {
                            ForEach(model.latestItems) { series in
                                NavigationLink(destination: SeriesDetailView(series: series)) {
                                    SeriesRow(series: series)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await model.loadDiscovery()
                }

                if model.isLoading && model.rankItems.isEmpty && model.latestItems.isEmpty {
                    ProgressView()
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if !model.isLoading && model.rankItems.isEmpty && model.latestItems.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "flame")
                            .font(.system(size: 44))
                            .foregroundStyle(.secondary)
                        Text("内置签名器就绪，下拉加载")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("发现")
            .task {
                if model.rankItems.isEmpty && model.latestItems.isEmpty {
                    await model.loadDiscovery()
                }
            }
            .alert("请求失败", isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } }
            )) {
                Button("好", role: .cancel) {}
            } message: {
                Text(model.errorMessage ?? "")
            }
        }
    }
}

private struct SearchView: View {
    @EnvironmentObject private var model: AppModel
    @State private var query = ""

    var body: some View {
        NavigationView {
            ZStack {
                List(model.searchResults) { series in
                    NavigationLink(destination: SeriesDetailView(series: series)) {
                        SeriesRow(series: series)
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await model.search(query)
                }

                if model.searchResults.isEmpty && !model.isLoading {
                    VStack(spacing: 12) {
                        Image(systemName: "play.rectangle.on.rectangle")
                            .font(.system(size: 44))
                            .foregroundStyle(.secondary)
                        Text("输入剧名搜索")
                            .foregroundStyle(.secondary)
                    }
                }

                if model.isLoading {
                    ProgressView()
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .navigationTitle("红果 iOS")
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索短剧")
            .onSubmit(of: .search) {
                Task { await model.search(query) }
            }
            .alert("请求失败", isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } }
            )) {
                Button("好", role: .cancel) {}
            } message: {
                Text(model.errorMessage ?? "")
            }
        }
    }
}

private struct SeriesRow: View {
    let series: Series

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: series.cover.flatMap(URL.init(string:))) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Color.secondary.opacity(0.15)
                        .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                }
            }
            .frame(width: 68, height: 96)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 6) {
                Text(series.title)
                    .font(.headline)
                    .lineLimit(2)
                if let intro = series.intro, !intro.isEmpty {
                    Text(intro)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                if let count = series.episodeCount {
                    Text("\(count) 集")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
