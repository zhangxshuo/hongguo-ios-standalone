# HongguoIOS 完全独立版

这是无需电脑后端的 iOS 原生客户端。App 内置 Android AArch64 `libmetasec_ml.so` 仿真签名器，以及纯离线视频解密逻辑。

## 已内置

- `X-Gorgon` / `X-Argus` / `X-Ladon` / `X-Khronos` 本地签名
- 红果接口直连：榜单、剧集、视频模型
- `spade_a` → content key 纯字节解包
- MP4 CENC AES-128-CTR 视频/音频全轨解密
- 解密结果本地缓存，支持 AVPlayer 拖动

## 产物

GitHub Actions 构建的未签名 IPA：

```text
dist/HongguoIOS-unsigned.ipa
```

仓库：

```text
https://github.com/zhangxshuo/hongguo-ios-standalone
```

## 安装

1. 用全能签导入 `HongguoIOS-unsigned.ipa`。
2. 使用你自己的可用证书签名。
3. 安装后直接打开。首次加载榜单和剧集会走内置签名器；播放时会先下载并离线解密整集，然后本地播放。

## 构建

仓库的 GitHub Actions 工作流 `Build unsigned iOS IPA` 会自动：

1. 安装 XcodeGen；
2. 生成 Xcode 工程；
3. 构建未签名 IPA；
4. 上传 `HongguoIOS-unsigned` artifact。

## 说明

- App 不向电脑后端发送请求。
- 签名库源码在 `zhangxshuo/hongguo-standalone-signer`。
- `libmetasec_ml.so`、`libc++_shared.so`、`ms_16777218.bin` 随 App 打包。
- 只用于你自有软件/授权范围内的客户端兼容与离线使用。
