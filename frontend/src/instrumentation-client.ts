import * as Sentry from "@sentry/nextjs";
import { opcionesDelBuild } from "@/lib/observabilidad";

Sentry.init({
  ...opcionesDelBuild,
  // Solo errores: sin una sesión por visita que gaste el límite de eventos.
  integrations: (porDefecto) =>
    porDefecto.filter((integracion) => integracion.name !== "BrowserSession"),
});
