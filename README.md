# 气破 · Q版

一个简单、可爱、双人对战的回合制小游戏：**双方同时出招，一起亮招结算**。

## 玩法

每回合每人各选一招（互不可见），然后一起结算：

- **攻**：打掉对手 1 颗心，并震散对手 1 点气。
- **防**：护盾 +1，最多 3 点；护盾可以挡住一次攻击。
- **聚**：气 +1，最多 5 点。
- **破防**：至少需要 3 点气，消耗全部气。若 **气 > 对手护盾**，直接获胜；否则击碎对手护盾并打掉 1 颗心。

结算顺序：先结算 **聚气 / 防守**（同一回合就能生效），再结算 **破防**，再结算 **普攻**，
最后双方伤害同时落地。气血（♥）归零即告负；若双方同回合倒下则判**平局**。

## 两种模式

- **单机同屏**：一台设备两人轮流选招，中间有全屏遮挡，选招不泄漏。
- **联网对战**：各自在自己设备上选招，通过房间码配对；服务器只转发双方选招，
  两端客户端各跑同一套确定性结算逻辑。

## 操作

- 鼠标点击底部招式卡
- 键盘 `1 / 2 / 3 / 4` 快速出招
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
- 一个窗口点「创建房间」拿到 4 位房间码；
- 另一个窗口填服务器地址 `ws://127.0.0.1:8080` 和房间码点「加入」。

> 本地要开两个客户端：可以导出后开两个程序，或用命令行再跑一个实例，
> 例如 `Godot_v4.7.2-stable_win64.exe --path .`（把 Godot 换成你的可执行文件路径）。
> 本机测试两个窗口都用 `ws://127.0.0.1:8080` 即可；跨机测试把 `127.0.0.1` 换成开服那台机器的局域网 IP。

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
> 若改用 Netlify / Cloudflare Pages 也可以，它们支持直接用 `deploy/web/_headers` 配响应头。

### 4. 填服务器地址

两种方式任选：
- 打开游戏后，在「联网对战」界面直接把 `wss://你的服务器地址` 填进「服务器」输入框；
- 或改 `scripts/main.gd` 顶部的 `DEFAULT_SERVER` 常量，重新导出。

> 注意：网页是 `https` 时，浏览器只允许连 `wss://`（不能连 `ws://`）。

## 文件

- `main.tscn`：主场景
- `scripts/main.gd`：界面、Q版角色绘制、回合逻辑、联机流程与音效
- `scripts/net_client.gd`：WebSocket 客户端（建房 / 加入 / 收发射招）
- `server/`：Node.js 房间服务器
- `export_presets.cfg`：Web 导出预设（单线程，无需跨域隔离头）
- `.github/workflows/deploy-pages.yml`：push 后自动导出并发布到 GitHub Pages
- `deploy/web/_headers`：改用 Netlify / Cloudflare Pages 时的跨域隔离头
- `render.yaml`：Render 部署配置
- `icon.svg`：项目图标
