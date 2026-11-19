// 气破 Q版 · 联机房间服务器
// 负责建房 / 房间列表 / 配对 / 转发双方选招，结算逻辑在两端客户端各跑一遍。
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
  if (ws && ws.readyState === 1) {
    try {
      ws.send(JSON.stringify(obj));
    } catch {}
  }
}

/** 等待加入的房间（不足两人）→ 大厅列表 */
function roomList() {
  const list = [];
  for (const room of rooms.values()) {
    const players = room.sockets.filter(Boolean).length;
    if (players < 2) {
      list.push({ code: room.code, players, capacity: 2 });
    }
  }
  return list;
}

/** 只给"正在浏览大厅"的连接推送房间列表 */
function sendRooms(ws) {
  if (ws.meta && ws.meta.mode === "lobby") {
    send(ws, { t: "rooms", rooms: roomList() });
  }
}

function broadcastLobby() {
  const payload = JSON.stringify({ t: "rooms", rooms: roomList() });
  for (const ws of wss.clients) {
    if (ws.readyState === 1 && ws.meta && ws.meta.mode === "lobby") {
      try {
        ws.send(payload);
      } catch {}
    }
  }
}

/** 把某个连接从它的房间里摘除；通知对手并返回大厅模式 */
function detachRoom(ws) {
  const room = rooms.get(ws.meta.room);
  if (room) {
    const other = room.sockets[1 - ws.meta.seat];
    if (other && other !== ws) {
      send(other, { t: "peer_left" });
      other.meta = { room: null, seat: -1, mode: "lobby" };
    }
    rooms.delete(room.code);
  }
  ws.meta = { room: null, seat: -1, mode: "lobby" };
}

wss.on("connection", (ws) => {
  ws.meta = { room: null, seat: -1, mode: "lobby" };
  ws.isAlive = true;

  ws.on("pong", () => {
    ws.isAlive = true;
  });

  // 一进来就把当前可加入的房间列表发过去
  sendRooms(ws);

  ws.on("message", (buf) => {
    let msg;
    try {
      msg = JSON.parse(buf.toString());
    } catch {
      return;
    }

    switch (msg.t) {
      case "list": {
        sendRooms(ws);
        break;
      }

      case "create": {
        if (ws.meta.room) detachRoom(ws);
        let code;
        do {
          code = makeCode();
        } while (rooms.has(code));
        rooms.set(code, { code, sockets: [ws, null] });
        ws.meta = { room: code, seat: 0, mode: "waiting" };
        // 不给客户端看房间码，创建者只需等待
        send(ws, { t: "created" });
        broadcastLobby();
        break;
      }

      case "join": {
        const code = String(msg.room || "").toUpperCase().trim();
        const room = rooms.get(code);
        if (!room) {
          send(ws, { t: "error", msg: "房间不存在或已开始，刷新看看吧" });
          break;
        }
        if (room.sockets[1]) {
          send(ws, { t: "error", msg: "房间已满，换个房间试试" });
          break;
        }
        if (ws.meta.room) detachRoom(ws);
        room.sockets[1] = ws;
        room.sockets[0].meta.mode = "playing";
        ws.meta = { room: code, seat: 1, mode: "playing" };
        send(room.sockets[0], { t: "start", seat: 0 });
        send(room.sockets[1], { t: "start", seat: 1 });
        broadcastLobby();
        break;
      }

      case "leave": {
        if (ws.meta.room) {
          detachRoom(ws);
          broadcastLobby();
        }
        sendRooms(ws);
        break;
      }

      case "action": {
        const room = rooms.get(ws.meta.room);
        if (!room) break;
        const other = room.sockets[1 - ws.meta.seat];
        send(other, { t: "action", action: String(msg.action || ""), atk_add: intOr(msg.atk_add), def_add: intOr(msg.def_add) });
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
    if (ws.meta.room) {
      detachRoom(ws);
      broadcastLobby();
    }
  });
});

function intOr(v) {
  const n = parseInt(v, 10);
  return Number.isFinite(n) ? n : 0;
}

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
