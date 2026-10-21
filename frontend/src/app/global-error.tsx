"use client";

import * as Sentry from "@sentry/nextjs";
import { useEffect } from "react";

// Reemplaza al layout raíz cuando falla, así que no tiene sus estilos ni fuentes.
export default function GlobalError({
  error,
  retry,
}: {
  error: unknown;
  retry: () => void;
}) {
  useEffect(() => {
    Sentry.captureException(error);
  }, [error]);

  return (
    <html lang="es">
      <body
        style={{
          margin: 0,
          minHeight: "100vh",
          display: "grid",
          placeItems: "center",
          padding: "1rem",
          fontFamily: "system-ui, sans-serif",
          textAlign: "center",
          background: "#FFF4DC",
          color: "#1F4E3D",
        }}
      >
        <main>
          <title>Algo salió mal · De Aquí</title>
          <h1>Algo salió mal</h1>
          <p>Intenta de nuevo en un momento.</p>
          <button
            type="button"
            onClick={() => retry()}
            style={{
              marginTop: "1rem",
              padding: "0.75rem 1.25rem",
              border: 0,
              borderRadius: "0.75rem",
              background: "#1F4E3D",
              color: "#FFF4DC",
              font: "inherit",
              cursor: "pointer",
            }}
          >
            Intentar de nuevo
          </button>
        </main>
      </body>
    </html>
  );
}
