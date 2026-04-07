import { apifyGoogleFlightsProvider } from "./apifyGoogleFlights.js";
import { duffelProvider } from "./duffel.js";
import { skyscannerProvider } from "./skyscanner.js";

const FLIGHTS_PROVIDER = (
  process.env.FLIGHTS_PROVIDER || "apify-google-flights"
).toLowerCase();

const providers = {
  "apify-google-flights": apifyGoogleFlightsProvider,
  apify: apifyGoogleFlightsProvider,
  duffel: duffelProvider,
  skyscanner: skyscannerProvider,
};

export function getProvider() {
  return providers[FLIGHTS_PROVIDER] || duffelProvider;
}
