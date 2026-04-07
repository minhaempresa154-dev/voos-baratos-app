import { searchAirportCatalog } from "./airportCatalog.js";

const APIFY_TOKEN = process.env.APIFY_TOKEN;
const APIFY_GOOGLE_FLIGHTS_ACTOR =
  process.env.APIFY_GOOGLE_FLIGHTS_ACTOR || "canadesk/google-flights";
const APIFY_TIMEOUT_SECONDS = Number(process.env.APIFY_TIMEOUT_SECONDS || 120);
const APIFY_USE_RESIDENTIAL_PROXY =
  process.env.APIFY_USE_RESIDENTIAL_PROXY !== "false";

function ensureApifyCredentials() {
  if (!APIFY_TOKEN) {
    const error = new Error(
      "Token da Apify nao configurado. Preencha APIFY_TOKEN no backend."
    );
    error.statusCode = 500;
    throw error;
  }
}

async function apifyRunSync(input) {
  ensureApifyCredentials();

  const url = new URL(
    `https://api.apify.com/v2/acts/${encodeURIComponent(
      APIFY_GOOGLE_FLIGHTS_ACTOR.replace("/", "~")
    )}/run-sync-get-dataset-items`
  );
  url.searchParams.set("token", APIFY_TOKEN);
  url.searchParams.set("format", "json");
  url.searchParams.set("clean", "true");
  url.searchParams.set("timeout", String(APIFY_TIMEOUT_SECONDS));

  const response = await fetch(url, {
    method: "POST",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      Authorization: `Bearer ${APIFY_TOKEN}`,
    },
    body: JSON.stringify(input),
  });

  const rawText = await response.text();
  const payload = rawText ? JSON.parse(rawText) : [];

  if (!response.ok) {
    const detail =
      payload?.error?.message ||
      payload?.message ||
      payload?.error ||
      "Erro na API da Apify.";
    const error = new Error(detail);
    error.statusCode = response.status;
    throw error;
  }

  if (!Array.isArray(payload)) {
    const error = new Error(
      "A resposta da Apify nao retornou uma lista de voos no formato esperado."
    );
    error.statusCode = 502;
    throw error;
  }

  return payload;
}

function mapCabinClass(value) {
  switch (value) {
    case "PREMIUM_ECONOMY":
      return "premium-economy";
    case "BUSINESS":
      return "business";
    case "FIRST":
      return "first";
    default:
      return "economy";
  }
}

function mapStops(value) {
  return value ? "0" : "select";
}

function buildApifyInput(body) {
  return {
    departureIATA: body.originCode,
    arrivalIATA: [body.destinationCode],
    departureDate: body.departureDate,
    ...(body.returnDate ? { arrivalDate: body.returnDate } : {}),
    currency: body.currency || "BRL",
    adults: Number(body.adults || 1),
    children: 0,
    infantsInSeat: 0,
    infantsOnLap: 0,
    travelClass: mapCabinClass(body.cabinClass),
    stops: mapStops(body.nonStop),
    airlines: "ALL",
    ...(APIFY_USE_RESIDENTIAL_PROXY
      ? {
          proxy: {
            useApifyProxy: true,
            apifyProxyGroups: ["RESIDENTIAL"],
          },
        }
      : {}),
  };
}

function asArray(value) {
  return Array.isArray(value) ? value : [];
}

function parseAmount(value) {
  if (typeof value === "number") return value;
  if (typeof value !== "string") return 0;
  const normalized = value.replace(/[^\d,.-]/g, "").replace(/\.(?=\d{3}\b)/g, "").replace(",", ".");
  return Number(normalized) || 0;
}

function durationToIso(value) {
  if (!value) return "";
  if (/^P(T.*)?$/i.test(value) || /^PT/i.test(value)) return value;
  if (/^\d{2}:\d{2}$/.test(value)) {
    const [hours, minutes] = value.split(":");
    return `PT${Number(hours)}H${Number(minutes)}M`;
  }

  const hourMatch = `${value}`.match(/(\d+)\s*(h|hr|hrs|hour|hours)/i);
  const minuteMatch = `${value}`.match(/(\d+)\s*(m|min|mins|minute|minutes)/i);
  const hours = Number(hourMatch?.[1] || 0);
  const minutes = Number(minuteMatch?.[1] || 0);
  if (hours === 0 && minutes === 0) return "";
  return `PT${hours}H${minutes}M`;
}

function computeCashAndPoints(amount) {
  const cashAndPointsAmount = Number((amount * 0.55).toFixed(2));
  const pointsEstimate = Math.round(amount * 800);

  return {
    cashAndPointsAmount,
    label: `R$ ${cashAndPointsAmount.toFixed(2).replace(".", ",")} + ${pointsEstimate} pts (estimativa)`,
  };
}

