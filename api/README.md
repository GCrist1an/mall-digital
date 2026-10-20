# API · De Aquí

API principal en Java con Spring Boot, desplegada en Oracle Cloud y conectada a Oracle Autonomous Database.

Se inicializa en la tarea **MD-63** (Víctor). Hasta entonces esta carpeta está vacía.
Las migraciones de base de datos irán en `src/main/resources/db/` (MD-15).

El CI (MD-17) compila y prueba con Java 21 (Temurin) y detecta solo si el proyecto usa Maven (`pom.xml`) o Gradle (`build.gradle` / `build.gradle.kts`). Mientras no haya proyecto, el job `api` termina en verde con un aviso.
