import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const dsn = "https://clave@glitchtip.example/29005";
const sobre = `${JSON.stringify({ dsn, event_id: "1" })}\n{"type":"event"}\n{}`;

// El DSN se fija al importar el módulo, así que cada prueba lo importa de nuevo.
async function rutaDelTunel(dsnDelBuild: string) {
  vi.stubEnv("NEXT_PUBLIC_SENTRY_DSN", dsnDelBuild);
  vi.resetModules();
  return import("@/app/monitoreo/route");
}

function peticion(cuerpo: string, cabeceras: Record<string, string> = {}) {
  return new Request("https://deaqui.co/monitoreo", {
    method: "POST",
    body: cuerpo,
    headers: cabeceras,
  });
}

describe("Túnel /monitoreo", () => {
  const fetchSimulado = vi.fn();

  beforeEach(() => {
    fetchSimulado.mockResolvedValue(
      new Response(null, {
        status: 200,
        headers: { "Retry-After": "60" },
      }),
    );
    vi.stubGlobal("fetch", fetchSimulado);
  });

  afterEach(() => {
    vi.unstubAllEnvs();
    vi.unstubAllGlobals();
    fetchSimulado.mockReset();
  });

  it("reenvía el sobre a GlitchTip sin las cabeceras del visitante", async () => {
    const { POST } = await rutaDelTunel(dsn);

    const respuesta = await POST(
      peticion(sobre, {
        "X-Forwarded-For": "181.118.155.23",
        "X-Real-IP": "181.118.155.23",
        Cookie: "sesion=abc",
      }),
    );

    expect(respuesta.status).toBe(200);
    expect(respuesta.headers.get("Retry-After")).toBe("60");
    expect(fetchSimulado).toHaveBeenCalledWith(
      "https://glitchtip.example/api/29005/envelope/",
      {
        method: "POST",
        body: sobre,
        headers: { "Content-Type": "application/x-sentry-envelope" },
      },
    );
  });

  it("no reenvía sobres de otro proyecto", async () => {
    const { POST } = await rutaDelTunel(dsn);
    const ajeno = sobre.replace("/29005", "/1");

    const respuesta = await POST(peticion(ajeno));

    expect(respuesta.status).toBe(400);
    expect(fetchSimulado).not.toHaveBeenCalled();
  });

  it("rechaza sobres demasiado grandes", async () => {
    const { POST } = await rutaDelTunel(dsn);

    const respuesta = await POST(peticion("x".repeat(1_000_001)));

    expect(respuesta.status).toBe(413);
    expect(fetchSimulado).not.toHaveBeenCalled();
  });
});
