import http from "node:http";
import { URL } from "node:url";

import { getProvider } from "./providers/index.js";

const PORT = Number(process.env.PORT || 8787);
const provider = getProvider();

function sendJson(res, statusCode, payload) {
  res.writeHead(statusCode, {
    "Content-Type": "application/json; charset=utf-8",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
  });
  res.end(JSON.stringify(payload));
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let raw = "";
    req.on("data", (chunk) => {
      raw += chunk;
    });
    req.on("end", () => {
      if (!raw) {
        resolve({});
        return;
      }
      try {
        resolve(JSON.parse(raw));
      } catch (_) {
        reject(new Error("JSON invalido no corpo da requisicao."));
      }
    });
    req.on("error", reject);
  });
}

const server = http.createServer(async (req, res) => {
  if (!req.url) {
    sendJson(res, 404, { error: "Rota nao encontrada." });
    return;
  }

  if (req.method === "OPTIONS") {
    sendJson(res, 200, { ok: true });
    return;
  }

  const reqUrl = new URL(req.url, `http://${req.headers.host || "localhost"}`);

  try {
    if (req.method === "GET" && reqUrl.pathname === "/health") {
      sendJson(res, 200, {
        ok: true,
        provider: provider.name,
        environment: provider.environment,
        credentialsConfigured: provider.credentialsConfigured,
      });
      return;
    }

    if (req.method === "GET" && reqUrl.pathname === "/api/locations") {
      const keyword = (reqUrl.searchParams.get("q") || "").trim();
      const data = await provider.searchLocations(keyword);
      sendJson(res, 200, { data });
      return;
    }

    if (req.method === "POST" && reqUrl.pathname === "/api/flights/search") {
      const body = await readBody(req);
      const data = await provider.searchFlights(body);
      sendJson(res, 200, { data });
      return;
    }

    sendJson(res, 404, { error: "Rota nao encontrada." });
  } catch (error) {
    sendJson(res, error.statusCode || 500, {
      error: error.message || "Erro interno no servidor.",
    });
  }
});

server.listen(PORT, () => {
  console.log(
    `Voos Baratos backend em http://localhost:${PORT} usando provider ${provider.name}`
  );
});
