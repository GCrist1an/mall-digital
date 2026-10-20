-- =============================================================================
-- Jira MD-15: Crear bases Oracle Autonomous DB (dev y prod) y aplicar esquema inicial
-- Archivo: 01_create_schema.sql
-- Descripción: Esquema inicial para Mall Digital - Tablas principales
-- Compatible con: Oracle Database 23ai / Autonomous Database
-- =============================================================================

-- Configuración de sesión
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS.FF3';

-- =============================================================================
-- ESQUEMA: MALL_DIGITAL
-- =============================================================================
-- Nota: En Autonomous DB, el esquema se crea automáticamente con el usuario ADMIN
-- o se puede crear un usuario específico. Aquí definimos las tablas bajo el esquema actual.

-- =============================================================================
-- TABLA: CATEGORIAS
-- Catálogo de categorías de productos/locales
-- =============================================================================
CREATE TABLE categorias (
    id_categoria        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo              VARCHAR2(20) NOT NULL UNIQUE,
    nombre              VARCHAR2(100) NOT NULL,
    descripcion         VARCHAR2(500),
    id_categoria_padre  NUMBER,
    nivel               NUMBER DEFAULT 1 CHECK (nivel BETWEEN 1 AND 5),
    activo              NUMBER(1) DEFAULT 1 CHECK (activo IN (0, 1)),
    orden_visualizacion NUMBER DEFAULT 0,
    fecha_creacion      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    creado_por          VARCHAR2(100) DEFAULT USER,
    actualizado_por     VARCHAR2(100)
);

COMMENT ON TABLE categorias IS 'Catálogo de categorías jerárquicas para productos y locales del mall';
COMMENT ON COLUMN categorias.codigo IS 'Código único alfanumérico de la categoría';
COMMENT ON COLUMN categorias.id_categoria_padre IS 'Referencia a categoría padre para jerarquía';

-- Índices para búsquedas jerárquicas
CREATE INDEX idx_categorias_padre ON categorias(id_categoria_padre);
CREATE INDEX idx_categorias_activo ON categorias(activo);

-- =============================================================================
-- TABLA: MARCAS
-- Marcas comerciales de los productos
-- =============================================================================
CREATE TABLE marcas (
    id_marca            NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo              VARCHAR2(30) NOT NULL UNIQUE,
    nombre              VARCHAR2(100) NOT NULL,
    descripcion         VARCHAR2(500),
    logo_url            VARCHAR2(500),
    sitio_web           VARCHAR2(255),
    pais_origen         VARCHAR2(50),
    activo              NUMBER(1) DEFAULT 1 CHECK (activo IN (0, 1)),
    fecha_creacion      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    creado_por          VARCHAR2(100) DEFAULT USER,
    actualizado_por     VARCHAR2(100)
);

COMMENT ON TABLE marcas IS 'Marcas comerciales disponibles en el mall digital';
CREATE INDEX idx_marcas_activo ON marcas(activo);

-- =============================================================================
-- TABLA: LOCALES
-- Locales físicos o virtuales del mall
-- =============================================================================
CREATE TABLE locales (
    id_local            NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo              VARCHAR2(20) NOT NULL UNIQUE,
    nombre              VARCHAR2(150) NOT NULL,
    descripcion         VARCHAR2(1000),
    id_categoria        NUMBER NOT NULL,
    id_marca            NUMBER,
    ubicacion_fisica    VARCHAR2(200),
    superficie_m2       NUMBER(10,2),
    capacidad_maxima    NUMBER,
    telefono            VARCHAR2(30),
    email               VARCHAR2(150),
    horario_apertura    VARCHAR2(50),
    sitio_web           VARCHAR2(255),
    redes_sociales      CLOB,
    imagen_principal    VARCHAR2(500),
    galeria_imagenes    CLOB,
    activo              NUMBER(1) DEFAULT 1 CHECK (activo IN (0, 1)),
    destacado           NUMBER(1) DEFAULT 0 CHECK (destacado IN (0, 1)),
    fecha_inauguracion  DATE,
    fecha_creacion      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    creado_por          VARCHAR2(100) DEFAULT USER,
    actualizado_por     VARCHAR2(100),
    
    CONSTRAINT fk_locales_categoria FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria),
    CONSTRAINT fk_locales_marca FOREIGN KEY (id_marca) REFERENCES marcas(id_marca)
);

