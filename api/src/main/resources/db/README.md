# Migraciones de base de datos · MD-15

Scripts para Oracle Autonomous Database. Revisa: @GCrist1an (ver CODEOWNERS).

| Archivo | Qué hace |
|---|---|
| `V1__md15_esquema_base_oracle.sql` | Crea el esquema completo de «De Aquí» (20 tablas) y siembra Pereira y Dosquebradas |
| `rollback/V1__md15_esquema_base_oracle_rollback.sql` | Borra todo (destructivo) |

## Modelo de negocio
- Moneda única **COP**, en pesos enteros `NUMBER(12,0)`; las tablas con importes fuerzan `moneda = 'COP'`.
- **Sin pasarela de pagos**: los pedidos se coordinan por WhatsApp. No hay tablas de pagos.
- Tiendas con verificación, carrito y pedidos, servicios con agenda (piloto), feed de novedades y métricas.

## Cómo aplicar (manual, mientras se decide la herramienta)
1. Conéctate con SQL Developer Web (consola de OCI) o SQLcl a la base **dev**.
2. Ejecuta `V1__md15_esquema_base_oracle.sql` completo.
3. Verifica: `SELECT table_name FROM user_tables ORDER BY 1;` debe listar 20 tablas.

## Herramienta de migraciones: PENDIENTE
Cuando se elija Flyway o Liquibase, **excluye `rollback/`** de la ruta que escanea la herramienta
(Flyway escanea subcarpetas y ejecutaría el rollback). Puede moverse a `db/rollback/` fuera de `locations`
o a `schema/`. No habilites migración automática al arrancar hasta resolverlo.
