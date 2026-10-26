-- =============================================================================
-- Jira MD-15: Esquema base de Oracle Autonomous DB para «De Aquí» (Mall Digital)
-- Archivo: V1__md15_esquema_base_oracle.sql
-- Compatible con: Oracle Database 19c o superior / Autonomous Database Always Free
-- -----------------------------------------------------------------------------
-- Modelo de negocio que refleja este esquema (Documento Maestro, sección 8):
--   * Moneda única: pesos colombianos (COP), en pesos enteros NUMBER(12,0).
--     Cada tabla con importes lleva moneda = 'COP' con CHECK que la fija.
--   * Sin pasarela de pagos: NO existen tablas ni columnas de pago. Cada pedido
--     se coordina por WhatsApp entre el cliente y la tienda.
--   * Verificación de tiendas: solo se publica una tienda VERIFICADA.
--   * Carrito: carritos / carrito_items; al confirmarse se convierte en un
--     pedido por tienda (pedidos / pedido_items).
--   * Servicios con agenda (piloto): servicios, servicios_horarios y citas.
--   * Feed: publicaciones de novedades y ofertas de las tiendas.
--   * Métricas: eventos del embudo y agregados diarios por tienda.
--
-- Alcance geográfico del piloto: Pereira y Dosquebradas (Risaralda, Colombia).
--
-- Convenciones:
--   * Booleanos: NUMBER(1) con CHECK (0, 1).
--   * fecha_actualizacion la mantiene la aplicación (no hay triggers).
--   * Este script NO incluye ALTER SESSION: la configuración de sesión pertenece
--     a la conexión (Hikari), no a la migración.
--
-- Ubicación: api/src/main/resources/db/ (revisa @GCrist1an según CODEOWNERS).
-- Herramienta de migraciones: PENDIENTE (Flyway o Liquibase). Ver README.md de
-- esta carpeta. Mientras tanto el script se aplica a mano.
-- Rollback: rollback/V1__md15_esquema_base_oracle_rollback.sql
-- =============================================================================

