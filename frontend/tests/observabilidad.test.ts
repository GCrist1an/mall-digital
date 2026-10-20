import { describe, expect, it } from "vitest";
import { entornoDesde, opcionesSentry } from "@/lib/observabilidad";

const dsn = "https://clave@glitchtip.example/1";

describe("Entorno de GlitchTip", () => {
  it("reconoce preview y production", () => {
    expect(entornoDesde("preview")).toBe("preview");
    expect(entornoDesde("production")).toBe("production");
  });

  it("trata cualquier otro valor como development", () => {
    expect(entornoDesde(undefined)).toBe("development");
    expect(entornoDesde("")).toBe("development");
    expect(entornoDesde("development")).toBe("development");
  });
});

describe("Opciones de GlitchTip", () => {
  it("envía eventos en preview y production cuando hay DSN", () => {
    expect(opcionesSentry({ dsn, entorno: "preview" }).enabled).toBe(true);
    expect(opcionesSentry({ dsn, entorno: "production" }).enabled).toBe(true);
  });

  it("no envía eventos desde el entorno local aunque haya DSN", () => {
    expect(opcionesSentry({ dsn }).enabled).toBe(false);
    expect(opcionesSentry({ dsn, entorno: "development" }).enabled).toBe(false);
  });

  it("no envía eventos sin DSN", () => {
    expect(opcionesSentry({ entorno: "production" }).enabled).toBe(false);
    expect(opcionesSentry({ dsn: "", entorno: "production" }).enabled).toBe(
      false,
    );
  });

  it("no envía datos personales ni transacciones", () => {
    const opciones = opcionesSentry({ dsn, entorno: "production" });

    expect(opciones.sendDefaultPii).toBe(false);
    expect(opciones.tracesSampleRate).toBe(0);
  });

  it("usa el commit como release y lo omite si viene vacío", () => {
    expect(opcionesSentry({ dsn, release: "abc123" }).release).toBe("abc123");
    expect(opcionesSentry({ dsn, release: "" }).release).toBeUndefined();
  });
});
