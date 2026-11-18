const WebSocket = require("ws");
const URL = "wss://qi-duel-server.onrender.com";

function open() {
  return new Promise((res, rej) => {
    const ws = new WebSocket(URL);
    ws.msgs = [];
    ws.on("message", (d) => ws.msgs.push(JSON.parse(d.toString())));
    ws.on("open", () => res(ws));
    ws.on("error", rej);
  });
}
function waitFor(ws, pred, ms = 15000) {
  return new Promise((res, rej) => {
    const t0 = Date.now();
    const tick = () => {
      const m = ws.msgs.find(pred);
      if (m) return res(m);
      if (Date.now() - t0 > ms) return rej(new Error("timeout"));
      setTimeout(tick, 30);
    };
    tick();
  });
}
(async () => {
  const a = await open();
  const b = await open();
  a.send(JSON.stringify({ t: "create" }));
  const created = await waitFor(a, (m) => m.t === "created");
  console.log("room:", created.room);
  b.send(JSON.stringify({ t: "join", room: created.room }));
  const [sa, sb] = await Promise.all([
    waitFor(a, (m) => m.t === "start"),
    waitFor(b, (m) => m.t === "start"),
  ]);
  console.log("seats:", sa.seat, sb.seat);
  a.send(JSON.stringify({ t: "action", action: "attack" }));
  const r1 = await waitFor(b, (m) => m.t === "action");
  b.send(JSON.stringify({ t: "action", action: "defend" }));
  const r2 = await waitFor(a, (m) => m.t === "action");
  console.log("relay:", r1.action, r2.action);
  a.close(); b.close();
  console.log("WSS_OK");
  process.exit(0);
})().catch((e) => { console.error(e); process.exit(1); });