-- =============================================================================
-- TABLA: CIUDADES
-- =============================================================================
CREATE TABLE ciudades (
    id_ciudad           NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo              VARCHAR2(20) NOT NULL UNIQUE,
    nombre              VARCHAR2(100) NOT NULL,
    departamento        VARCHAR2(100) NOT NULL,
    activo              NUMBER(1) DEFAULT 1 NOT NULL CHECK (activo IN (0, 1)),
    fecha_creacion      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE ciudades IS 'Municipios cubiertos por De Aquí (Pereira y Dosquebradas en el piloto)';
COMMENT ON COLUMN ciudades.codigo IS 'Código único del municipio, por ejemplo PEREIRA o DOSQUEBRADAS';

CREATE INDEX idx_ciudades_activo ON ciudades(activo);

-- =============================================================================
-- TABLA: CATEGORIAS
-- =============================================================================
CREATE TABLE categorias (
    id_categoria        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo              VARCHAR2(20) NOT NULL UNIQUE,
    nombre              VARCHAR2(100) NOT NULL,
    descripcion         VARCHAR2(500),
    id_categoria_padre  NUMBER,
    nivel               NUMBER DEFAULT 1 NOT NULL CHECK (nivel BETWEEN 1 AND 5),
    icono_url           VARCHAR2(500),
    activo              NUMBER(1) DEFAULT 1 NOT NULL CHECK (activo IN (0, 1)),
    orden_visualizacion NUMBER DEFAULT 0 NOT NULL,
    fecha_creacion      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    creado_por          VARCHAR2(100) DEFAULT USER,
    actualizado_por     VARCHAR2(100),

    CONSTRAINT fk_categorias_padre FOREIGN KEY (id_categoria_padre) REFERENCES categorias(id_categoria)
);

COMMENT ON TABLE categorias IS 'Catálogo de categorías jerárquicas de tiendas, productos y servicios';
COMMENT ON COLUMN categorias.id_categoria_padre IS 'Referencia a la categoría padre para la jerarquía';

CREATE INDEX idx_categorias_padre ON categorias(id_categoria_padre);
CREATE INDEX idx_categorias_activo ON categorias(activo);

-- =============================================================================
-- TABLA: MARCAS
-- =============================================================================
CREATE TABLE marcas (
    id_marca            NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo              VARCHAR2(30) NOT NULL UNIQUE,
    nombre              VARCHAR2(100) NOT NULL,
    descripcion         VARCHAR2(500),
    logo_url            VARCHAR2(500),
    activo              NUMBER(1) DEFAULT 1 NOT NULL CHECK (activo IN (0, 1)),
    fecha_creacion      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    creado_por          VARCHAR2(100) DEFAULT USER,
    actualizado_por     VARCHAR2(100)
);

COMMENT ON TABLE marcas IS 'Marcas comerciales disponibles en el catálogo de las tiendas';

CREATE INDEX idx_marcas_activo ON marcas(activo);

-- =============================================================================
-- TABLA: USUARIOS
-- Clientes, dueños de tienda y administradores de De Aquí
-- =============================================================================
CREATE TABLE usuarios (
    id_usuario          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email               VARCHAR2(150) NOT NULL UNIQUE,
    password_hash       VARCHAR2(255),
    nombres             VARCHAR2(100) NOT NULL,
    apellidos           VARCHAR2(100),
    telefono            VARCHAR2(30),
    whatsapp            VARCHAR2(30),
    rol                 VARCHAR2(20) DEFAULT 'CLIENTE' NOT NULL
                        CHECK (rol IN ('CLIENTE', 'TIENDA', 'ADMIN')),
    id_ciudad           NUMBER,
    email_verificado    NUMBER(1) DEFAULT 0 NOT NULL CHECK (email_verificado IN (0, 1)),
    activo              NUMBER(1) DEFAULT 1 NOT NULL CHECK (activo IN (0, 1)),
    ultimo_acceso       TIMESTAMP WITH TIME ZONE,
    fecha_creacion      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT fk_usuarios_ciudad FOREIGN KEY (id_ciudad) REFERENCES ciudades(id_ciudad)
);

COMMENT ON TABLE usuarios IS 'Cuentas de la plataforma: clientes, dueños de tienda y administradores';
COMMENT ON COLUMN usuarios.password_hash IS 'Hash de la contraseña (nunca en texto plano). NULL si la autenticación es externa';
COMMENT ON COLUMN usuarios.whatsapp IS 'WhatsApp del cliente, para que la tienda lo contacte';

CREATE INDEX idx_usuarios_rol ON usuarios(rol);
CREATE INDEX idx_usuarios_ciudad ON usuarios(id_ciudad);

-- =============================================================================
-- TABLA: DIRECCIONES_USUARIOS
-- Direcciones de entrega del cliente (formato colombiano, con barrio)
-- =============================================================================
CREATE TABLE direcciones_usuarios (
    id_direccion        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_usuario          NUMBER NOT NULL,
    alias               VARCHAR2(50),
    id_ciudad           NUMBER NOT NULL,
    direccion           VARCHAR2(200) NOT NULL,
    barrio              VARCHAR2(100),
    referencia          VARCHAR2(200),
    es_principal        NUMBER(1) DEFAULT 0 NOT NULL CHECK (es_principal IN (0, 1)),
    fecha_creacion      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT fk_dirusu_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    CONSTRAINT fk_dirusu_ciudad FOREIGN KEY (id_ciudad) REFERENCES ciudades(id_ciudad)
);

COMMENT ON TABLE direcciones_usuarios IS 'Direcciones de entrega guardadas por el cliente';
COMMENT ON COLUMN direcciones_usuarios.direccion IS 'Dirección tal como se escribe en Colombia, por ejemplo: Carrera 7 # 20-35';

CREATE INDEX idx_dirusu_usuario ON direcciones_usuarios(id_usuario);
CREATE INDEX idx_dirusu_ciudad ON direcciones_usuarios(id_ciudad);

-- =============================================================================
-- TABLA: TIENDAS
-- Tiendas locales de Pereira y Dosquebradas que venden en De Aquí
-- =============================================================================
CREATE TABLE tiendas (
    id_tienda             NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo                VARCHAR2(20) NOT NULL UNIQUE,
    nombre                VARCHAR2(150) NOT NULL,
    descripcion           VARCHAR2(1000),
    id_propietario        NUMBER,
    id_categoria          NUMBER NOT NULL,
    id_marca              NUMBER,
    id_ciudad             NUMBER NOT NULL,
    direccion_calle       VARCHAR2(200),
    direccion_numero      VARCHAR2(20),
    direccion_barrio      VARCHAR2(100),
    direccion_referencia  VARCHAR2(200),
    direccion_completa    CLOB,
    telefono              VARCHAR2(30),
    whatsapp              VARCHAR2(30) NOT NULL,
    email                 VARCHAR2(150),
    sitio_web             VARCHAR2(255),
    redes_sociales        CLOB,
    horarios_atencion     CLOB,
    tipo_entrega          VARCHAR2(30) DEFAULT 'AMBOS' NOT NULL
                          CHECK (tipo_entrega IN ('RECOGER_EN_TIENDA', 'DOMICILIO', 'AMBOS')),
    logo_url              VARCHAR2(500),
    banner_url            VARCHAR2(500),
    calificacion_promedio NUMBER(2, 1) DEFAULT 0 NOT NULL
                          CHECK (calificacion_promedio BETWEEN 0 AND 5),
    numero_resenas        NUMBER DEFAULT 0 NOT NULL CHECK (numero_resenas >= 0),
    estado_verificacion   VARCHAR2(20) DEFAULT 'PENDIENTE' NOT NULL
                          CHECK (estado_verificacion IN ('PENDIENTE', 'VERIFICADA', 'RECHAZADA', 'SUSPENDIDA')),
    fecha_verificacion    TIMESTAMP WITH TIME ZONE,
    verificada_por        VARCHAR2(100),
    activo                NUMBER(1) DEFAULT 1 NOT NULL CHECK (activo IN (0, 1)),
    destacado             NUMBER(1) DEFAULT 0 NOT NULL CHECK (destacado IN (0, 1)),
    fecha_creacion        TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_actualizacion   TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    creado_por            VARCHAR2(100) DEFAULT USER,
    actualizado_por       VARCHAR2(100),

    CONSTRAINT fk_tiendas_propietario FOREIGN KEY (id_propietario) REFERENCES usuarios(id_usuario),
    CONSTRAINT fk_tiendas_categoria FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria),
    CONSTRAINT fk_tiendas_marca FOREIGN KEY (id_marca) REFERENCES marcas(id_marca),
    CONSTRAINT fk_tiendas_ciudad FOREIGN KEY (id_ciudad) REFERENCES ciudades(id_ciudad),
    CONSTRAINT chk_tiendas_verificacion CHECK (
        estado_verificacion <> 'VERIFICADA' OR fecha_verificacion IS NOT NULL
    ),
    CONSTRAINT chk_tiendas_redes_json CHECK (redes_sociales IS JSON),
    CONSTRAINT chk_tiendas_horarios_json CHECK (horarios_atencion IS JSON),
    CONSTRAINT chk_tiendas_dircompleta_json CHECK (direccion_completa IS JSON)
);

