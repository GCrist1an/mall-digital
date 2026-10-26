-- =============================================================================
-- MD-15: crea el usuario de la API (DEAQUI_APP). Ejecutar UNA vez, como ADMIN.
-- Está en db/setup/ (fuera de db/migration): Flyway NO lo ejecuta.
--
-- Ejecutar con SQLcl (o SQL*Plus): pide la contraseña al correrlo, sin mostrarla.
-- Nunca escribas la contraseña en este archivo. La hoja SQL web de Database
-- Actions no soporta ACCEPT ... HIDE.
-- Contraseña: 12-30 caracteres, con mayúscula, minúscula y número.
-- =============================================================================
-- VERIFY OFF evita que SQLcl imprima la sentencia ya sustituida (con la clave).
SET VERIFY OFF
ACCEPT clave_app CHAR PROMPT 'Contraseña para DEAQUI_APP: ' HIDE

CREATE USER deaqui_app IDENTIFIED BY "&clave_app" QUOTA 0 ON DATA;

UNDEFINE clave_app

-- Solo puede conectarse. Sin CREATE/DROP/ALTER: no es dueño de nada.
GRANT CREATE SESSION TO deaqui_app;
