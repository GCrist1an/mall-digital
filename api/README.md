# API · De Aquí

API principal en Java 21 con Spring Boot 3.2 y Maven, conectada a Oracle Autonomous Database.

## Ejecutar en local
```powershell
$env:DB_URL      = "jdbc:oracle:thin:@malldev_high?TNS_ADMIN=C:/ruta/al/wallet"
$env:DB_USER     = "usuario_app"
$env:DB_PASSWORD = "..."
.\mvnw.cmd spring-boot:run
```
Sin esas variables la API no arranca (la configuración está en `src/main/resources/application.yml`).

## Compilar y probar
```powershell
.\mvnw.cmd -B verify
```

## Base de datos
Las migraciones están en `src/main/resources/db/` (ver su README). Hibernate no toca el esquema (`ddl-auto: none`).

El CI (MD-17) compila y prueba con Java 21 (Temurin) y detecta Maven por `pom.xml`.