COMMENT ON TABLE tiendas IS 'Tiendas locales verificadas que venden en De Aquí';
COMMENT ON COLUMN tiendas.id_propietario IS 'Usuario con rol TIENDA que administra la tienda';
COMMENT ON COLUMN tiendas.whatsapp IS 'Número de WhatsApp de la tienda: es el canal de los pedidos';
COMMENT ON COLUMN tiendas.horarios_atencion IS 'JSON: {"lunes": {"apertura": "08:00", "cierre": "18:00"}, ...}';
COMMENT ON COLUMN tiendas.redes_sociales IS 'JSON: {"instagram": "...", "facebook": "..."}';
COMMENT ON COLUMN tiendas.direccion_completa IS 'JSON con la dirección descompuesta de la tienda';
COMMENT ON COLUMN tiendas.estado_verificacion IS 'PENDIENTE, VERIFICADA, RECHAZADA o SUSPENDIDA. Solo las VERIFICADAS se publican';
COMMENT ON COLUMN tiendas.calificacion_promedio IS 'Promedio de las reseñas, de 0 a 5';

CREATE INDEX idx_tiendas_propietario ON tiendas(id_propietario);
CREATE INDEX idx_tiendas_categoria ON tiendas(id_categoria);
CREATE INDEX idx_tiendas_marca ON tiendas(id_marca);
CREATE INDEX idx_tiendas_ciudad ON tiendas(id_ciudad);
CREATE INDEX idx_tiendas_verificacion ON tiendas(estado_verificacion);
CREATE INDEX idx_tiendas_activo ON tiendas(activo);
CREATE INDEX idx_tiendas_destacado ON tiendas(destacado);

-- =============================================================================
-- TABLA: VERIFICACIONES_TIENDAS
-- Historial del proceso de verificación de cada tienda
-- =============================================================================
CREATE TABLE verificaciones_tiendas (
    id_verificacion     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_tienda           NUMBER NOT NULL,
    estado              VARCHAR2(20) DEFAULT 'SOLICITADA' NOT NULL
                        CHECK (estado IN ('SOLICITADA', 'EN_REVISION', 'APROBADA', 'RECHAZADA')),
    fecha_solicitud     TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_resolucion    TIMESTAMP WITH TIME ZONE,
    revisor             VARCHAR2(100),
    tipo_documento      VARCHAR2(30) CHECK (tipo_documento IN ('CC', 'CE', 'NIT', 'RUT', 'CAMARA_COMERCIO', 'OTRO')),
    numero_documento    VARCHAR2(50),
    documentos          CLOB,
    observaciones       VARCHAR2(1000),
    resultado           VARCHAR2(1000),
    fecha_creacion      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT fk_verificaciones_tienda FOREIGN KEY (id_tienda) REFERENCES tiendas(id_tienda) ON DELETE CASCADE,
    CONSTRAINT chk_verificaciones_docs_json CHECK (documentos IS JSON)
);

