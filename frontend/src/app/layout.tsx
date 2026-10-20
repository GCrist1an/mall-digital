import type { Metadata, Viewport } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "De Aquí · Tiendas locales de Pereira y Dosquebradas",
  description:
    "Descubre tiendas locales verificadas de Pereira y Dosquebradas, arma tu carrito y pide por WhatsApp.",
};

export const viewport: Viewport = {
  themeColor: "#1f4e3d",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="es" className={`${inter.variable} h-full antialiased`}>
      <body className="flex min-h-full flex-col font-sans">{children}</body>
    </html>
  );
}
