"use client";

import { useState } from "react";

export function BotonesDePrueba() {
  const [estadoServidor, setEstadoServidor] = useState<string | null>(null);

  async function probarServidor() {
    setEstadoServidor("Enviando…");
    const respuesta = await fetch("/prueba-errores/servidor");
    setEstadoServidor(`El servidor respondió ${respuesta.status}.`);
  }

  return (
    <div className="mt-6 flex flex-col gap-3 sm:flex-row">
      <button
        type="button"
        onClick={() => {
          throw new Error("Prueba de GlitchTip desde el navegador (MD-18)");
        }}
        className="rounded-xl bg-brand-green px-4 py-3 font-semibold text-brand-cream"
      >
        Error en el navegador
      </button>
      <button
        type="button"
        onClick={probarServidor}
        className="rounded-xl bg-brand-yellow px-4 py-3 font-semibold text-brand-green"
      >
        Error en el servidor
      </button>
      {estadoServidor && (
        <p role="status" className="self-center">
          {estadoServidor}
        </p>
      )}
    </div>
  );
}
