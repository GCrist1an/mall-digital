import type { ErrorEvent } from "@sentry/nextjs";
import { describe, expect, it } from "vitest";
import {
  destinoDelTunel,
  entornoDesde,
  limpiarBreadcrumb,
  limpiarEvento,
  opcionesSentry,
  sinConsulta,
} from "@/lib/observabilidad";

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

  it("no recoge datos del usuario, cookies, cuerpos ni consultas", () => {
    const { dataCollection } = opcionesSentry({ dsn, entorno: "production" });

    expect(dataCollection.userInfo).toBe(false);
    expect(dataCollection.cookies).toBe(false);
    expect(dataCollection.httpBodies).toEqual([]);
    expect(dataCollection.urlQueryParams).toBe(false);
    expect(dataCollection.stackFrameVariables).toBe(false);
  });

  it("solo deja la cabecera user-agent de la petición", () => {
    const { dataCollection } = opcionesSentry({ dsn, entorno: "production" });

    expect(dataCollection.httpHeaders).toEqual({
      request: { allow: ["user-agent"] },
      response: false,
    });
  });

  it("no envía transacciones", () => {
    expect(opcionesSentry({ dsn }).tracesSampleRate).toBe(0);
  });

  it("usa el commit como release y lo omite si viene vacío", () => {
    expect(opcionesSentry({ dsn, release: "abc123" }).release).toBe("abc123");
    expect(opcionesSentry({ dsn, release: "" }).release).toBeUndefined();
  });
});

describe("URLs sin consulta", () => {
  it("quita la consulta y el fragmento", () => {
    expect(sinConsulta("https://deaqui.co/tiendas?correo=a@b.co")).toBe(
      "https://deaqui.co/tiendas",
    );
    expect(sinConsulta("/carrito#paso-2")).toBe("/carrito");
    expect(sinConsulta("/pedido?id=1#x")).toBe("/pedido");
  });

  it("deja igual una URL sin consulta", () => {
    expect(sinConsulta("/tiendas")).toBe("/tiendas");
  });

  it("limpia las URLs de los breadcrumbs de fetch y de navegación", () => {
    expect(
      limpiarBreadcrumb({
        category: "fetch",
        data: { url: "/api/tiendas?telefono=300", method: "GET" },
      }).data,
    ).toEqual({ url: "/api/tiendas", method: "GET" });

    expect(
      limpiarBreadcrumb({
        category: "navigation",
        data: { from: "/?nombre=Ana", to: "/carrito?cedula=123" },
      }).data,
    ).toEqual({ from: "/", to: "/carrito" });
  });

  it("deja igual un breadcrumb sin datos", () => {
    const breadcrumb = { category: "ui.click", message: "button" };

    expect(limpiarBreadcrumb(breadcrumb)).toBe(breadcrumb);
  });

  it("limpia la petición y los breadcrumbs del evento", () => {
    const evento = limpiarEvento({
      type: undefined,
      request: { url: "https://deaqui.co/?correo=a@b.co", query_string: "x" },
      breadcrumbs: [{ data: { url: "/api?telefono=300" } }],
    } satisfies ErrorEvent);

    expect(evento.request).toEqual({ url: "https://deaqui.co/" });
    expect(evento.breadcrumbs?.[0]?.data).toEqual({ url: "/api" });
  });

  it("limpia la ruta que guarda onRequestError en el contexto nextjs", () => {
    const evento = limpiarEvento({
      type: undefined,
      contexts: {
        nextjs: {
          request_path: "/pedido?correo=ana%40correo.co&telefono=3001234567",
          route_type: "route",
        },
      },
    } satisfies ErrorEvent);

    expect(evento.contexts?.nextjs).toEqual({
      request_path: "/pedido",
      route_type: "route",
    });
  });
});

describe("Destino del túnel", () => {
  const propio = "https://clave@glitchtip.example/29005";
  const sobre = (dsnDelSobre: string) =>
    `${JSON.stringify({ dsn: dsnDelSobre, event_id: "1" })}\n{"type":"event"}\n{}`;

  it("reenvía los sobres de nuestro proyecto al endpoint de GlitchTip", () => {
    expect(destinoDelTunel(sobre(propio), propio)).toBe(
      "https://glitchtip.example/api/29005/envelope/",
    );
  });

  it("rechaza sobres de otro proyecto, otra clave u otro servidor", () => {
    expect(
      destinoDelTunel(sobre("https://clave@glitchtip.example/1"), propio),
    ).toBeNull();
    expect(
      destinoDelTunel(sobre("https://otra@glitchtip.example/29005"), propio),
    ).toBeNull();
    expect(
      destinoDelTunel(sobre("https://clave@otro.example/29005"), propio),
    ).toBeNull();
  });

  it("rechaza sobres mal formados o sin DSN propio", () => {
    expect(destinoDelTunel("no es json", propio)).toBeNull();
    expect(destinoDelTunel('{"event_id":"1"}\n{}', propio)).toBeNull();
    expect(destinoDelTunel(sobre(propio), undefined)).toBeNull();
  });
});
