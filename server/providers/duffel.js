const DUFFEL_ACCESS_TOKEN = process.env.DUFFEL_ACCESS_TOKEN;
const DUFFEL_MODE = process.env.DUFFEL_MODE === "live" ? "live" : "test";
const DUFFEL_BASE_URL = "https://api.duffel.com";
const DUFFEL_VERSION = "v2";

function ensureDuffelCredentials() {
  if (!DUFFEL_ACCESS_TOKEN) {
    const error = new Error(
      "Token da Duffel nao configurado. Preencha DUFFEL_ACCESS_TOKEN no backend."
    );
    error.statusCode = 500;
    throw error;
  }
}

async function duffelRequest(path, { method = "GET", query, body } = {}) {
  ensureDuffelCredentials();

  const url = new URL(`${DUFFEL_BASE_URL}${path}`);
  Object.entries(query || {}).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== "") {
      url.searchParams.set(key, String(value));
    }
  });

  const response = await fetch(url, {
    method,
    headers: {
      Accept: "application/json",
      Authorization: `Bearer ${DUFFEL_ACCESS_TOKEN}`,
      "Duffel-Version": DUFFEL_VERSION,
      ...(body ? { "Content-Type": "application/json" } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });

  const payload = await response.json();
  if (!response.ok) {
    const detail =
      payload?.errors?.[0]?.message ||
      payload?.errors?.[0]?.title ||
      payload?.error ||
      "Erro na API da Duffel.";
    const error = new Error(detail);
    error.statusCode = response.status;
    throw error;
  }

  return payload;
}

function normalizeLocation(item) {
  const cityName = item.city_name || item.city?.name || "";
  const countryCode = item.iata_country_code || "";
  const name = item.name || "";
  return {
    id: item.id,
    iataCode: item.iata_code,
    name,
    city: cityName,
    country: countryCode,
    subtitle: [cityName, countryCode].filter(Boolean).join(", "),
  };
}

function normalizeOffer(offer) {
  const slice = offer.slices?.[0];
  const segments = slice?.segments || [];
  const firstSegment = segments[0];
  const lastSegment = segments[segments.length - 1];
  const amount = Number(offer.total_amount || 0);
  const cashAndPointsAmount = Number((amount * 0.55).toFixed(2));
  const pointsEstimate = Math.round(amount * 800);

  return {
    id: offer.id,
    airline:
      firstSegment?.operating_carrier?.name ||
      firstSegment?.marketing_carrier?.name ||
      "Companhia",
    validatingAirlineCodes: [
      firstSegment?.marketing_carrier?.iata_code,
      firstSegment?.operating_carrier?.iata_code,
    ].filter(Boolean),
    flightNumber:
      `${firstSegment?.marketing_carrier?.iata_code || ""}${firstSegment?.marketing_carrier_flight_number || ""}`,
    originCode: firstSegment?.origin?.iata_code || "",
    destinationCode: lastSegment?.destination?.iata_code || "",
    departureAt: firstSegment?.departing_at,
    arrivalAt: lastSegment?.arriving_at,
    duration: slice?.duration || "",
    stops: Math.max(segments.length - 1, 0),
    currency: offer.total_currency || "BRL",
    cashTotal: amount,
    cashAndPointsTotal: cashAndPointsAmount,
    cashAndPointsEstimateLabel: `R$ ${cashAndPointsAmount
      .toFixed(2)
      .replace(".", ",")} + ${pointsEstimate} pts (estimativa)`,
    baggageIncluded: offer.conditions?.change_before_departure?.allowed ?? false,
    cabin: segments[0]?.cabin_class || "economy",
    buyUrl: null,
    bookingProvider:
      firstSegment?.operating_carrier?.name ||
      firstSegment?.marketing_carrier?.name ||
      "Parceiro da oferta",
    segments: segments.map((segment) => ({
      carrierCode:
        segment.marketing_carrier?.iata_code ||
        segment.operating_carrier?.iata_code ||
        "",
      number: segment.marketing_carrier_flight_number || "",
      originCode: segment.origin?.iata_code || "",
      destinationCode: segment.destination?.iata_code || "",
      departureAt: segment.departing_at,
      arrivalAt: segment.arriving_at,
      duration: segment.duration || "",
    })),
  };
}

function buildPassengers(adults) {
  return Array.from({ length: adults }, () => ({ type: "adult" }));
}

function buildSlices(body) {
  const slices = [
    {
      origin: body.originCode,
      destination: body.destinationCode,
      departure_date: body.departureDate,
    },
  ];

  if (body.returnDate) {
    slices.push({
      origin: body.destinationCode,
      destination: body.originCode,
      departure_date: body.returnDate,
    });
  }

  return slices;
}

function mapCabinClass(value) {
  switch (value) {
    case "PREMIUM_ECONOMY":
      return "premium_economy";
    case "BUSINESS":
      return "business";
    case "FIRST":
      return "first";
    default:
      return "economy";
  }
}

export const duffelProvider = {
  name: "duffel",
  environment: DUFFEL_MODE,
  credentialsConfigured: Boolean(DUFFEL_ACCESS_TOKEN),
  async searchLocations(keyword) {
    if (keyword.trim().length < 3) return [];
    const payload = await duffelRequest("/places/suggestions", {
      query: {
        query: keyword,
        limit: 8,
      },
    });
    return (payload.data || []).map(normalizeLocation);
  },
  async searchFlights(body) {
    const payload = await duffelRequest("/air/offer_requests", {
      method: "POST",
      query: { return_offers: true },
      body: {
        data: {
          cabin_class: mapCabinClass(body.cabinClass),
          max_connections: body.nonStop ? 0 : 2,
          passengers: buildPassengers(Number(body.adults || 1)),
          slices: buildSlices(body),
        },
      },
    });

    return (payload.data?.offers || []).map(normalizeOffer);
  },
};