function readAirlineNames(item, details) {
  const detailNames = asArray(details?.airlines?.name).filter(Boolean);
  const segmentNames = readLegs(details).map((leg) => leg?.airlineName).filter(Boolean);
  const topLevelNames = asArray(item?.airlines).filter(Boolean);
  return [...new Set([...detailNames, ...segmentNames, ...topLevelNames])];
}

function readAirlineCodes(item, details) {
  const detailCodes = asArray(details?.airlines?.code).filter(Boolean);
  const segmentCodes = readLegs(details)
    .map((leg) => leg?.airlineCode)
    .filter(Boolean);
  const topLevelCodes = asArray(item?.airlineCodes || item?.airlinesCode).filter(
    Boolean
  );
  return [...new Set([...detailCodes, ...segmentCodes, ...topLevelCodes])];
}

function readLegs(details) {
  const directLegs = asArray(details?.legs);
  if (directLegs.length > 0) return directLegs;

  return [
    ...asArray(details?.departureFlights),
    ...asArray(details?.returnFlights),
    ...asArray(details?.segments),
  ];
}

function readBookingUrl(item) {
  return (
    item?.bookingUrl ||
    item?.booking_url ||
    item?.deepLink ||
    item?.deeplink ||
    item?.url ||
    item?.booking?.url ||
    item?.bookingOptions?.[0]?.url ||
    item?.details?.bookingUrl ||
    item?.details?.booking?.url ||
    null
  );
}

function normalizeSegment(leg, fallbackCabin) {
  const departureAt = leg?.departureTime || leg?.departure_time;
  const arrivalAt = leg?.arrivalTime || leg?.arrival_time;
  const flightNumber = `${leg?.airlineName || ""}${leg?.flightNumber || leg?.flight_code || ""}`.trim();

  return {
    carrierCode:
      leg?.airlineCode ||
      leg?.airlineName ||
      "",
    number: flightNumber.replace(/\s+/g, ""),
    originCode: leg?.departureAirport || leg?.origin || "",
    destinationCode: leg?.arrivalAirport || leg?.destination || "",
    departureAt,
    arrivalAt,
    duration: durationToIso(leg?.duration),
    cabin: leg?.seatClass || leg?.seat_class || fallbackCabin,
  };
}

function normalizeOffer(item, index) {
  const details = item?.details || {};
  const legs = readLegs(details);
  if (legs.length === 0) return null;

  const segments = legs
    .map((leg) => normalizeSegment(leg, item?.travelClass || "economy"))
    .filter((segment) => segment.departureAt && segment.arrivalAt);

  if (segments.length === 0) return null;

  const amount = parseAmount(item?.price);
  const airlineNames = readAirlineNames(item, details);
  const airlineCodes = readAirlineCodes(item, details);
  const firstSegment = segments[0];
  const lastSegment = segments[segments.length - 1];
  const points = computeCashAndPoints(amount);
  const bookingUrl = readBookingUrl(item);

  return {
    id: `${item?.id || item?.uuid || `${firstSegment.originCode}-${firstSegment.destinationCode}-${firstSegment.departureAt}-${index}`}`,
    airline: airlineNames[0] || "Companhia",
    validatingAirlineCodes: airlineCodes.slice(0, 3),
    flightNumber: firstSegment.number,
    originCode: firstSegment.originCode,
    destinationCode: lastSegment.destinationCode,
    departureAt: firstSegment.departureAt,
    arrivalAt: lastSegment.arrivalAt,
    duration: durationToIso(details?.duration || item?.duration || item?.total_duration),
    stops: Math.max(segments.length - 1, 0),
    currency: item?.currency || "BRL",
    cashTotal: amount,
    cashAndPointsTotal: points.cashAndPointsAmount,
    cashAndPointsEstimateLabel: points.label,
    baggageIncluded:
      item?.baggageIncluded === true ||
      item?.bagsIncluded === true ||
      item?.details?.baggageIncluded === true,
    cabin: firstSegment.cabin || item?.travelClass || "economy",
    buyUrl: bookingUrl,
    bookingProvider:
      item?.agent ||
      item?.bookingProvider ||
      airlineNames[0] ||
      "Google Flights",
    segments: segments.map((segment) => ({
      carrierCode: segment.carrierCode,
      number: segment.number,
      originCode: segment.originCode,
      destinationCode: segment.destinationCode,
      departureAt: segment.departureAt,
      arrivalAt: segment.arrivalAt,
      duration: segment.duration,
    })),
  };
}

export const apifyGoogleFlightsProvider = {
  name: "apify-google-flights",
  environment: "production_scraper",
  credentialsConfigured: Boolean(APIFY_TOKEN),
  async searchLocations(keyword) {
    return searchAirportCatalog(keyword);
  },
  async searchFlights(body) {
    const payload = await apifyRunSync(buildApifyInput(body));
    return payload
      .map((item, index) => normalizeOffer(item, index))
      .filter(Boolean)
      .slice(0, Number(body.max || 25));
  },
};