COMMENT ON TABLE verificaciones_tiendas IS 'Historial de verificaciones de tiendas: quién las revisó y con qué soportes';
COMMENT ON COLUMN verificaciones_tiendas.documentos IS 'JSON Array con las rutas de los soportes: ["rut.pdf", "camara_comercio.pdf"]';

CREATE INDEX idx_verificaciones_tienda ON verificaciones_tiendas(id_tienda);
CREATE INDEX idx_verificaciones_estado ON verificaciones_tiendas(estado);

-- =============================================================================
-- TABLA: PRODUCTOS
-- Catálogo de productos de cada tienda. Precios en COP enteros.
-- =============================================================================
CREATE TABLE productos (
    id_producto         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_tienda           NUMBER NOT NULL,
    id_categoria        NUMBER NOT NULL,
    id_marca            NUMBER,
    nombre              VARCHAR2(200) NOT NULL,
    descripcion         VARCHAR2(2000),
    sku                 VARCHAR2(50),
    precio              NUMBER(12, 0) NOT NULL CHECK (precio >= 0),
    precio_oferta       NUMBER(12, 0) CHECK (precio_oferta >= 0),
    moneda              VARCHAR2(3) DEFAULT 'COP' NOT NULL CHECK (moneda = 'COP'),
    unidad_medida       VARCHAR2(20) DEFAULT 'UNIDAD' NOT NULL,
    stock               NUMBER DEFAULT 0 NOT NULL CHECK (stock >= 0),
    controla_stock      NUMBER(1) DEFAULT 1 NOT NULL CHECK (controla_stock IN (0, 1)),
    disponible          NUMBER(1) DEFAULT 1 NOT NULL CHECK (disponible IN (0, 1)),
    destacado           NUMBER(1) DEFAULT 0 NOT NULL CHECK (destacado IN (0, 1)),
    imagen_principal_url VARCHAR2(500),
    activo              NUMBER(1) DEFAULT 1 NOT NULL CHECK (activo IN (0, 1)),
    fecha_creacion      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT fk_productos_tienda FOREIGN KEY (id_tienda) REFERENCES tiendas(id_tienda) ON DELETE CASCADE,
    CONSTRAINT fk_productos_categoria FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria),
    CONSTRAINT fk_productos_marca FOREIGN KEY (id_marca) REFERENCES marcas(id_marca),
    CONSTRAINT chk_productos_oferta CHECK (precio_oferta IS NULL OR precio_oferta <= precio),
    CONSTRAINT uq_productos_tienda_sku UNIQUE (id_tienda, sku)
);

COMMENT ON TABLE productos IS 'Productos que vende cada tienda';
COMMENT ON COLUMN productos.precio IS 'Precio en pesos colombianos (COP), sin decimales';
COMMENT ON COLUMN productos.moneda IS 'Siempre COP: De Aquí opera con una sola moneda';

CREATE INDEX idx_productos_tienda ON productos(id_tienda);
CREATE INDEX idx_productos_categoria ON productos(id_categoria);
CREATE INDEX idx_productos_marca ON productos(id_marca);
CREATE INDEX idx_productos_disponible ON productos(disponible, activo);

CREATE TABLE producto_imagenes (
    id_imagen           NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_producto         NUMBER NOT NULL,
    url                 VARCHAR2(500) NOT NULL,
    orden               NUMBER DEFAULT 0 NOT NULL,
    fecha_creacion      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT fk_prodimg_producto FOREIGN KEY (id_producto) REFERENCES productos(id_producto) ON DELETE CASCADE
);

COMMENT ON TABLE producto_imagenes IS 'Galería de imágenes de cada producto';

CREATE INDEX idx_prodimg_producto ON producto_imagenes(id_producto);

-- =============================================================================
-- TABLA: SERVICIOS
-- Servicios con agenda de las tiendas (fase piloto)
-- =============================================================================
CREATE TABLE servicios (
    id_servicio         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_tienda           NUMBER NOT NULL,
    id_categoria        NUMBER NOT NULL,
    nombre              VARCHAR2(200) NOT NULL,
    descripcion         VARCHAR2(2000),
    precio              NUMBER(12, 0) CHECK (precio >= 0),
    moneda              VARCHAR2(3) DEFAULT 'COP' NOT NULL CHECK (moneda = 'COP'),
    duracion_minutos    NUMBER(4) DEFAULT 60 NOT NULL CHECK (duracion_minutos > 0),
    cupos_por_horario   NUMBER(3) DEFAULT 1 NOT NULL CHECK (cupos_por_horario > 0),
    requiere_agenda     NUMBER(1) DEFAULT 1 NOT NULL CHECK (requiere_agenda IN (0, 1)),
    imagen_url          VARCHAR2(500),
    activo              NUMBER(1) DEFAULT 1 NOT NULL CHECK (activo IN (0, 1)),
    fecha_creacion      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT fk_servicios_tienda FOREIGN KEY (id_tienda) REFERENCES tiendas(id_tienda) ON DELETE CASCADE,
    CONSTRAINT fk_servicios_categoria FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria)
);

