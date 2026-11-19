# 气破 · Q版

一个简单、可爱、双人对战的回合制小游戏：**双方同时出招，一起亮招结算**。

## 玩法

四维数值（有上限，溢出无效）：

| 属性 | 上限 | 初始 |
| --- | --- | --- |
| 气血 HP | 10 | 10 |
| 攻击 ATK | 5 | 1 |
| 防御 DEF | 3 | 1 |
| 气 QI | 5 | 1 |

每回合每人各选一招（互不可见），然后一起结算：

- **攻**：对对手造成 `max(0, 自身攻击 − 对方本回合有效防御)` 点伤害（最低 0）。
- **防**：本回合自身有效防御额外 +2，用来硬吃普攻。
- **聚**：气 +1，最多 5 点。

出招时还可以把「气」分配给属性：**气 → 攻击 +1** 或 **气 → 防御 +1**，每点气换 1 点永久加成
（攻击上限 5、防御上限 3）。分配在同一回合结算时先生效，所以可以「先加点、再出招」。

结算顺序：先把双方分配的气落实为永久攻 / 防，再结算 **聚气 / 防御姿态**，最后同时结算 **普攻** 伤害。
气血归零即告负；若双方同回合倒下则判**平局**。

## 两种模式

- **单机同屏**：一台设备两人轮流选招，中间有全屏遮挡，选招不泄漏。
- **联网对战**：各自在自己设备上选招，进大厅后创建或加入房间配对；服务器只负责房间列表与转发双方选招，
  两端客户端各跑同一套确定性结算逻辑。

## 操作

- 鼠标点击底部招式卡
- 键盘 `1 / 2 / 3` 快速出招（攻 / 防 / 聚），`Q / E` 把气分配到攻击 / 防御
- 顶部「重开 / 离开」：单机重开、联机返回大厅

## 运行（单机）

用 Godot 4.7 打开本目录的 `project.godot`，按 `F5` 运行。

## 联网对战

架构：**Godot 网页客户端 + 一个很小的 Node WebSocket 服务器**。

### 1. 本地联机测试

```bash
cd server
npm install
npm start          # 默认监听 8080
```

然后在 Godot 里运行项目 →「联网对战」：
- 一个窗口点「创建房间」，进入等待；
- 另一个窗口在大厅的房间列表里点一下刚开好的房间，就能直接加入开局。

> 界面上不再需要填服务器地址或房间码。本地测试时，把 `scripts/main.gd` 顶部的
> `DEFAULT_SERVER` 临时改成 `ws://127.0.0.1:8080` 再运行即可；跨机测试把它改成开服那台机器的局域网 IP。

### 2. 部署服务器

把 `server/` 部署到任意支持 WebSocket 的 Node 平台（Render / Railway / Fly.io 等），
平台会给一个 `https://xxx` 地址，对应的 WebSocket 地址就是 `wss://xxx`。

- 监听端口用平台注入的 `PORT`（`server.js` 已处理）。
- 启动命令：`npm start`，构建命令：`npm install`。
- 仓库里带了 `render.yaml`，在 Render 用 Blueprint 可直接识别。

#### 免费实例保活（Render 会休眠）

服务器提供健康检查接口，随便一个定时任务访问即可保活：

- `GET https://<你的服务域名>/ping` → 返回 `{"ok":true,"rooms":0,"uptime_s":...}`
- 也可以用 `/health`，根路径 `/` 也会返回 200。

用 [cron-job.org](https://console.cron-job.org/jobs) 建一个 Job：
- URL 填 `https://<你的服务域名>/ping`
- 执行频率选 **每 10 分钟**（Render 免费实例约 15 分钟无请求就休眠）
- 方法 GET 即可。

### 3. 网页客户端（自动部署到 GitHub Pages）

仓库里已经带了导出预设 `export_presets.cfg` 和 workflow `.github/workflows/deploy-pages.yml`，
**不用手动导出上传**：每次 push 到 `main`，GitHub Actions 会自动用 Godot 4.7.2 导出网页并发布到 Pages。

一次性设置：

1. 打开仓库 `Settings → Pages`；
2. `Build and deployment → Source` 选 **GitHub Actions**。

之后 push 即自动构建，站点地址：`https://ctg12581.github.io/qi-duel/`。
（也可以在 Actions 页面手动点 `Run workflow`。）

> 网页版采用**单线程导出**（`variant/thread_support=false`），不需要 `SharedArrayBuffer`，
> 也不需要任何跨域隔离响应头，GitHub Pages / itch.io 等纯静态托管都能直接跑。
> 预设里还加了一小段脚本，会清掉旧版本遗留的 Service Worker 缓存在首次加载时造成的黑屏。
>
> 本地预览导出结果：`cd build/web && python -m http.server 8000`，浏览器开 `http://localhost:8000`。
>
> 也可以改用 Netlify / Cloudflare Pages，同样能自动从仓库部署，单线程构建不需要配任何响应头。

### 4. 服务器地址

客户端不再在界面上填写服务器地址，统一使用 `scripts/main.gd` 顶部的 `DEFAULT_SERVER` 常量，
改完重新导出即可。

> 注意：网页是 `https` 时，浏览器只允许连 `wss://`（不能连 `ws://`）。

## 文件

- `main.tscn`：主场景
- `scripts/main.gd`：界面、角色立绘与动作切换、回合逻辑、联机流程与音效
- `scripts/net_client.gd`：WebSocket 客户端（建房 / 加入 / 收发射招）
- `web/shell.html`：网页加载界面模板（带进度条的加载页）
- `assets/characters/`：可选角色（Doro / 咕嘎 / 鲸鱼娘）的萌系立绘与动作贴图
- `server/`：Node.js 房间服务器
- `export_presets.cfg`：Web 导出预设（单线程，无需跨域隔离头）
- `.github/workflows/deploy-pages.yml`：push 后自动导出并发布到 GitHub Pages
- `render.yaml`：Render 部署配置
- `icon.svg`：项目图标

## 素材来源

角色立绘均为网络二创/表情包素材，**仅供个人娱乐与非商业用途，请勿商用**；
如公开部署，版权风险由使用者自行承担。

- **Doro**：手游《胜利女神：妮姬》角色桃乐丝（Dorothy）的同人梗，
  素材整理自 <https://memebako.com/meme/doro>，版权归 Shift Up 所有。
- **咕嘎（咕咕嘎嘎）**：Goo Goo Ga Ga 企鹅迷因表情包，
  素材整理自 <https://memebako.com/meme/gugugaga>。
- **鲸鱼娘**：DeepSeek 鲸鱼娘（原型「溟月」by 上善无形，女仆装二创 by ZipZipPipe），
  素材整理自 <https://iphsiibl.github.io/deepseek-whale-girl-gallery/>，整体 **CC BY-NC-SA 4.0**（禁商用）。
- 中文字体：Noto Sans SC（SIL Open Font License）。
