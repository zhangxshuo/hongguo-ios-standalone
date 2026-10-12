# HongguoIOS

这是一个可安装的 iOS 原生壳，配现有 Python 后端使用。

## 能力

- 发现页：热播榜 + 最新上架
- 搜索（当前可能被上游 `param_invalid` 拒绝）
- 查看剧集
- 使用系统 `AVPlayer` 播放
- 后端地址和 API Key 可在 App 内设置

已实测通过的后端接口：

```text
/rank
/latest
/episodes
/stream
```

`/search` 当前会返回上游 `code=100103 param_invalid`，所以首页默认是发现页，不用搜索也能浏览和播放。

## 架构

```text
iOS SwiftUI App
  -> http://<电脑局域网IP>:8000
    -> remote_server.py
      -> 现有 Python 后端
      -> FqTrace Java 签名器
      -> fqnovel API
      -> AES-128-CTR 解密
```

这个版本不是“完全独立 iOS 版”。它不包含把 `libmetasec_ml.so` 的 Android AArch64 签名算法移植到 iOS 的部分。

## 构建 unsigned IPA

1. 把这个目录推到一个 GitHub 仓库。
2. 打开仓库的 Actions。
3. 运行 `Build unsigned iOS IPA`。
4. 下载 `HongguoIOS-unsigned` artifact。
5. 解压得到 `HongguoIOS-unsigned.ipa`。
6. 用全能签签名安装。全能签需要你自己的可用证书。

用 `gh` 可以直接这样：

```bash
cd outputs/HongguoIOS
git init
git add .
git commit -m "Hongguo iOS client"
gh auth login
gh repo create hongguo-ios --public --source . --push
gh run watch
gh run download --name HongguoIOS-unsigned
```

## 使用

先在电脑上跑后端：

```powershell
cd C:\Users\jiang\AppData\Local\红果免费短剧\backend
.\python\python.exe remote_server.py
```

记下 `remote_server.py` 打印的：

```text
API Key: <64位十六进制>
监听: 0.0.0.0:8000
```

然后在 iOS App 设置里填：

```text
后端: http://<电脑局域网IP>:8000
API Key: <remote_server.py 打印的值>
```

手机和电脑需要在同一个局域网。Windows 防火墙需要允许 Python 的专用网络入站。
