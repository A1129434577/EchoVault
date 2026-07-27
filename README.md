# NocturneBox

NocturneBox 是一个离线优先的本地音乐保险库。用户通过 Flutter 文件选择插件导入音频，应用会复制到自己的沙盒目录，并用 Flutter 音频插件播放。

## 已完成功能

- 本地音频导入：使用 `file_picker` 批量导入 `mp3`、`m4a`、`wav`、`aiff` 等系统可播放音频。
- 离线曲库：导入后的文件保存到 App 沙盒 `Application Support/NocturneBox/Music`。
- 纯 Flutter 播放：使用 `just_audio`，不再维护自定义 `MethodChannel`、`EventChannel` 或 Swift 播放器。
- 后台音频：`UIBackgroundModes/audio` 已配置。
- 播放控制：播放、暂停、恢复、进度条拖动、播放完成自动下一首。
- 曲库信息：使用文件名生成标题，导入时探测音频时长。
- 收藏与删除：使用 `shared_preferences` 持久化曲库，删除会同步移除沙盒音频文件。
- 智能歌单：Quick Hits、Long Ride、Saved Signal。
- 睡眠定时：5 到 120 分钟后自动暂停。
- 用户跟踪权限：已接入 ATT，便于后续广告归因和个性化广告。
- 自定义 AppIcon：已替换 Flutter 默认图标。
- 自动化验证：`flutter analyze`、`flutter test`、`flutter build ios --simulator` 已通过。

## 工程位置

```bash
/Users/liubin/Desktop/Codex Test/EchoVault
```

## 常用命令

```bash
cd "/Users/liubin/Desktop/Codex Test/EchoVault"
flutter analyze
flutter test
flutter build ios --simulator
flutter build ipa --release
```

## App Store Connect 文案草稿

名称：NocturneBox

副标题：Private offline music vault

描述：
NocturneBox keeps your personal audio collection available offline. Import music and audio files from the Files app, organize favorites, use smart crates, control playback with a sleep timer, and listen without accounts or cloud uploads.

隐私说明：
Imported audio files stay in the app sandbox on the device unless the user deletes or exports them through iOS file sharing. The app requests user tracking permission to support future ad measurement and relevant ads.

## 上线前必做

1. 在 Xcode 中打开 `ios/Runner.xcworkspace`，确认 Team、Bundle Identifier、版本号和签名证书。
2. 用真实设备测试导入不同格式音频、后台播放、锁屏后继续播放。
3. 在 App Store Connect 上传截图、隐私营养标签和年龄分级。
4. 如需支持锁屏控制中心和耳机远程控制，可继续接入 `MPNowPlayingInfoCenter` 与 `MPRemoteCommandCenter`。
