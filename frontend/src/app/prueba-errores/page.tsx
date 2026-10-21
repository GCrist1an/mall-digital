import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { esPreview } from "@/lib/observabilidad";
import { BotonesDePrueba } from "./botones-de-prueba";

// Ruta para probar GlitchTip en los despliegues de preview (MD-18).
// En producción y en local responde 404: se decide en el build.

export const metadata: Metadata = {
  title: "Prueba de errores · De Aquí",
  robots: { index: false, follow: false },
};

export default function PruebaErrores() {
  if (!esPreview) notFound();

  return (
    <main className="mx-auto w-full max-w-3xl flex-1 px-4 py-10">
      <h1 className="text-2xl font-bold">Prueba de errores</h1>
      <p className="mt-2 text-brand-green/80">
        Cada botón genera un error que debe llegar a GlitchTip con el entorno
        «preview».
      </p>
      <BotonesDePrueba />
    </main>
  );
}
