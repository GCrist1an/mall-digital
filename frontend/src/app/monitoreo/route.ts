import { destinoDelTunel, opcionesDelBuild } from "@/lib/observabilidad";

// Túnel de GlitchTip (MD-18): reenvía los eventos del navegador desde el
// servidor, sin cabeceras del visitante, para que GlitchTip no guarde su IP.

const TAMANO_MAXIMO = 1_000_000;

export async function POST(request: Request) {
  if (Number(request.headers.get("content-length")) > TAMANO_MAXIMO) {
    return new Response(null, { status: 413 });
  }

  const sobre = await request.text();
  if (sobre.length > TAMANO_MAXIMO) {
    return new Response(null, { status: 413 });
  }

  const destino = destinoDelTunel(sobre, opcionesDelBuild.dsn);
  if (!destino) {
    return new Response(null, { status: 400 });
  }

  // Solo el tipo de contenido: ni X-Forwarded-For ni otras cabeceras con la IP.
  const respuesta = await fetch(destino, {
    method: "POST",
    body: sobre,
    headers: { "Content-Type": "application/x-sentry-envelope" },
  });

  // El SDK respeta los límites de GlitchTip si le llegan estas cabeceras.
  const cabeceras = new Headers();
  for (const nombre of ["X-Sentry-Rate-Limits", "Retry-After"]) {
    const valor = respuesta.headers.get(nombre);
    if (valor) cabeceras.set(nombre, valor);
  }
  return new Response(null, { status: respuesta.status, headers: cabeceras });
}
