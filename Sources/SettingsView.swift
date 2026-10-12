import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        NavigationView {
            Form {
                Section("运行模式") {
                    Label("完全独立，无需电脑后端", systemImage: "iphone.gen3")
                    Text(model.statusText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("内置能力") {
                    Text("X-Gorgon / X-Argus / X-Ladon / X-Khronos 本地签名")
                    Text("红果视频接口直连")
                    Text("spade_a → content key 离线解包")
                    Text("MP4 CENC AES-128-CTR 全轨解密")
                }

                Section("说明") {
                    Text("签名库和媒体解密均在设备本地运行，不上传账号、Cookie 或视频内容。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("首次播放会下载并解密整集，之后走本地缓存，支持拖动。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("设置")
        }
    }
}
