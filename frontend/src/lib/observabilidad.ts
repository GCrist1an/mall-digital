// Opciones de GlitchTip (SDK de Sentry) compartidas por el navegador y el servidor (MD-18).
// GlitchTip gratuito admite 1.000 eventos al mes: solo se envían errores,
// y nunca desde el entorno local.

export type Entorno = "development" | "preview" | "production";

export function entornoDesde(valor: string | undefined): Entorno {
  return valor === "production" || valor === "preview" ? valor : "development";
}

interface ValoresDelBuild {
  dsn?: string;
  entorno?: string;
  release?: string;
}

export function opcionesSentry({ dsn, entorno, release }: ValoresDelBuild) {
  const environment = entornoDesde(entorno);

  return {
    dsn: dsn || undefined,
    environment,
    release: release || undefined,
    enabled: Boolean(dsn) && environment !== "development",
    // Ley 1581: sin IP, cookies ni encabezados del usuario en los eventos.
    sendDefaultPii: false,
    // Sin transacciones de rendimiento: cada una contaría como evento.
    tracesSampleRate: 0,
  };
}

// Next reemplaza estos process.env en el build; por eso se nombran uno a uno.
// El entorno y el release los fija next.config.ts a partir de Vercel.
export const opcionesDelBuild = opcionesSentry({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  entorno: process.env.NEXT_PUBLIC_SENTRY_ENVIRONMENT,
  release: process.env.NEXT_PUBLIC_SENTRY_RELEASE,
});

export const esPreview = opcionesDelBuild.environment === "preview";
