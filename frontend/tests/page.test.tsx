import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import Home from "@/app/page";

describe("Página de inicio", () => {
  it("muestra el lema de De Aquí como título principal", () => {
    render(<Home />);

    expect(
      screen.getByRole("heading", {
        level: 1,
        name: "Tiendas locales verificadas de Pereira y Dosquebradas",
      }),
    ).toBeInTheDocument();
  });

  it("explica los tres pasos en orden", () => {
    render(<Home />);

    const steps = screen
      .getAllByRole("heading", { level: 3 })
      .map((heading) => heading.textContent);

    expect(steps).toEqual([
      "Descubre tiendas",
      "Arma tu carrito",
      "Pide por WhatsApp",
    ]);
  });
});
