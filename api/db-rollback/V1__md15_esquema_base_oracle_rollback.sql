-- =============================================================================
-- Jira MD-15: ROLLBACK de V1__md15_esquema_base_oracle.sql
-- ¡DESTRUCTIVO! Borra todas las tablas de De Aquí y sus datos.
-- Úsalo solo en dev, o en prod con respaldo previo y aprobación del equipo.
-- Orden inverso al de creación para respetar las llaves foráneas.
-- =============================================================================

DROP TABLE metricas_diarias_tienda CASCADE CONSTRAINTS PURGE;
DROP TABLE eventos_metricas CASCADE CONSTRAINTS PURGE;
DROP TABLE publicaciones CASCADE CONSTRAINTS PURGE;
DROP TABLE resenas CASCADE CONSTRAINTS PURGE;
DROP TABLE pedido_items CASCADE CONSTRAINTS PURGE;
DROP TABLE pedidos CASCADE CONSTRAINTS PURGE;
DROP TABLE carrito_items CASCADE CONSTRAINTS PURGE;
DROP TABLE carritos CASCADE CONSTRAINTS PURGE;
DROP TABLE citas CASCADE CONSTRAINTS PURGE;
DROP TABLE servicios_horarios CASCADE CONSTRAINTS PURGE;
DROP TABLE servicios CASCADE CONSTRAINTS PURGE;
DROP TABLE producto_imagenes CASCADE CONSTRAINTS PURGE;
DROP TABLE productos CASCADE CONSTRAINTS PURGE;
DROP TABLE verificaciones_tiendas CASCADE CONSTRAINTS PURGE;
DROP TABLE tiendas CASCADE CONSTRAINTS PURGE;
DROP TABLE direcciones_usuarios CASCADE CONSTRAINTS PURGE;
DROP TABLE usuarios CASCADE CONSTRAINTS PURGE;
DROP TABLE marcas CASCADE CONSTRAINTS PURGE;
DROP TABLE categorias CASCADE CONSTRAINTS PURGE;
DROP TABLE ciudades CASCADE CONSTRAINTS PURGE;
