# 红果独立 iOS 版全链路审计

## 1. 目标样本与固定输入

| 文件 | SHA256 |
| --- | --- |
| hongguo-desktop-companion.exe | F9271AA2BD6B788810910AB268864D609ADF4A82F2A6671AAF06EA38149D3004 |
| libmetasec_ml.so | 20D3F8DD8D0D47E4E3C0DA0F377EAF69E72A72C8D214CA56E6E7493C65A8FC2D |
| libc++_shared.so | E8373EE43274541EFD2D34FE0588D55BF953612E1417AD47CFD2C4BD1AA383D0 |
| ms_16777218.bin | C44B4F1E213490E3518F85FA8DACE1E7D52B77D3D360EF06CC27B6562ADFB62C |

## 2. 本地签名器审计

- JNI 调用序列已与 Unidbg 对齐：
  `65539, 33554433, 33554434, 268435470, 16777233, 16777233`
- 输出头：`X-Gorgon`、`X-Argus`、`X-Ladon`、`X-Khronos`
- 修复项：
  - `__memcpy_chk` / `__memset_chk` 长度参数由错误的 `x3` 改为正确的 `x2`
  - 修复 checked memory 操作覆盖 VM 状态表导致 `0x4004ee94` 偶发崩溃
  - 仿真栈和堆显式清零，降低 TCI/JIT 环境差异
- 压力测试：连续 10 次签名 `10 / 10` 成功

## 3. 离线解密审计

- 算法链路：
  - `spade_a` -> content key
  - MP4 `senc` base IV
  - AES-128-CTR 视频/音频全轨解密
  - 解密后将 `encv/enca/sinf/senc/saiz/saio/pssh` 改为 `free`/`hvc1`/`mp4a`
- 真实样本 1：
  - 样本大小：7,071,428 字节
  - 视频样本 NAL 自证：5640 / 5640 合法
- 真实样本 2：
  - 样本大小：7,417,624 字节
  - 视频样本 NAL 自证：6671 / 6671 合法

## 4. 直连接口审计

按 Swift 端的免签榜单 + 签名详情 + 签名视频模型逻辑实测：

| 步骤 | 结果 |
| --- | --- |
| 榜单 cell_data | 10 个 |
| multi_video_detail | code 0，222 集 |
| multi_video_model | code 0，5 条轨道，顶层 `spade_a` 存在 |

修复项：

- 视频模型原始轨道使用顶层 `spade_a/size/definition`，Swift 现在同时兼容顶层和旧版嵌套结构。
- 榜单、搜索改为免签，和现有后端策略一致。
- 发现页先加载热播榜，再加载新剧榜；新剧榜失败不会清空首页。

## 5. iOS 构建审计

- 签名/解密静态库：`libhongguo_standalone_signer.a`
  - SHA256：43EDA741C8CF6557D09A9643EE87051C3B59B47798AB0EB38DF9AB346992B9BF
- 最终 ad-hoc IPA：
  - 路径：`outputs/HongguoIOS-adhoc.ipa`
  - SHA256：B94EF425942603117C9502463D5AEB90BEBFFFD386A5026CB01E92F5AD3AF46A
- IPA 根目录结构：
  - `Payload/HongguoIOS.app/HongguoIOS`
  - `Payload/HongguoIOS.app/Info.plist`
  - `Payload/HongguoIOS.app/_CodeSignature/CodeResources`
  - `Payload/HongguoIOS.app/libmetasec_ml.so`
  - `Payload/HongguoIOS.app/libc++_shared.so`
  - `Payload/HongguoIOS.app/ms_16777218.bin`
- 二进制审计确认包含：
  - `hongguo_sign`
  - `hongguo_decrypt_file`
  - `X-Gorgon`
  - `spade key unwrap failed`
- `Info.plist` 已保留：
  - `CFBundleDisplayName`
  - `MinimumOSVersion = 15.0`
  - `NSAppTransportSecurity`
  - `UISupportedInterfaceOrientations`

## 6. 当前边界

本机是 Windows，没有 iPhone/macOS 真机运行时。已完成的验证覆盖：

- 原始样本与资源哈希
- 本地 Unicorn JIT 签名压力测试
- 两段真实加密视频的全轨解密和 NAL 自证
- Swift 端接口构造逻辑的等价实测
- macOS GitHub Actions 静态库构建
- 未签名 + ad-hoc 两种 IPA 构建和 ZIP/签名结构检查

尚未在本机执行的是 iPhone 上的最终安装、系统弹窗和 AVPlayer 真机播放。若真机仍报错，需要保留新的报错原文以继续定位。