COMMENT ON TABLE servicios IS 'Servicios que ofrece una tienda (peluquería, reparaciones, etc.)';
COMMENT ON COLUMN servicios.precio IS 'Precio en COP. NULL = a convenir con la tienda';

CREATE INDEX idx_servicios_tienda ON servicios(id_tienda);
CREATE INDEX idx_servicios_categoria ON servicios(id_categoria);

CREATE TABLE servicios_horarios (
    id_horario          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_servicio         NUMBER NOT NULL,
    dia_semana          NUMBER(1) NOT NULL CHECK (dia_semana BETWEEN 1 AND 7),
    hora_inicio         VARCHAR2(5) NOT NULL,
    hora_fin            VARCHAR2(5) NOT NULL,
    activo              NUMBER(1) DEFAULT 1 NOT NULL CHECK (activo IN (0, 1)),

    CONSTRAINT fk_serhor_servicio FOREIGN KEY (id_servicio) REFERENCES servicios(id_servicio) ON DELETE CASCADE,
    CONSTRAINT chk_serhor_formato CHECK (
        REGEXP_LIKE(hora_inicio, '^([01][0-9]|2[0-3]):[0-5][0-9]$')
        AND REGEXP_LIKE(hora_fin, '^([01][0-9]|2[0-3]):[0-5][0-9]$')
        AND hora_fin > hora_inicio
    )
);

COMMENT ON TABLE servicios_horarios IS 'Franjas semanales en que se atiende un servicio';
COMMENT ON COLUMN servicios_horarios.dia_semana IS '1 = lunes ... 7 = domingo';
COMMENT ON COLUMN servicios_horarios.hora_inicio IS 'Formato HH:MM de 24 horas, hora de Colombia';

CREATE INDEX idx_serhor_servicio ON servicios_horarios(id_servicio);

CREATE TABLE citas (
    id_cita             NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_servicio         NUMBER NOT NULL,
    id_usuario          NUMBER NOT NULL,
    fecha_hora_inicio   TIMESTAMP WITH TIME ZONE NOT NULL,
    fecha_hora_fin      TIMESTAMP WITH TIME ZONE NOT NULL,
    estado              VARCHAR2(20) DEFAULT 'SOLICITADA' NOT NULL
                        CHECK (estado IN ('SOLICITADA', 'CONFIRMADA', 'CANCELADA', 'COMPLETADA', 'NO_ASISTIO')),
    notas_cliente       VARCHAR2(500),
    notas_tienda        VARCHAR2(500),
    fecha_creacion      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT fk_citas_servicio FOREIGN KEY (id_servicio) REFERENCES servicios(id_servicio),
    CONSTRAINT fk_citas_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario),
    CONSTRAINT chk_citas_rango CHECK (fecha_hora_fin > fecha_hora_inicio)
);

COMMENT ON TABLE citas IS 'Citas agendadas por clientes para un servicio. La tienda las confirma por WhatsApp';

CREATE INDEX idx_citas_servicio_fecha ON citas(id_servicio, fecha_hora_inicio);
CREATE INDEX idx_citas_usuario ON citas(id_usuario);
CREATE INDEX idx_citas_estado ON citas(estado);

-- =============================================================================
-- TABLAS: CARRITOS y CARRITO_ITEMS
-- Un carrito por cliente y tienda; al confirmarse se convierte en un pedido
-- =============================================================================
CREATE TABLE carritos (
    id_carrito          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_usuario          NUMBER NOT NULL,
    id_tienda           NUMBER NOT NULL,
    estado              VARCHAR2(20) DEFAULT 'ACTIVO' NOT NULL
                        CHECK (estado IN ('ACTIVO', 'CONVERTIDO', 'ABANDONADO')),
    fecha_creacion      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT fk_carritos_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    CONSTRAINT fk_carritos_tienda FOREIGN KEY (id_tienda) REFERENCES tiendas(id_tienda) ON DELETE CASCADE
);

COMMENT ON TABLE carritos IS 'Carrito de compras: uno ACTIVO por cliente y tienda';

