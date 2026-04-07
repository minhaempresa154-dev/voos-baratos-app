import { duffelProvider } from "./duffel.js";
import { skyscannerProvider } from "./skyscanner.js";

const FLIGHTS_PROVIDER = (process.env.FLIGHTS_PROVIDER || "duffel").toLowerCase();

const providers = {
  duffel: duffelProvider,
  skyscanner: skyscannerProvider,
};

export function getProvider() {
  return providers[FLIGHTS_PROVIDER] || duffelProvider;
}