COMMENT ON TABLE locales IS 'Locales físicos y virtuales del mall digital';
COMMENT ON COLUMN locales.redes_sociales IS 'JSON: {"facebook": "...", "instagram": "...", "twitter": "..."}';
COMMENT ON COLUMN locales.galeria_imagenes IS 'JSON Array: ["url1", "url2", ...]';

CREATE INDEX idx_locales_categoria ON locales(id_categoria);
CREATE INDEX idx_locales_marca ON locales(id_marca);
CREATE INDEX idx_locales_activo ON locales(activo);
CREATE INDEX idx_locales_destacado ON locales(destacado);

-- =============================================================================
-- TABLA: PRODUCTOS
-- Productos ofrecidos por los locales
-- =============================================================================
CREATE TABLE productos (
    id_producto         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo              VARCHAR2(30) NOT NULL UNIQUE,
    codigo_barras       VARCHAR2(50),
    nombre              VARCHAR2(200) NOT NULL,
    descripcion_corta   VARCHAR2(500),
    descripcion_larga   CLOB,
    id_local            NUMBER NOT NULL,
    id_categoria        NUMBER NOT NULL,
    id_marca            NUMBER,
    precio_lista        NUMBER(12,2) NOT NULL CHECK (precio_lista >= 0),
    precio_oferta       NUMBER(12,2) CHECK (precio_oferta >= 0),
    fecha_inicio_oferta DATE,
    fecha_fin_oferta    DATE,
    moneda              VARCHAR2(3) DEFAULT 'MXN',
    sku_interno         VARCHAR2(50),
    unidad_medida       VARCHAR2(20) DEFAULT 'PIEZA',
    peso_kg             NUMBER(8,3),
    dimensiones_cm      VARCHAR2(50),
    stock_actual        NUMBER DEFAULT 0 CHECK (stock_actual >= 0),
    stock_minimo        NUMBER DEFAULT 5 CHECK (stock_minimo >= 0),
    stock_maximo        NUMBER DEFAULT 1000,
    gestion_stock       NUMBER(1) DEFAULT 1 CHECK (gestion_stock IN (0, 1)),
    imagen_principal    VARCHAR2(500),
    galeria_imagenes    CLOB,
    etiquetas           CLOB,
    activo              NUMBER(1) DEFAULT 1 CHECK (activo IN (0, 1)),
    visible_online      NUMBER(1) DEFAULT 1 CHECK (visible_online IN (0, 1)),
    requiere_receta     NUMBER(1) DEFAULT 0 CHECK (requiere_receta IN (0, 1)),
    fecha_creacion      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    creado_por          VARCHAR2(100) DEFAULT USER,
    actualizado_por     VARCHAR2(100),
    
    CONSTRAINT fk_productos_local FOREIGN KEY (id_local) REFERENCES locales(id_local),
    CONSTRAINT fk_productos_categoria FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria),
    CONSTRAINT fk_productos_marca FOREIGN KEY (id_marca) REFERENCES marcas(id_marca),
    CONSTRAINT chk_precio_oferta CHECK (precio_oferta IS NULL OR precio_oferta <= precio_lista)
);

COMMENT ON TABLE productos IS 'Catálogo de productos disponibles en los locales del mall';
COMMENT ON COLUMN productos.etiquetas IS 'JSON Array de etiquetas: ["nuevo", "oferta", "exclusivo", "bestseller"]';
COMMENT ON COLUMN productos.galeria_imagenes IS 'JSON Array de URLs de imágenes';

CREATE INDEX idx_productos_local ON productos(id_local);
CREATE INDEX idx_productos_categoria ON productos(id_categoria);
CREATE INDEX idx_productos_marca ON productos(id_marca);
CREATE INDEX idx_productos_activo ON productos(activo);
CREATE INDEX idx_productos_visible ON productos(visible_online);
CREATE INDEX idx_productos_precio ON productos(precio_lista);
CREATE INDEX idx_productos_stock ON productos(stock_actual);
CREATE INDEX idx_productos_codigo_barras ON productos(codigo_barras);

