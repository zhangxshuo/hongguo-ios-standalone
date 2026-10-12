import AVFoundation
import AVKit
import SwiftUI

struct PlayerView: View {
    let vid: String
    let title: String

    @EnvironmentObject private var model: AppModel
    @State private var player: AVPlayer?
    @State private var errorText: String?
    @State private var progressText = "准备播放..."

    var body: some View {
        VStack {
            if let player {
                VideoPlayer(player: player)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorText {
                Text(errorText)
                    .foregroundStyle(.red)
                    .padding()
            } else {
                ProgressView(progressText)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task(priority: .userInitiated) {
            await start()
        }
        .onDisappear {
            player?.pause()
        }
    }

    @MainActor
    private func start() async {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback)
            try session.setActive(true)
        } catch {
            // Continue; AVPlayer may still work without an active audio session.
        }

        do {
            progressText = "下载并离线解密中..."
            let url = try await model.playbackURL(vid: vid)
            let item = AVPlayerItem(url: url)
            let newPlayer = AVPlayer(playerItem: item)
            player = newPlayer
            progressText = "开始播放"
            newPlayer.play()
        } catch {
            errorText = error.localizedDescription
        }
    }
}