CREATE INDEX idx_carritos_usuario ON carritos(id_usuario);
CREATE INDEX idx_carritos_tienda ON carritos(id_tienda);
-- Solo un carrito ACTIVO por cliente y tienda
CREATE UNIQUE INDEX uq_carritos_activo ON carritos(
    CASE WHEN estado = 'ACTIVO' THEN id_usuario END,
    CASE WHEN estado = 'ACTIVO' THEN id_tienda END
);

CREATE TABLE carrito_items (
    id_item             NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_carrito          NUMBER NOT NULL,
    id_producto         NUMBER NOT NULL,
    cantidad            NUMBER NOT NULL CHECK (cantidad > 0),
    precio_unitario     NUMBER(12, 0) NOT NULL CHECK (precio_unitario >= 0),
    fecha_creacion      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT fk_caritem_carrito FOREIGN KEY (id_carrito) REFERENCES carritos(id_carrito) ON DELETE CASCADE,
    CONSTRAINT fk_caritem_producto FOREIGN KEY (id_producto) REFERENCES productos(id_producto),
    CONSTRAINT uq_caritem_producto UNIQUE (id_carrito, id_producto)
);

COMMENT ON COLUMN carrito_items.precio_unitario IS 'Precio en COP al momento de agregar el producto';

CREATE INDEX idx_caritem_producto ON carrito_items(id_producto);

-- =============================================================================
-- TABLAS: PEDIDOS y PEDIDO_ITEMS
-- Un pedido por tienda, coordinado por WhatsApp. NO hay pasarela de pagos:
-- el pago, si lo hay, se acuerda directamente entre cliente y tienda.
-- =============================================================================
CREATE TABLE pedidos (
    id_pedido             NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo                VARCHAR2(20) NOT NULL UNIQUE,
    id_usuario            NUMBER NOT NULL,
    id_tienda             NUMBER NOT NULL,
    id_carrito            NUMBER,
    estado                VARCHAR2(30) DEFAULT 'CREADO' NOT NULL
                          CHECK (estado IN ('CREADO', 'ENVIADO_WHATSAPP', 'CONFIRMADO', 'PREPARANDO',
                                            'LISTO', 'EN_CAMINO', 'ENTREGADO', 'CANCELADO')),
    tipo_entrega          VARCHAR2(30) NOT NULL
                          CHECK (tipo_entrega IN ('RECOGER_EN_TIENDA', 'DOMICILIO')),
    direccion_entrega     VARCHAR2(500),
    barrio_entrega        VARCHAR2(100),
    id_ciudad_entrega     NUMBER,
    whatsapp_cliente      VARCHAR2(30) NOT NULL,
    whatsapp_tienda       VARCHAR2(30) NOT NULL,
    subtotal              NUMBER(12, 0) DEFAULT 0 NOT NULL CHECK (subtotal >= 0),
    costo_envio           NUMBER(12, 0) DEFAULT 0 NOT NULL CHECK (costo_envio >= 0),
    total                 NUMBER(12, 0) DEFAULT 0 NOT NULL CHECK (total >= 0),
    moneda                VARCHAR2(3) DEFAULT 'COP' NOT NULL CHECK (moneda = 'COP'),
    notas_cliente         VARCHAR2(500),
    notas_tienda          VARCHAR2(500),
    fecha_envio_whatsapp  TIMESTAMP WITH TIME ZONE,
    fecha_confirmacion    TIMESTAMP WITH TIME ZONE,
    fecha_entrega         TIMESTAMP WITH TIME ZONE,
    fecha_cancelacion     TIMESTAMP WITH TIME ZONE,
    motivo_cancelacion    VARCHAR2(500),
    fecha_creacion        TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_actualizacion   TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT fk_pedidos_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario),
    CONSTRAINT fk_pedidos_tienda FOREIGN KEY (id_tienda) REFERENCES tiendas(id_tienda),
    CONSTRAINT fk_pedidos_carrito FOREIGN KEY (id_carrito) REFERENCES carritos(id_carrito) ON DELETE SET NULL,
    CONSTRAINT fk_pedidos_ciudad FOREIGN KEY (id_ciudad_entrega) REFERENCES ciudades(id_ciudad),
    CONSTRAINT chk_pedidos_total CHECK (total = subtotal + costo_envio),
    CONSTRAINT chk_pedidos_domicilio CHECK (tipo_entrega <> 'DOMICILIO' OR direccion_entrega IS NOT NULL)
);

COMMENT ON TABLE pedidos IS 'Pedidos por tienda coordinados por WhatsApp. Sin pasarela de pagos integrada';
COMMENT ON COLUMN pedidos.total IS 'subtotal + costo_envio, en COP';
COMMENT ON COLUMN pedidos.whatsapp_tienda IS 'WhatsApp de la tienda al momento del pedido (copia histórica)';
COMMENT ON COLUMN pedidos.fecha_envio_whatsapp IS 'Cuándo el cliente abrió WhatsApp con el mensaje del pedido';