-- =============================================================================
-- TABLA: CLIENTES
-- Usuarios/Clientes del mall digital
-- =============================================================================
CREATE TABLE clientes (
    id_cliente          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo_cliente      VARCHAR2(20) NOT NULL UNIQUE,
    tipo_documento      VARCHAR2(10) DEFAULT 'INE' CHECK (tipo_documento IN ('INE', 'PASAPORTE', 'RFC', 'OTRO')),
    numero_documento    VARCHAR2(30) NOT NULL UNIQUE,
    nombres             VARCHAR2(100) NOT NULL,
    apellidos           VARCHAR2(100) NOT NULL,
    email               VARCHAR2(150) NOT NULL UNIQUE,
    telefono            VARCHAR2(30),
    fecha_nacimiento    DATE,
    genero              VARCHAR2(1) CHECK (genero IN ('M', 'F', 'O', 'N')),
    direccion_calle     VARCHAR2(200),
    direccion_numero    VARCHAR2(20),
    direccion_colonia   VARCHAR2(100),
    direccion_ciudad    VARCHAR2(100),
    direccion_estado    VARCHAR2(100),
    direccion_cp        VARCHAR2(10),
    direccion_pais      VARCHAR2(50) DEFAULT 'México',
    direccion_completa  CLOB,
    nivel_fidelidad     VARCHAR2(20) DEFAULT 'BRONCE' CHECK (nivel_fidelidad IN ('BRONCE', 'PLATA', 'ORO', 'PLATINO', 'DIAMANTE')),
    puntos_acumulados   NUMBER DEFAULT 0 CHECK (puntos_acumulados >= 0),
    fecha_registro      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fecha_ultima_visita TIMESTAMP WITH TIME ZONE,
    activo              NUMBER(1) DEFAULT 1 CHECK (activo IN (0, 1)),
    acepta_marketing    NUMBER(1) DEFAULT 0 CHECK (acepta_marketing IN (0, 1)),
    creado_por          VARCHAR2(100) DEFAULT USER,
    actualizado_por     VARCHAR2(100),
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE clientes IS 'Clientes registrados en el mall digital';
COMMENT ON COLUMN clientes.direccion_completa IS 'JSON estructurado con componentes de dirección';
COMMENT ON COLUMN clientes.nivel_fidelidad IS 'Nivel en programa de fidelidad';

CREATE INDEX idx_clientes_email ON clientes(email);
CREATE INDEX idx_clientes_documento ON clientes(numero_documento);
CREATE INDEX idx_clientes_activo ON clientes(activo);
CREATE INDEX idx_clientes_fidelidad ON clientes(nivel_fidelidad);

-- =============================================================================
-- TABLA: PEDIDOS
-- Órdenes de compra
-- =============================================================================
CREATE TABLE pedidos (
    id_pedido           NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    numero_pedido       VARCHAR2(30) NOT NULL UNIQUE,
    id_cliente          NUMBER NOT NULL,
    id_local            NUMBER,
    estado              VARCHAR2(20) DEFAULT 'PENDIENTE' 
                        CHECK (estado IN ('PENDIENTE', 'CONFIRMADO', 'PREPARANDO', 'LISTO_RECOGER', 'EN_CAMINO', 'ENTREGADO', 'CANCELADO', 'DEVUELTO')),
    tipo_pedido         VARCHAR2(20) DEFAULT 'ONLINE' 
                        CHECK (tipo_pedido IN ('ONLINE', 'PRESENCIAL', 'TELEFONICO', 'APP')),
    subtotal            NUMBER(12,2) NOT NULL DEFAULT 0 CHECK (subtotal >= 0),
    descuento           NUMBER(12,2) DEFAULT 0 CHECK (descuento >= 0),
    impuestos           NUMBER(12,2) DEFAULT 0 CHECK (impuestos >= 0),
    envio               NUMBER(12,2) DEFAULT 0 CHECK (envio >= 0),
    total               NUMBER(12,2) NOT NULL DEFAULT 0 CHECK (total >= 0),
    moneda              VARCHAR2(3) DEFAULT 'MXN',
    metodo_pago         VARCHAR2(30),
    id_transaccion_pago VARCHAR2(100),
    estado_pago         VARCHAR2(20) DEFAULT 'PENDIENTE' 
                        CHECK (estado_pago IN ('PENDIENTE', 'AUTORIZADO', 'CAPTURADO', 'RECHAZADO', 'REEMBOLSADO', 'PARCIAL')),
    notas_cliente       VARCHAR2(1000),
    notas_internas      VARCHAR2(1000),
    direccion_entrega   CLOB,
    fecha_pedido        TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fecha_confirmacion  TIMESTAMP WITH TIME ZONE,
    fecha_preparacion   TIMESTAMP WITH TIME ZONE,
    fecha_listo         TIMESTAMP WITH TIME ZONE,
    fecha_envio         TIMESTAMP WITH TIME ZONE,
    fecha_entrega       TIMESTAMP WITH TIME ZONE,
    fecha_cancelacion   TIMESTAMP WITH TIME ZONE,
    motivo_cancelacion  VARCHAR2(500),
    creado_por          VARCHAR2(100) DEFAULT USER,
    actualizado_por     VARCHAR2(100),
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_pedidos_cliente FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
    CONSTRAINT fk_pedidos_local FOREIGN KEY (id_local) REFERENCES locales(id_local)
);

COMMENT ON TABLE pedidos IS 'Órdenes de compra realizadas en el mall digital';
COMMENT ON COLUMN pedidos.direccion_entrega IS 'JSON con dirección de entrega estructurada';

CREATE INDEX idx_pedidos_cliente ON pedidos(id_cliente);
CREATE INDEX idx_pedidos_local ON pedidos(id_local);
CREATE INDEX idx_pedidos_estado ON pedidos(estado);
CREATE INDEX idx_pedidos_fecha ON pedidos(fecha_pedido);
CREATE INDEX idx_pedidos_numero ON pedidos(numero_pedido);

-- =============================================================================
-- TABLA: DETALLE_PEDIDOS
-- Líneas de detalle de cada pedido
-- =============================================================================
CREATE TABLE detalle_pedidos (
    id_detalle          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_pedido           NUMBER NOT NULL,
    id_producto         NUMBER NOT NULL,
    cantidad            NUMBER NOT NULL CHECK (cantidad > 0),
    precio_unitario     NUMBER(12,2) NOT NULL CHECK (precio_unitario >= 0),
    descuento_unitario  NUMBER(12,2) DEFAULT 0 CHECK (descuento_unitario >= 0),
    impuestos_unitario  NUMBER(12,2) DEFAULT 0 CHECK (impuestos_unitario >= 0),
    subtotal_linea      NUMBER(12,2) NOT NULL CHECK (subtotal_linea >= 0),
    notas               VARCHAR2(500),
    estado_linea        VARCHAR2(20) DEFAULT 'PENDIENTE' 
                        CHECK (estado_linea IN ('PENDIENTE', 'CONFIRMADO', 'PREPARANDO', 'LISTO', 'ENVIADO', 'ENTREGADO', 'DEVUELTO', 'CANCELADO')),
    fecha_creacion      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_detalle_pedido FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido) ON DELETE CASCADE,
    CONSTRAINT fk_detalle_producto FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);

