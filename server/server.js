// 气破 Q版 · 联机房间服务器
// 只负责建房 / 配对 / 转发双方选招，结算逻辑在两端客户端各跑一遍。
//
// 本地测试：npm install && npm start
// 部署：Render / Railway / Fly.io 等任意支持 WebSocket 的 Node 平台，
//      监听 PORT（多数平台会自动注入）。

const http = require("http");
const { WebSocketServer } = require("ws");

const PORT = process.env.PORT || 8080;
const startedAt = Date.now();

const server = http.createServer((req, res) => {
  const path = (req.url || "/").split("?")[0];
  if (path === "/ping" || path === "/health") {
    res.writeHead(200, {
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store",
      "Access-Control-Allow-Origin": "*",
    });
    res.end(
      JSON.stringify({
        ok: true,
        service: "qi-duel",
        rooms: rooms.size,
        uptime_s: Math.floor((Date.now() - startedAt) / 1000),
        time: new Date().toISOString(),
      })
    );
    return;
  }
  res.writeHead(200, { "Content-Type": "text/plain; charset=utf-8" });
  res.end("qi-duel ws server ok");
});

const wss = new WebSocketServer({ server });

/** code -> { code, sockets: [ws|null, ws|null] } */
const rooms = new Map();

// 去掉容易看混的 0/O/1/I
const CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

function makeCode() {
  let s = "";
  for (let i = 0; i < 4; i++) s += CHARS[Math.floor(Math.random() * CHARS.length)];
  return s;
}

function send(ws, obj) {
  if (ws && ws.readyState === 1) ws.send(JSON.stringify(obj));
}

wss.on("connection", (ws) => {
  ws.meta = { room: null, seat: -1 };
  ws.isAlive = true;

  ws.on("pong", () => {
    ws.isAlive = true;
  });

  ws.on("message", (buf) => {
    let msg;
    try {
      msg = JSON.parse(buf.toString());
    } catch {
      return;
    }

    switch (msg.t) {
      case "create": {
        let code;
        do {
          code = makeCode();
        } while (rooms.has(code));
        rooms.set(code, { code, sockets: [ws, null] });
        ws.meta = { room: code, seat: 0 };
        send(ws, { t: "created", room: code });
        break;
      }

      case "join": {
        const code = String(msg.room || "").toUpperCase().trim();
        const room = rooms.get(code);
        if (!room) {
          send(ws, { t: "error", msg: "房间不存在，检查房间码" });
          break;
        }
        if (room.sockets[1]) {
          send(ws, { t: "error", msg: "房间已满" });
          break;
        }
        room.sockets[1] = ws;
        ws.meta = { room: code, seat: 1 };
        send(room.sockets[0], { t: "start", room: code, seat: 0 });
        send(room.sockets[1], { t: "start", room: code, seat: 1 });
        break;
      }

      case "action": {
        const room = rooms.get(ws.meta.room);
        if (!room) break;
        const other = room.sockets[1 - ws.meta.seat];
        send(other, { t: "action", action: String(msg.action || "") });
        break;
      }

      case "rematch": {
        const room = rooms.get(ws.meta.room);
        if (!room) break;
        const other = room.sockets[1 - ws.meta.seat];
        send(other, { t: "rematch" });
        break;
      }

      default:
        break;
    }
  });

  ws.on("close", () => {
    const room = rooms.get(ws.meta.room);
    if (!room) return;
    const other = room.sockets[1 - ws.meta.seat];
    send(other, { t: "peer_left" });
    rooms.delete(room.code);
  });
});

// 心跳，防止代理把空闲连接掐掉
const timer = setInterval(() => {
  for (const ws of wss.clients) {
    if (ws.isAlive === false) {
      ws.terminate();
      continue;
    }
    ws.isAlive = false;
    try {
      ws.ping();
    } catch {}
  }
}, 30000);

wss.on("close", () => clearInterval(timer));

server.listen(PORT, () => {
  console.log(`qi-duel server listening on ${PORT}`);
});
