const SKYSCANNER_API_KEY = process.env.SKYSCANNER_API_KEY;
const SKYSCANNER_AFFILIATE_ID = process.env.SKYSCANNER_AFFILIATE_ID;
const SKYSCANNER_MARKET = process.env.SKYSCANNER_MARKET || "BR";
const SKYSCANNER_LOCALE = process.env.SKYSCANNER_LOCALE || "pt-BR";
const SKYSCANNER_CURRENCY = process.env.SKYSCANNER_CURRENCY || "BRL";

export const skyscannerProvider = {
  name: "skyscanner",
  environment: "pending_access",
  credentialsConfigured: Boolean(SKYSCANNER_API_KEY),
  async searchLocations() {
    const error = new Error(
      "Provider Skyscanner preparado na arquitetura, mas ainda depende das credenciais oficiais e aprovacao da Travel API."
    );
    error.statusCode = 501;
    throw error;
  },
  async searchFlights() {
    const missing = [];
    if (!SKYSCANNER_API_KEY) missing.push("SKYSCANNER_API_KEY");
    if (!SKYSCANNER_AFFILIATE_ID) missing.push("SKYSCANNER_AFFILIATE_ID");
    const detail = missing.length == 0
      ? "Provider Skyscanner preparado, aguardando implementacao final com credenciais aprovadas."
      : `Para ativar o provider Skyscanner, configure: ${missing.join(", ")}. Mercado padrao ${SKYSCANNER_MARKET}, locale ${SKYSCANNER_LOCALE}, moeda ${SKYSCANNER_CURRENCY}.`;
    const error = new Error(detail);
    error.statusCode = 501;
    throw error;
  },
};