COMMENT ON TABLE detalle_pedidos IS 'Detalle de productos en cada pedido';

CREATE INDEX idx_detalle_pedido ON detalle_pedidos(id_pedido);
CREATE INDEX idx_detalle_producto ON detalle_pedidos(id_producto);

-- =============================================================================
-- TABLA: PAGOS
-- Registro de pagos y transacciones
-- =============================================================================
CREATE TABLE pagos (
    id_pago             NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_pedido           NUMBER NOT NULL,
    referencia_pago     VARCHAR2(100) NOT NULL UNIQUE,
    proveedor_pago      VARCHAR2(50) CHECK (proveedor_pago IN ('STRIPE', 'PAYPAL', 'MERCADOPAGO', 'OPENPAY', 'CULQI', 'EFECTIVO', 'TRANSFERENCIA', 'OTRO')),
    monto               NUMBER(12,2) NOT NULL CHECK (monto > 0),
    moneda              VARCHAR2(3) DEFAULT 'MXN',
    estado              VARCHAR2(20) DEFAULT 'INICIADO' 
                        CHECK (estado IN ('INICIADO', 'PROCESANDO', 'COMPLETADO', 'FALLIDO', 'REEMBOLSADO', 'PARCIALMENTE_REEMBOLSADO')),
    tipo_pago           VARCHAR2(20) CHECK (tipo_pago IN ('CARGO', 'REEMBOLSO', 'AJUSTE')),
    metodo_pago         VARCHAR2(30),
    ultimos4_tarjeta    VARCHAR2(4),
    marca_tarjeta       VARCHAR2(20),
    datos_adicionales   CLOB,
    fecha_inicio        TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fecha_completado    TIMESTAMP WITH TIME ZONE,
    fecha_reembolso     TIMESTAMP WITH TIME ZONE,
    creado_por          VARCHAR2(100) DEFAULT USER,
    
    CONSTRAINT fk_pagos_pedido FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido)
);

