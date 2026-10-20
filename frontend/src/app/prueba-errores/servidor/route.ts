import { connection } from "next/server";
import { esPreview } from "@/lib/observabilidad";

export async function GET() {
  // Espera una petición real: no se prerenderiza en el build.
  await connection();

  if (!esPreview) {
    return new Response(null, { status: 404 });
  }

  throw new Error("Prueba de GlitchTip desde el servidor (MD-18)");
}
