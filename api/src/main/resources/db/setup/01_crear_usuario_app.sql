-- =============================================================================
-- MD-15: crea el usuario de la API (DEAQUI_APP). Ejecutar UNA vez, como ADMIN.
-- Está en db/setup/ (fuera de db/migration): Flyway NO lo ejecuta.
--
-- Cambia CAMBIAR_ESTA_CLAVE por una contraseña real y propia (12-30 caracteres,
-- mayúscula, minúscula y número). No la subas al repositorio.
-- =============================================================================
CREATE USER deaqui_app IDENTIFIED BY "CAMBIAR_ESTA_CLAVE" QUOTA 0 ON DATA;

-- Solo puede conectarse. Sin CREATE/DROP/ALTER: no es dueño de nada.
GRANT CREATE SESSION TO deaqui_app;
