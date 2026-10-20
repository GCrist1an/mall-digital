# Frontend · De Aquí

Next.js (App Router) + React + TypeScript + Tailwind, móvil primero, desplegado en Vercel.

## Requisitos

- Node 24 (ver `.nvmrc`).
- pnpm, en la versión fijada en `packageManager` de `package.json`. Con Corepack: `corepack enable`.

## Cómo correrlo

```bash
cd frontend
pnpm install
pnpm dev        # http://localhost:3000
```

## Scripts

| Script              | Qué hace                                  |
| ------------------- | ----------------------------------------- |
| `pnpm dev`          | Servidor de desarrollo                    |
| `pnpm build`        | Build de producción                       |
| `pnpm start`        | Sirve el build de producción              |
| `pnpm lint`         | ESLint (reglas de Next.js + Prettier)     |
| `pnpm typecheck`    | Revisión de tipos con TypeScript (strict) |
| `pnpm format`       | Formatea con Prettier                     |
| `pnpm format:check` | Verifica el formato sin cambiar archivos  |
| `pnpm test`         | Pruebas con Vitest + Testing Library      |
| `pnpm test:watch`   | Pruebas en modo watch                     |

## Estructura

```
src/
├── app/          # rutas (App Router), layout y estilos globales
├── components/
│   └── ui/       # piezas reutilizables
├── features/     # módulos de dominio: tiendas, carrito, pedidos
├── lib/          # utilidades y cliente de la API
└── types/        # tipos compartidos
tests/            # pruebas
public/           # logo y archivos estáticos
```

## Marca

Los colores del logo están como tokens de Tailwind en `src/app/globals.css`:

| Token          | Color     | Ejemplo de uso     |
| -------------- | --------- | ------------------ |
| `brand-green`  | `#1F4E3D` | `bg-brand-green`   |
| `brand-yellow` | `#F2B632` | `bg-brand-yellow`  |
| `brand-cream`  | `#FFF4DC` | `text-brand-cream` |

Fuente: Inter, servida localmente con `next/font`.