COMMENT ON TABLE pagos IS 'Historial de pagos y transacciones financieras';
COMMENT ON COLUMN pagos.datos_adicionales IS 'JSON con respuesta completa del proveedor de pagos';

CREATE INDEX idx_pagos_pedido ON pagos(id_pedido);
CREATE INDEX idx_pagos_referencia ON pagos(referencia_pago);
CREATE INDEX idx_pagos_estado ON pagos(estado);

-- =============================================================================
-- TABLA: RESENAS
-- Reseñas y calificaciones de productos/locales
-- =============================================================================
CREATE TABLE resenas (
    id_resena           NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_cliente          NUMBER NOT NULL,
    id_producto         NUMBER,
    id_local            NUMBER,
    calificacion        NUMBER(1) NOT NULL CHECK (calificacion BETWEEN 1 AND 5),
    titulo              VARCHAR2(200),
    comentario          VARCHAR2(2000),
    verificado_compra   NUMBER(1) DEFAULT 0 CHECK (verificado_compra IN (0, 1)),
    id_pedido           NUMBER,
    util_count          NUMBER DEFAULT 0 CHECK (util_count >= 0),
    estado              VARCHAR2(20) DEFAULT 'PENDIENTE' 
                        CHECK (estado IN ('PENDIENTE', 'APROBADA', 'RECHAZADA', 'OCULTA')),
    fecha_creacion      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fecha_moderacion    TIMESTAMP WITH TIME ZONE,
    moderado_por        VARCHAR2(100),
    
    CONSTRAINT fk_resenas_cliente FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
    CONSTRAINT fk_resenas_producto FOREIGN KEY (id_producto) REFERENCES productos(id_producto),
    CONSTRAINT fk_resenas_local FOREIGN KEY (id_local) REFERENCES locales(id_local),
    CONSTRAINT fk_resenas_pedido FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido),
    CONSTRAINT chk_resena_producto_o_local CHECK (
        (id_producto IS NOT NULL AND id_local IS NULL) OR 
        (id_producto IS NULL AND id_local IS NOT NULL)
    )
);

COMMENT ON TABLE resenas IS 'Reseñas y calificaciones de clientes sobre productos y locales';

CREATE INDEX idx_resenas_cliente ON resenas(id_cliente);
CREATE INDEX idx_resenas_producto ON resenas(id_producto);
CREATE INDEX idx_resenas_local ON resenas(id_local);
CREATE INDEX idx_resenas_estado ON resenas(estado);

-- =============================================================================
-- TABLA: FAVORITOS
-- Lista de deseos/favoritos de clientes
-- =============================================================================
CREATE TABLE favoritos (
    id_favorito         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_cliente          NUMBER NOT NULL,
    id_producto         NUMBER,
    id_local            NUMBER,
    fecha_agregado      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_favoritos_cliente FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente) ON DELETE CASCADE,
    CONSTRAINT fk_favoritos_producto FOREIGN KEY (id_producto) REFERENCES productos(id_producto) ON DELETE CASCADE,
    CONSTRAINT fk_favoritos_local FOREIGN KEY (id_local) REFERENCES locales(id_local) ON DELETE CASCADE,
    CONSTRAINT chk_favorito_producto_o_local CHECK (
        (id_producto IS NOT NULL AND id_local IS NULL) OR 
        (id_producto IS NULL AND id_local IS NOT NULL)
    ),
    CONSTRAINT uk_favorito_unico UNIQUE (id_cliente, id_producto, id_local)
);

