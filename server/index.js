import http from "node:http";
import { URL } from "node:url";

const PORT = Number(process.env.PORT || 8787);
const AMADEUS_ENV = process.env.AMADEUS_ENV === "production" ? "production" : "test";
const AMADEUS_CLIENT_ID = process.env.AMADEUS_CLIENT_ID;
const AMADEUS_CLIENT_SECRET = process.env.AMADEUS_CLIENT_SECRET;
const AMADEUS_BASE_URL =
  AMADEUS_ENV === "production"
    ? "https://api.amadeus.com"
    : "https://test.api.amadeus.com";

let accessToken = null;
let accessTokenExpiresAt = 0;

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
      } catch (error) {
        reject(new Error("JSON invalido no corpo da requisicao."));
      }
    });
    req.on("error", reject);
  });
}

function ensureCredentials() {
  if (!AMADEUS_CLIENT_ID || !AMADEUS_CLIENT_SECRET) {
    const error = new Error(
      "Credenciais da Amadeus nao configuradas. Preencha AMADEUS_CLIENT_ID e AMADEUS_CLIENT_SECRET no backend."
    );
    error.statusCode = 500;
    throw error;
  }
}

async function getAccessToken() {
  ensureCredentials();

  if (accessToken && Date.now() < accessTokenExpiresAt) {
    return accessToken;
  }

  const body = new URLSearchParams({
    grant_type: "client_credentials",
    client_id: AMADEUS_CLIENT_ID,
    client_secret: AMADEUS_CLIENT_SECRET,
  });

  const response = await fetch(`${AMADEUS_BASE_URL}/v1/security/oauth2/token`, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body,
  });

  if (!response.ok) {
    const message = await response.text();
    throw new Error(`Falha ao autenticar na Amadeus: ${message}`);
  }

  const payload = await response.json();
  accessToken = payload.access_token;
  accessTokenExpiresAt = Date.now() + Math.max((payload.expires_in - 60) * 1000, 60_000);
  return accessToken;
}

async function amadeusGet(path, searchParams) {
  const token = await getAccessToken();
  const url = new URL(`${AMADEUS_BASE_URL}${path}`);
  Object.entries(searchParams).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== "") {
      url.searchParams.set(key, String(value));
    }
  });

  const response = await fetch(url, {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });

  const payload = await response.json();
  if (!response.ok) {
    const detail = payload?.errors?.[0]?.detail || payload?.errors?.[0]?.title || "Erro na API da Amadeus.";
    const error = new Error(detail);
    error.statusCode = response.status;
    throw error;
  }

  return payload;
}

function normalizeLocation(item) {
  const address = item.address || {};
  const name = item.name || item.detailedName || item.iataCode || "";
  const city = address.cityName || "";
  const country = address.countryName || "";
  return {
    id: item.id,
    iataCode: item.iataCode,
    name,
    city,
    country,
    subtitle: [city, country].filter(Boolean).join(", "),
    detailedName: item.detailedName || name,
  };
}

function normalizeOffer(offer) {
  const itinerary = offer.itineraries?.[0];
  const segments = itinerary?.segments || [];
  const firstSegment = segments[0];
  const lastSegment = segments[segments.length - 1];
  const price = offer.price || {};
  const travelerPricings = offer.travelerPricings || [];
  const fareDetails = travelerPricings.flatMap((traveler) => traveler.fareDetailsBySegment || []);
  const total = Number(price.total || 0);
  const cashAndPointsTotal = Number((total * 0.55).toFixed(2));
  const pointsEstimate = Math.round(total * 800);

  return {
    id: offer.id,
    airline: firstSegment?.carrierCode || "Companhia",
    validatingAirlineCodes: offer.validatingAirlineCodes || [],
    originCode: firstSegment?.departure?.iataCode || "",
    destinationCode: lastSegment?.arrival?.iataCode || "",
    departureAt: firstSegment?.departure?.at,
    arrivalAt: lastSegment?.arrival?.at,
    duration: itinerary?.duration || "",
    stops: Math.max(segments.length - 1, 0),
    currency: price.currency || "BRL",
    cashTotal: total,
    cashAndPointsTotal,
    cashAndPointsEstimateLabel: `R$ ${cashAndPointsTotal.toFixed(2).replace(".", ",")} + ${pointsEstimate} pts (estimativa)`,
    segments: segments.map((segment) => ({
      carrierCode: segment.carrierCode,
      number: segment.number,
      originCode: segment.departure?.iataCode,
      destinationCode: segment.arrival?.iataCode,
      departureAt: segment.departure?.at,
      arrivalAt: segment.arrival?.at,
      duration: segment.duration,
    })),
    baggageIncluded: fareDetails.some((detail) => detail.includedCheckedBags?.quantity),
    cabin: fareDetails[0]?.cabin || "ECONOMY",
  };
}

async function handleLocations(reqUrl, res) {
  const keyword = (reqUrl.searchParams.get("q") || "").trim();
  if (keyword.length < 3) {
    sendJson(res, 200, { data: [] });
    return;
  }

  const payload = await amadeusGet("/v1/reference-data/locations", {
    keyword,
    subType: "CITY,AIRPORT",
    "page[limit]": 8,
    sort: "analytics.travelers.score",
    "view": "FULL",
  });

  sendJson(res, 200, {
    data: (payload.data || []).map(normalizeLocation),
  });
}

async function handleFlights(body, res) {
  const payload = await amadeusGet("/v2/shopping/flight-offers", {
    originLocationCode: body.originCode,
    destinationLocationCode: body.destinationCode,
    departureDate: body.departureDate,
    returnDate: body.returnDate,
    adults: body.adults || 1,
    travelClass: body.cabinClass || "ECONOMY",
    currencyCode: body.currency || "BRL",
    max: body.max || 20,
    nonStop: body.nonStop ?? false,
  });

  sendJson(res, 200, {
    data: (payload.data || []).map(normalizeOffer),
    dictionaries: payload.dictionaries || {},
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
        provider: "amadeus",
        environment: AMADEUS_ENV,
        credentialsConfigured: Boolean(AMADEUS_CLIENT_ID && AMADEUS_CLIENT_SECRET),
      });
      return;
    }

    if (req.method === "GET" && reqUrl.pathname === "/api/locations") {
      await handleLocations(reqUrl, res);
      return;
    }

    if (req.method === "POST" && reqUrl.pathname === "/api/flights/search") {
      const body = await readBody(req);
      await handleFlights(body, res);
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
  console.log(`Voos Baratos backend em http://localhost:${PORT}`);
});
