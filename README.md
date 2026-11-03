# QQ Bot Launcher (AstrBot + NapCat)

Windows 一键启动脚本：把 NapCat（QQ 协议端）和 AstrBot（机器人框架）按正确顺序拉起来，并自动建立 OneBot v11 反向 WebSocket 连接。

## 它解决什么

单独跑这两个程序会踩三个坑：

1. **启动顺序**：NapCat 先起、AstrBot 后起，NapCat 会一直 `ECONNREFUSED 127.0.0.1:6199`，要等下一个 30 秒重连周期。
2. **注入文件丢失**：QQ 客户端自动更新会删掉 `resources\app\loadNapCat.js`，NapCat 启动后报 `Cannot find module ... loadNapCat.js`，QQ 弹 "A JavaScript error occurred in the main process"。
3. **批处理换行**：`.bat` 必须是 CRLF。LF-only 的批处理在 cmd 下会报"系统找不到指定的路径 / 命令语法不正确"，窗口闪一下就关，看起来像"没反应"。

`start.bat` 依次处理这三件事。

## 架构

```
QQ 客户端 (NapCat 注入)
      │  OneBot v11 反向 WebSocket
      ▼
ws://127.0.0.1:6199/ws  ←  AstrBot aiocqhttp 适配器
      │
      ▼
    LLM  →  回复
```

NapCat 作为 WS 客户端主动连 AstrBot，所以 **AstrBot 必须先监听 6199**。

## 前置

| 组件 | 说明 |
|---|---|
| Windows 10/11 | 脚本用 `powershell` 查端口，系统自带 |
| QQ NT | 官方客户端，记录安装目录（默认 `E:\versions\<version>\resources\app`） |
| NapCat.Shell.Windows.Node | [releases](https://github.com/NapNeko/NapCatQQ/releases) 下载 `NapCat.Shell.Windows.Node.zip`，解压后用其中的 `launcher-user.bat` |
| AstrBot | [AstrBotDevs/AstrBot](https://github.com/AstrBotDevs/AstrBot) 桌面版或源码版，监听 6199 |

## 配置

```bat
copy config.example.bat config.bat
```

编辑 `config.bat`：

```bat
set "QQ_ACCOUNT=123456789"                    # 机器人 QQ 号
set "NAPCAT_DIR=D:\NapCat\app\napcat"         # NapCat 解压目录（含 launcher-user.bat）
set "QQ_INSTALL_DIR=E:\versions"              # QQ 的 versions 目录
set "ASTRBOT_EXE=D:\AstrBot\astrbot-desktop-tauri.exe"
```

`config.bat` 已加入 `.gitignore`，账号不会进仓库。

## 使用

```bat
start.bat
```

流程：停残留进程 → 起 AstrBot → 轮询等 6199（最多 60 秒）→ 补 `loadNapCat.js` → 起 QQ/NapCat 快速登录。

> 快速登录依赖 NapCat 缓存的登录态。缓存失效（换设备、长时间未登录）时会自动回落到二维码，二维码打印在当前控制台，同时存到 `cache\qrcode.png`。

> `start.bat` 第一步是 `taskkill /f /im QQ.exe`，会关掉本机**所有** QQ 进程，包括你正在用的个人号。

首次登录用 `login.bat`，可以输密码，也可以留空走二维码（二维码会打印在控制台，同时存到 `cache\qrcode.png`）。

二维码页面（可选）：

```bat
python qrview\serve.py
```

打开 `http://127.0.0.1:8099/`，页面每 2 秒自动刷新，NapCat 每 2 分钟换码，扫当前这张即可。

## AstrBot 侧配置

`data/cmd_config.json`：

```json
"platform": {
  "id": "default",
  "type": "aiocqhttp",
  "enable": true,
  "ws_reverse_host": "0.0.0.0",
  "ws_reverse_port": 6199,
  "ws_reverse_token": ""
}
```

NapCat 侧 `config\onebot11_<QQ号>.json`：

```json
"websocketClients": [
  {
    "name": "AstrBot",
    "enable": true,
    "url": "ws://127.0.0.1:6199/ws",
    "messagePostFormat": "array",
    "token": ""
  }
]
```

**注意**：OneBot 配置在登录成功时才加载，改完必须重启 NapCat 重新登录一次才生效。

## 排错

| 现象 | 原因 | 处理 |
|---|---|---|
| `ECONNREFUSED 127.0.0.1:6199` | AstrBot 没起或端口不对 | 先起 AstrBot，确认 6199 在监听 |
| `Cannot find module '...loadNapCat.js'` | QQ 更新后注入文件丢失 | 重跑 `start.bat`，它会自动补 |
| 窗口闪退 | bat 是 LF 换行 | 转 CRLF |
| 反向 WS 一直重连 | 路径少 `/ws` 或 token 不匹配 | 检查 URL 与 AstrBot token |
| 登录后立刻掉线 | 手机端切换了同一账号 | 换设备保持在线，或改用密码登录 |

日志：把 `config\napcat.json` 和 `config\napcat_<QQ号>.json` 里的 `fileLog` 都设为 `true`（账号级配置会覆盖全局），日志写到 `logs\`。

## 目录

```
start.bat              一键启动（AstrBot + NapCat）
login.bat              交互式登录（密码 / 二维码）
config.example.bat     配置模板
qrview/serve.py        自动刷新的二维码页面
.gitattributes         行尾规则（*.bat 强制 CRLF）
.gitignore             排除 config.bat / 日志
LICENSE                MIT
```

## License

MIT
