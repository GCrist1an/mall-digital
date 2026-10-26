# Migraciones de base de datos · MD-15

Scripts para Oracle Autonomous Database. Revisa: @GCrist1an (ver CODEOWNERS).

## Estructura
```
db/
├── migration/   ← lo único que Flyway ejecuta (ruta por defecto de Spring Boot)
│   └── V1__md15_esquema_base_oracle.sql   (20 tablas en COP, sin pagos)
├── rollback/    ← scripts destructivos, FUERA de la ruta de Flyway
│   └── V1__md15_esquema_base_oracle_rollback.sql
└── setup/       ← preparación manual de usuarios, FUERA de la ruta de Flyway
    ├── 01_crear_usuario_app.sql
    └── 02_otorgar_permisos_app.sql
```
Flyway solo mira `classpath:db/migration` (ver `application.yml`). Nunca pongas rollback ni scripts de
setup dentro de `migration/`: Flyway los tomaría como migraciones.

## Reglas de Flyway
- **No edites una migración ya aplicada** (ni sus comentarios): Flyway guarda un checksum y `validate` falla.
  Cualquier cambio va en una nueva `V2__descripcion.sql`.
- Nombre: `V<n>__descripcion.sql` (dos guiones bajos).
- La V1 ya se aplicó en dev con el CLI de Flyway. Al moverla a `migration/` no cambió su contenido.

## Usuarios de base de datos (decisión MD-15)
| Usuario | Para qué | Permisos |
|---|---|---|
| `DEAQUI` | Dueño del esquema; **solo Flyway/migraciones** | DDL completo sobre su esquema |
| `DEAQUI_APP` | **La API en ejecución** | Solo `SELECT, INSERT, UPDATE, DELETE` sobre las tablas de `DEAQUI` |

La API **no** usa `DEAQUI`: si hubiera una falla o una inyección SQL, `DEAQUI_APP` no puede borrar ni alterar tablas.

Crear el usuario (como `ADMIN`, una vez por base):
1. `setup/01_crear_usuario_app.sql` (cambia la contraseña de ejemplo).
2. `setup/02_otorgar_permisos_app.sql`. Repítelo tras cada migración que cree tablas.

## Cómo migrar con Flyway desde la API
Flyway viene desactivado por defecto. Para migrar al arrancar:
```powershell
$env:FLYWAY_ENABLED  = "true"
$env:FLYWAY_USER     = "DEAQUI"
$env:FLYWAY_PASSWORD = "..."          # contraseña de DEAQUI
```
La API en sí se conecta con `DB_USER=DEAQUI_APP`. En producción se recomienda migrar con un paso
separado (CLI o CI) y dejar `FLYWAY_ENABLED=false` en la API, para que ella nunca tenga credenciales de dueño.

## Modelo de negocio
- Moneda única **COP**, pesos enteros `NUMBER(12,0)`; las tablas con importes fuerzan `moneda = 'COP'`.
- **Sin pasarela de pagos**: los pedidos se coordinan por WhatsApp.
- Tiendas con verificación, carrito y pedidos, servicios con agenda (piloto), feed y métricas.

## Rollback (destructivo)
`rollback/V1__md15_esquema_base_oracle_rollback.sql` borra todas las tablas. Solo en dev, o en prod con
respaldo y aprobación del equipo. Si Flyway ya migró, borra también su tabla `flyway_schema_history`
o usa `flyway clean` en dev, para evitar un estado inconsistente.
