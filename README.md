# Mall Digital · De Aquí

Centro comercial digital de tiendas locales verificadas de Pereira y Dosquebradas.
El comprador descubre tiendas reales de su ciudad, arma su carrito y envía el pedido a cada tienda por WhatsApp.

> Nombre del proyecto: **Mall Digital** · Nombre comercial: **De Aquí**

## Estructura del repositorio

| Carpeta | Qué contiene | Responsable | Jira |
|---|---|---|---|
| `frontend/` | Next.js + React + TypeScript + Tailwind, móvil primero, desplegado en Vercel | Cristian | MD-14, MD-16 |
| `api/` | API principal en Java con Spring Boot, desplegada en Oracle Cloud | Víctor | MD-63 |
| `docs/` | Enlaces al Documento Maestro y decisiones de arquitectura (ADR) | Ambos | — |
| `.github/` | CI con GitHub Actions, plantilla de PR y revisores automáticos | Cristian | MD-13, MD-17 |

## Cómo correr el proyecto

Se completa cuando existan las bases de cada parte:

- **Frontend:** ver `frontend/README.md` (MD-14).
- **API:** ver `api/README.md` (MD-63).

## Cómo trabajamos

1. Toma una tarea del sprint en Jira y muévela a «En curso».
2. Crea la rama con la clave de Jira: `feat/MD-14-nextjs-inicial`, `fix/MD-140-mensaje-whatsapp`.
3. Escribe los commits con la clave: `feat(frontend): MD-14 agrega página de inicio`.
4. Abre el pull request con la clave en el título y mueve la tarea a «En revisión».
5. El PR necesita CI en verde y la aprobación del revisor asignado por `CODEOWNERS`.
   El CI (`.github/workflows/ci.yml`) corre los checks `frontend` y `api` en cada PR y en cada push a `main`.
6. Se fusiona con **squash merge** y la rama se borra.

Más detalle en la sección 18 del Documento Maestro.

## Enlaces

- **Documento Maestro de Ingeniería:** https://claude.ai/code/artifact/e6a2243f-84ee-48f1-be8c-81a5d12e3058
- **Manual de uso de los espacios de trabajo:** https://claude.ai/code/artifact/d463a20c-4a60-4079-9503-2921b07e6818
- **Jira:** https://cdgutierrez00.atlassian.net (proyecto MD)
- **Slack:** https://mall-digital.slack.com

## Stack

Next.js · React · TypeScript · Tailwind · Java · Spring Boot · Oracle Autonomous Database · Vercel · Oracle Cloud · GitHub Actions · Sentry
