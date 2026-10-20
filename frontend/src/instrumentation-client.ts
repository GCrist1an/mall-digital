import * as Sentry from "@sentry/nextjs";
import { opcionesDelBuild, RUTA_DEL_TUNEL } from "@/lib/observabilidad";

Sentry.init({
  ...opcionesDelBuild,
  tunnel: RUTA_DEL_TUNEL,
  // Solo errores: sin una sesión por visita que gaste el límite de eventos.
  integrations: (porDefecto) =>
    porDefecto.filter((integracion) => integracion.name !== "BrowserSession"),
});
