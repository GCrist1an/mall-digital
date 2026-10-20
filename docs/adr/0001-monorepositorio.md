# ADR-0001 · Un solo repositorio para frontend y API

- **Estado:** Aceptada
- **Fecha:** 20/10/2026
- **Decidieron:** Cristian Gutierrez y Víctor Parra

## Contexto

El proyecto tiene un frontend en Next.js y una API en Spring Boot, con un equipo de dos personas.

## Decisión

Todo el código vive en un solo repositorio (`mall-digital`), con las carpetas `frontend/` y `api/`.

## Consecuencias

- Un solo lugar para revisar PRs, issues y configuración.
- Un cambio que toca frontend y API puede ir en un mismo PR.
- Los workflows de GitHub Actions se filtran por carpeta para no correr todo en cada cambio.
