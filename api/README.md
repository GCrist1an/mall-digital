# API · De Aquí

API principal en Java 21 con Spring Boot 3.2 y **Maven**, conectada a Oracle Autonomous Database.

## Ejecutar en local (dev)
```powershell
$env:DB_URL      = "jdbc:oracle:thin:@deaquidev_tp?TNS_ADMIN=C:/ruta/al/wallet"
$env:DB_USER     = "DEAQUI_APP"
$env:DB_PASSWORD = "..."
.\mvnw.cmd spring-boot:run
```
- `deaquidev_tp` es el alias del `tnsnames.ora` dentro del wallet de dev. Si tu wallet muestra otro, usa el de tu archivo.
- `TNS_ADMIN` apunta a la carpeta del wallet descomprimido, **fuera del repositorio**.
- Sin esas variables la API no arranca (configuración en `src/main/resources/application.yml`).

## Usuario de la API
La API usa **`DEAQUI_APP`** (solo lectura y escritura de datos), no `DEAQUI` (dueño del esquema, solo para migrar).
Detalle y scripts en [`src/main/resources/db/README.md`](src/main/resources/db/README.md).

## Migraciones (Flyway)
Las migraciones están en `src/main/resources/db/migration/`. Flyway está desactivado por defecto; para migrar al arrancar:
```powershell
$env:FLYWAY_ENABLED  = "true"
$env:FLYWAY_USER     = "DEAQUI"
$env:FLYWAY_PASSWORD = "..."
```

## Compilar y probar
```powershell
.\mvnw.cmd -B verify
```

El CI compila y prueba con Java 21 (Temurin) y detecta Maven por `pom.xml`.
