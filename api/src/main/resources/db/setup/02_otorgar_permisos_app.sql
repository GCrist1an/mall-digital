-- =============================================================================
-- MD-15: da a DEAQUI_APP lectura y escritura sobre las tablas de DEAQUI.
-- Ejecutar como ADMIN. Se puede repetir sin problema: vuélvelo a correr después
-- de cada migración que cree tablas nuevas (o incluye los GRANT en esa migración).
-- Está en db/setup/ (fuera de db/migration): Flyway NO lo ejecuta.
-- =============================================================================
BEGIN
  FOR t IN (SELECT table_name FROM all_tables WHERE owner = 'DEAQUI'
             AND table_name <> 'flyway_schema_history') LOOP
    EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON DEAQUI."'
                      || t.table_name || '" TO deaqui_app';
  END LOOP;
END;
/

-- Verificación: debe listar las 20 tablas de la aplicación
SELECT table_name, privilege
  FROM all_tab_privs
 WHERE grantee = 'DEAQUI_APP' AND table_schema = 'DEAQUI' AND privilege = 'SELECT'
 ORDER BY table_name;