CREATE INDEX idx_pedidos_usuario ON pedidos(id_usuario);
CREATE INDEX idx_pedidos_tienda_estado ON pedidos(id_tienda, estado);
CREATE INDEX idx_pedidos_carrito ON pedidos(id_carrito);
CREATE INDEX idx_pedidos_ciudad ON pedidos(id_ciudad_entrega);
CREATE INDEX idx_pedidos_fecha ON pedidos(fecha_creacion);

CREATE TABLE pedido_items (
    id_item             NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_pedido           NUMBER NOT NULL,
    id_producto         NUMBER,
    nombre_producto     VARCHAR2(200) NOT NULL,
    cantidad            NUMBER NOT NULL CHECK (cantidad > 0),
    precio_unitario     NUMBER(12, 0) NOT NULL CHECK (precio_unitario >= 0),
    subtotal            NUMBER(12, 0) NOT NULL CHECK (subtotal >= 0),

    CONSTRAINT fk_pedit_pedido FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido) ON DELETE CASCADE,
    CONSTRAINT fk_pedit_producto FOREIGN KEY (id_producto) REFERENCES productos(id_producto) ON DELETE SET NULL,
    CONSTRAINT chk_pedit_subtotal CHECK (subtotal = cantidad * precio_unitario)
);

COMMENT ON TABLE pedido_items IS 'Líneas del pedido: nombre y precio quedan copiados aunque el producto cambie';

CREATE INDEX idx_pedit_pedido ON pedido_items(id_pedido);
CREATE INDEX idx_pedit_producto ON pedido_items(id_producto);

-- =============================================================================
-- TABLA: RESENAS
-- =============================================================================
CREATE TABLE resenas (
    id_resena           NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_tienda           NUMBER NOT NULL,
    id_usuario          NUMBER NOT NULL,
    id_pedido           NUMBER,
    calificacion        NUMBER(1) NOT NULL CHECK (calificacion BETWEEN 1 AND 5),
    comentario          VARCHAR2(1000),
    visible             NUMBER(1) DEFAULT 1 NOT NULL CHECK (visible IN (0, 1)),
    fecha_creacion      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT fk_resenas_tienda FOREIGN KEY (id_tienda) REFERENCES tiendas(id_tienda) ON DELETE CASCADE,
    CONSTRAINT fk_resenas_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario),
    CONSTRAINT fk_resenas_pedido FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido) ON DELETE SET NULL,
    CONSTRAINT uq_resenas_tienda_usuario UNIQUE (id_tienda, id_usuario)
);

COMMENT ON TABLE resenas IS 'Reseñas de clientes. Alimentan tiendas.calificacion_promedio y numero_resenas';

CREATE INDEX idx_resenas_usuario ON resenas(id_usuario);
CREATE INDEX idx_resenas_pedido ON resenas(id_pedido);

-- =============================================================================
-- TABLA: PUBLICACIONES (feed de novedades)
-- =============================================================================
CREATE TABLE publicaciones (
    id_publicacion      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_tienda           NUMBER NOT NULL,
    tipo                VARCHAR2(20) DEFAULT 'NOVEDAD' NOT NULL
                        CHECK (tipo IN ('NOVEDAD', 'OFERTA', 'EVENTO', 'AVISO')),
    titulo              VARCHAR2(200) NOT NULL,
    contenido           VARCHAR2(2000),
    imagen_url          VARCHAR2(500),
    id_producto         NUMBER,
    id_servicio         NUMBER,
    estado              VARCHAR2(20) DEFAULT 'BORRADOR' NOT NULL
                        CHECK (estado IN ('BORRADOR', 'PUBLICADA', 'ARCHIVADA')),
    fecha_publicacion   TIMESTAMP WITH TIME ZONE,
    fecha_expiracion    TIMESTAMP WITH TIME ZONE,
    fecha_creacion      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT fk_publ_tienda FOREIGN KEY (id_tienda) REFERENCES tiendas(id_tienda) ON DELETE CASCADE,
    CONSTRAINT fk_publ_producto FOREIGN KEY (id_producto) REFERENCES productos(id_producto) ON DELETE SET NULL,
    CONSTRAINT fk_publ_servicio FOREIGN KEY (id_servicio) REFERENCES servicios(id_servicio) ON DELETE SET NULL,
    CONSTRAINT chk_publ_publicada CHECK (estado <> 'PUBLICADA' OR fecha_publicacion IS NOT NULL),
    CONSTRAINT chk_publ_vigencia CHECK (fecha_expiracion IS NULL OR fecha_publicacion IS NULL
                                        OR fecha_expiracion > fecha_publicacion)
);