COMMENT ON TABLE favoritos IS 'Lista de deseos y favoritos de los clientes';

CREATE INDEX idx_favoritos_cliente ON favoritos(id_cliente);

-- @@SPLIT@@

-- =============================================================================
-- TABLA: PROMOCIONES
-- Campañas y promociones del mall digital
-- =============================================================================
CREATE TABLE promociones (
    id_promocion          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo                VARCHAR2(30) NOT NULL UNIQUE,
    nombre                VARCHAR2(100) NOT NULL,
    descripcion           VARCHAR2(500),
    tipo                  VARCHAR2(30) NOT NULL CHECK (tipo EN ('PORCENTAJE', 'MONTO_FIXO', 'ENVIO_GRATIS', 'COMPRA_MINIMA')),
    valor                 NUMBER(12,2) NOT NULL,
    fecha_inicio          DATE NOT NULL,
    fecha_fin             DATE NOT NULL,
    id_local              NUMBER,
    id_producto           NUMBER,
    activo                NUMBER(1) DEFAULT 1 CHECK (activo IN (0, 1)),
    uso_maximo_por_cliente  NUMBER DEFAULT NULL,
    uso_actual            NUMBER DEFAULT 0,
    condiciones         CLOB,
    fecha_creacion        TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion   TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    creado_por            VARCHAR2(100) DEFAULT USER,
    actualizado_por       VARCHAR2(100),
    
    CONSTRAINT fk_promociones_local FOREIGN KEY (id_local) REFERENCES locales(id_local),
    CONSTRAINT fk_promociones_producto FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);

COMMENT ON TABLE promociones IS 'Campañas y promociones del mall digital';
COMMENT ON COLUMN promociones.codigo IS 'Código único para aplicar la promoción';
COMMENT ON COLUMN promociones.tipo IS 'Tipo de promoción: PORCENTAJE, MONTO_FIXO, ENVIO_GRATIS, COMPRA_MINIMA';
COMMENT ON COLUMN promociones.valor IS 'Valor del descuento o beneficio';
COMMENT ON COLUMN promociones.uso_actual IS 'Veces que ya fue usada la promoción';

CREATE INDEX idx_promociones_activo ON promociones(activo);
CREATE INDEX idx_promociones_fecha ON promociones(fecha_inicio, fecha_fin);
CREATE INDEX idx_promociones_codigo ON promociones(codigo);

-- =============================================================================
-- TABLA: CUONES
-- Cupones de descuento para clientes
-- =============================================================================
CREATE TABLE cupones (
    id_cupon            NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo              VARCHAR2(30) NOT NULL UNIQUE,
    id_promocion        NUMBER NOT NULL,
    id_cliente          NUMBER,
    fecha_emision       DATE DEFAULT CURRENT_DATE NOT NULL,
    fecha_expiracion    DATE NOT NULL,
    uso_maximo          NUMBER DEFAULT 1,
    uso_actual          NUMBER DEFAULT 0,
    estado              VARCHAR2(20) DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO', 'EXPIRADO', 'USADO', 'CANCELADO')),
    monto_descuento     NUMBER(12,2),
    porcentaje_descuento NUMBER(5,2),
    min_compra          NUMBER(12,2) DEFAULT 0 CHECK (min_compra >= 0),
    activa              NUMBER(1) DEFAULT 1 CHECK (activa IN (0, 1)),
    fecha_creacion      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    creado_por          VARCHAR2(100) DEFAULT USER,
    actualizado_por     VARCHAR2(100),
    
    CONSTRAINT fk_cupones_promocion FOREIGN KEY (id_promocion) REFERENCES promociones(id_promocion),
    CONSTRAINT fk_cupones_cliente FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
);

