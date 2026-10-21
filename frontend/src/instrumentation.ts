import * as Sentry from "@sentry/nextjs";
import { opcionesDelBuild } from "@/lib/observabilidad";

// Corre una vez por instancia del servidor, en el runtime nodejs y en edge.
export function register() {
  Sentry.init(opcionesDelBuild);
}

// Errores de Server Components, Route Handlers y Server Actions.
export const onRequestError = Sentry.captureRequestError;