COMMENT ON TABLE publicaciones IS 'Feed de novedades y ofertas que publican las tiendas verificadas';

CREATE INDEX idx_publ_tienda ON publicaciones(id_tienda);
CREATE INDEX idx_publ_feed ON publicaciones(estado, fecha_publicacion);
CREATE INDEX idx_publ_producto ON publicaciones(id_producto);
CREATE INDEX idx_publ_servicio ON publicaciones(id_servicio);

-- =============================================================================
-- TABLAS: EVENTOS_METRICAS y METRICAS_DIARIAS_TIENDA
-- Métricas básicas: embudo (vista -> carrito -> WhatsApp -> pedido) por tienda
-- =============================================================================
CREATE TABLE eventos_metricas (
    id_evento           NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tipo_evento         VARCHAR2(30) NOT NULL
                        CHECK (tipo_evento IN ('VISTA_TIENDA', 'VISTA_PRODUCTO', 'VISTA_PUBLICACION',
                                               'AGREGAR_CARRITO', 'CLIC_WHATSAPP', 'PEDIDO_CREADO',
                                               'CITA_SOLICITADA')),
    id_tienda           NUMBER,
    id_usuario          NUMBER,
    id_producto         NUMBER,
    id_servicio         NUMBER,
    id_publicacion      NUMBER,
    sesion_id           VARCHAR2(64),
    fecha_evento        TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT fk_evmet_tienda FOREIGN KEY (id_tienda) REFERENCES tiendas(id_tienda) ON DELETE CASCADE,
    CONSTRAINT fk_evmet_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE SET NULL,
    CONSTRAINT fk_evmet_producto FOREIGN KEY (id_producto) REFERENCES productos(id_producto) ON DELETE SET NULL,
    CONSTRAINT fk_evmet_servicio FOREIGN KEY (id_servicio) REFERENCES servicios(id_servicio) ON DELETE SET NULL,
    CONSTRAINT fk_evmet_publicacion FOREIGN KEY (id_publicacion) REFERENCES publicaciones(id_publicacion) ON DELETE SET NULL
);

COMMENT ON TABLE eventos_metricas IS 'Eventos del embudo de la plataforma. Se agregan por día en metricas_diarias_tienda';

CREATE INDEX idx_evmet_tienda_fecha ON eventos_metricas(id_tienda, fecha_evento);
CREATE INDEX idx_evmet_tipo_fecha ON eventos_metricas(tipo_evento, fecha_evento);
CREATE INDEX idx_evmet_usuario ON eventos_metricas(id_usuario);
CREATE INDEX idx_evmet_producto ON eventos_metricas(id_producto);
CREATE INDEX idx_evmet_servicio ON eventos_metricas(id_servicio);
CREATE INDEX idx_evmet_publicacion ON eventos_metricas(id_publicacion);

CREATE TABLE metricas_diarias_tienda (
    id_tienda           NUMBER NOT NULL,
    fecha               DATE NOT NULL,
    vistas_tienda       NUMBER DEFAULT 0 NOT NULL CHECK (vistas_tienda >= 0),
    vistas_producto     NUMBER DEFAULT 0 NOT NULL CHECK (vistas_producto >= 0),
    agregados_carrito   NUMBER DEFAULT 0 NOT NULL CHECK (agregados_carrito >= 0),
    clics_whatsapp      NUMBER DEFAULT 0 NOT NULL CHECK (clics_whatsapp >= 0),
    pedidos_creados     NUMBER DEFAULT 0 NOT NULL CHECK (pedidos_creados >= 0),
    citas_solicitadas   NUMBER DEFAULT 0 NOT NULL CHECK (citas_solicitadas >= 0),
    valor_pedidos_cop   NUMBER(14, 0) DEFAULT 0 NOT NULL CHECK (valor_pedidos_cop >= 0),
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT pk_metricas_diarias PRIMARY KEY (id_tienda, fecha),
    CONSTRAINT fk_metdia_tienda FOREIGN KEY (id_tienda) REFERENCES tiendas(id_tienda) ON DELETE CASCADE
);

COMMENT ON TABLE metricas_diarias_tienda IS 'Agregado diario por tienda para el panel de métricas básicas';
COMMENT ON COLUMN metricas_diarias_tienda.valor_pedidos_cop IS 'Suma de totales de pedidos creados ese día, en COP';

-- =============================================================================
-- DATOS INICIALES
-- =============================================================================
INSERT INTO ciudades (codigo, nombre, departamento) VALUES ('PEREIRA', 'Pereira', 'Risaralda');
INSERT INTO ciudades (codigo, nombre, departamento) VALUES ('DOSQUEBRADAS', 'Dosquebradas', 'Risaralda');

COMMIT;
