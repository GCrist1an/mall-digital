// Opciones de GlitchTip (SDK de Sentry) compartidas por el navegador y el servidor (MD-18).
// GlitchTip gratuito admite 1.000 eventos al mes: solo se envían errores,
// y nunca desde el entorno local.

import type { Breadcrumb, ErrorEvent, init } from "@sentry/nextjs";

type OpcionesDeInit = NonNullable<Parameters<typeof init>[0]>;

export type Entorno = "development" | "preview" | "production";

export function entornoDesde(valor: string | undefined): Entorno {
  return valor === "production" || valor === "preview" ? valor : "development";
}

// Quita la consulta (?…) y el fragmento (#…) de una URL, por si llevan datos personales.
export function sinConsulta(url: string): string {
  const corte = url.search(/[?#]/);
  return corte === -1 ? url : url.slice(0, corte);
}

// fetch y xhr guardan la URL en `url`; la navegación, en `from` y `to`.
const CAMPOS_CON_URL = ["url", "from", "to"] as const;

export function limpiarBreadcrumb(breadcrumb: Breadcrumb): Breadcrumb {
  if (!breadcrumb.data) return breadcrumb;

  const data = { ...breadcrumb.data };
  for (const campo of CAMPOS_CON_URL) {
    const valor = data[campo];
    if (typeof valor === "string") data[campo] = sinConsulta(valor);
  }
  return { ...breadcrumb, data };
}

// Red de seguridad sobre dataCollection.urlQueryParams: revisa el evento completo antes de enviarlo.
export function limpiarEvento(event: ErrorEvent): ErrorEvent {
  if (event.request) {
    const { query_string: _consulta, ...request } = event.request;
    if (request.url) request.url = sinConsulta(request.url);
    event.request = request;
  }
  if (event.breadcrumbs) {
    event.breadcrumbs = event.breadcrumbs.map(limpiarBreadcrumb);
  }
  // onRequestError guarda la ruta pedida, con su consulta, en este contexto.
  const nextjs = event.contexts?.nextjs;
  if (nextjs && typeof nextjs.request_path === "string") {
    nextjs.request_path = sinConsulta(nextjs.request_path);
  }
  return event;
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
    // Ley 1581: en el SDK 11, dataCollection reemplaza a sendDefaultPii y por
    // defecto lo recoge todo. Aquí solo se deja el user-agent, útil para reproducir errores.
    dataCollection: {
      userInfo: false,
      cookies: false,
      httpHeaders: { request: { allow: ["user-agent"] }, response: false },
      httpBodies: [],
      urlQueryParams: false,
      graphQL: { document: false, variables: false },
      genAI: { inputs: false, outputs: false },
      databaseQueryData: false,
      queues: false,
      stackFrameVariables: false,
    },
    beforeBreadcrumb: limpiarBreadcrumb,
    beforeSend: limpiarEvento,
    // Sin transacciones de rendimiento: cada una contaría como evento.
    tracesSampleRate: 0,
  } satisfies OpcionesDeInit;
}

// Next reemplaza estos process.env en el build; por eso se nombran uno a uno.
// El entorno y el release los fija next.config.ts a partir de Vercel.
export const opcionesDelBuild = opcionesSentry({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  entorno: process.env.NEXT_PUBLIC_SENTRY_ENVIRONMENT,
  release: process.env.NEXT_PUBLIC_SENTRY_RELEASE,
});

export const esPreview = opcionesDelBuild.environment === "preview";

// El navegador envía sus eventos a esta ruta propia y Vercel los reenvía a GlitchTip.
// Así GlitchTip registra la IP del servidor de Vercel y no la del visitante.
export const RUTA_DEL_TUNEL = "/monitoreo";

// Devuelve el endpoint de GlitchTip para un sobre (envelope) del túnel, o null si
// el sobre no es de nuestro proyecto: el túnel no reenvía a ningún otro destino.
export function destinoDelTunel(
  sobre: string,
  dsnPropio: string | undefined,
): string | null {
  if (!dsnPropio) return null;

  try {
    const cabecera: unknown = JSON.parse(sobre.split("\n", 1)[0] ?? "");
    if (typeof cabecera !== "object" || cabecera === null) return null;
    if (!("dsn" in cabecera) || typeof cabecera.dsn !== "string") return null;

    const recibido = new URL(cabecera.dsn);
    const propio = new URL(dsnPropio);
    if (
      recibido.origin !== propio.origin ||
      recibido.username !== propio.username ||
      recibido.pathname !== propio.pathname
    ) {
      return null;
    }

    const proyecto = propio.pathname.replace(/^\/+|\/+$/g, "");
    return `${propio.origin}/api/${proyecto}/envelope/`;
  } catch {
    return null;
  }
}