COMMENT ON TABLE cupones IS 'Cupones de descuento para clientes del mall digital';
COMMENT ON COLUMN cupones.codigo IS 'Código del canjeado por el cliente';
COMMENT ON COLUMN cupones.estado IS 'Estado actual del cupón';
COMMENT ON COLUMN cupones.uso_actual IS 'Veces que ya fue usado el cupón';

CREATE INDEX idx_cupones_codigo ON cupones(codigo);
CREATE INDEX idx_cupones_promocion ON cupones(id_promocion);
CREATE INDEX idx_cupones_estado ON cupones(estado);
CREATE INDEX idx_cupones_expiracion ON cupones(fecha_expiracion);

-- =============================================================================
-- TABLA: CONFIGURACION
-- Configuraciones y ajustes del sistema
-- =============================================================================
CREATE TABLE configuracion (
    id_configuracion      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    clave                 VARCHAR2(100) NOT NULL UNIQUE,
    valor               CLOB NOT NULL,
    tipo_dato           VARCHAR2(30) NOT NULL DEFAULT 'STRING' CHECK (tipo_dato IN ('STRING', 'NUMBER', 'BOOLEAN', 'DATE', 'JSON')),
    descripcion           VARCHAR2(500),
    id_modulo           VARCHAR2(50) NOT NULL,
    activo              NUMBER(1) DEFAULT 1 CHECK (activo IN (0, 1)),
    fecha_creacion      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    creado_por          VARCHAR2(100) DEFAULT USER,
    actualizado_por     VARCHAR2(100),
    
    CONSTRAINT uk_configuracion_clave_modulo UNIQUE (clave, id_modulo)
);

COMMENT ON TABLE configuracion IS 'Configuraciones y ajustes del sistema del mall digital';
COMMENT ON COLUMN configuracion.clave IS 'Clave única de la configuración';
COMMENT ON COLUMN configuracion.tipo_dato IS 'Tipo de dato: STRING, NUMBER, BOOLEAN, DATE, JSON';
COMMENT ON COLUMN configuracion.id_modulo IS 'Módulo al que pertenece la configuración';

CREATE INDEX idx_configuracion_clave ON configuracion(clave);
CREATE INDEX idx_configuracion_modulo ON configuracion(id_modulo);
CREATE INDEX idx_configuracion_activo ON configuracion(activo);

-- =============================================================================
-- TABLA: AJUSTES_INVENTARIO
-- Ajustes de inventario y stock
-- =============================================================================
CREATE TABLE ajustes_inventario (
    id_ajuste           NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_producto         NUMBER NOT NULL,
    tipo_ajuste         VARCHAR2(30) NOT NULL CHECK (tipo_ajuste EN ('ENTRADA', 'SALIDA', 'AJUSTE', 'INVENTARIO_FISICO')),
    cantidad            NUMBER NOT NULL CHECK (cantidad != 0),
    motivo              VARCHAR2(200) NOT NULL,
    fecha_ajuste        DATE DEFAULT CURRENT_DATE NOT NULL,
    id_local            NUMBER,
    id_usuario          VARCHAR2(100) DEFAULT USER,
    activo              NUMBER(1) DEFAULT 1 CHECK (activo IN (0, 1)),
    fecha_creacion      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_ajustes_producto FOREIGN KEY (id_producto) REFERENCES productos(id_producto),
    CONSTRAINT fk_ajustes_local FOREIGN KEY (id_local) REFERENCES locales(id_local)
);

COMMENT ON TABLE ajustes_inventario IS 'Historial de ajustes de inventario y stock';
COMMENT ON COLUMN ajustes_inventario.tipo_ajuste IS 'Tipo: ENTRADA, SALIDA, AJUSTE, INVENTARIO_FISICO';
COMMENT ON COLUMN ajustes_inventario.cantidad IS 'Cantidad positiva para ENTRADA, negativa para SALIDA';

CREATE INDEX idx_ajustes_producto ON ajustes_inventario(id_producto);
CREATE INDEX idx_ajustes_local ON ajustes_inventario(id_local);
CREATE INDEX idx_ajustes_fecha ON ajustes_inventario(fecha_ajuste);
