-- MODELO RELACIONAL ECO-ELECTRÓNICOS (MySQL 8.0+)
-- InnoDB + claves foráneas + restricciones básicas

CREATE DATABASE IF NOT EXISTS eco_electronicos
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE eco_electronicos;

-- CLIENTES y DIRECCIONES ---------------------------
CREATE TABLE clientes (
  id_cliente      INT AUTO_INCREMENT PRIMARY KEY,
  rut             VARCHAR(20) NULL,                -- opcional si es empresa extranjera, etc.
  nombre          VARCHAR(120) NOT NULL,
  correo          VARCHAR(150) NOT NULL,
  telefono        VARCHAR(30) NULL,
  fecha_alta      DATE NOT NULL DEFAULT (CURRENT_DATE),
  UNIQUE KEY uq_clientes_correo (correo)
) ENGINE=InnoDB;

CREATE TABLE direcciones (
  id_direccion    INT AUTO_INCREMENT PRIMARY KEY,
  id_cliente      INT NOT NULL,
  calle           VARCHAR(150) NOT NULL,
  comuna          VARCHAR(100) NOT NULL,
  ciudad          VARCHAR(100) NOT NULL DEFAULT 'Santiago',
  notas           VARCHAR(250) NULL,
  CONSTRAINT fk_dir_cliente FOREIGN KEY (id_cliente)
    REFERENCES clientes(id_cliente)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ARTÍCULOS (CATÁLOGO) ----------------------------
CREATE TABLE articulos (
  id_articulo     INT AUTO_INCREMENT PRIMARY KEY,
  nombre          VARCHAR(100) NOT NULL,
  categoria       VARCHAR(80)  NOT NULL,
  unidad          ENUM('unidad','kg') NOT NULL DEFAULT 'unidad',
  peligroso       TINYINT(1) NOT NULL DEFAULT 0,   -- baterías de litio, CRT, etc.
  UNIQUE KEY uq_articulo_nombre (nombre)
) ENGINE=InnoDB;

-- SOLICITUDES DE RETIRO ----------------------------
CREATE TABLE solicitudes (
  id_solicitud    INT AUTO_INCREMENT PRIMARY KEY,
  id_cliente      INT NOT NULL,
  id_direccion    INT NOT NULL,
  fecha_solicitud DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_deseada   DATETIME NOT NULL,
  estado          ENUM('pendiente','programada','completada','cancelada') NOT NULL DEFAULT 'pendiente',
  descripcion     VARCHAR(500) NULL,
  CONSTRAINT fk_sol_cliente FOREIGN KEY (id_cliente)
    REFERENCES clientes(id_cliente)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_sol_direccion FOREIGN KEY (id_direccion)
    REFERENCES direcciones(id_direccion)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- VEHÍCULOS y CONDUCTORES --------------------------
CREATE TABLE vehiculos (
  id_vehiculo     INT AUTO_INCREMENT PRIMARY KEY,
  patente         VARCHAR(12) NOT NULL,
  tipo            ENUM('furgon','camion_35t','camion_5t') NOT NULL,
  capacidad_kg    DECIMAL(8,2) NOT NULL CHECK (capacidad_kg > 0),
  activo          TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY uq_patente (patente)
) ENGINE=InnoDB;

CREATE TABLE conductores (
  id_conductor    INT AUTO_INCREMENT PRIMARY KEY,
  nombre          VARCHAR(120) NOT NULL,
  rut             VARCHAR(20)  NULL,
  licencia        ENUM('B','C','D','E') NOT NULL,
  activo          TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

-- ASIGNACIÓN (evita sobreasignación) ---------------
-- Un registro por solicitud programada con vehículo, fecha/hora y conductor.
-- Índices UNIQUE para evitar doble reserva de mismo vehículo o conductor simultáneamente.
CREATE TABLE asignaciones (
  id_asignacion   INT AUTO_INCREMENT PRIMARY KEY,
  id_solicitud    INT NOT NULL,
  id_vehiculo     INT NOT NULL,
  id_conductor    INT NOT NULL,
  inicio_programado DATETIME NOT NULL,
  fin_programado    DATETIME NOT NULL,
  CHECK (fin_programado > inicio_programado),
  CONSTRAINT fk_asig_solicitud FOREIGN KEY (id_solicitud)
    REFERENCES solicitudes(id_solicitud)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_asig_vehiculo FOREIGN KEY (id_vehiculo)
    REFERENCES vehiculos(id_vehiculo)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_asig_conductor FOREIGN KEY (id_conductor)
    REFERENCES conductores(id_conductor)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  UNIQUE KEY uq_vehiculo_slot (id_vehiculo, inicio_programado, fin_programado),
  UNIQUE KEY uq_conductor_slot (id_conductor, inicio_programado, fin_programado)
) ENGINE=InnoDB;

-- RETIROS y DETALLE DE ARTÍCULOS -------------------
-- El retiro se genera al completar una solicitud.
CREATE TABLE retiros (
  id_retiro       INT AUTO_INCREMENT PRIMARY KEY,
  id_solicitud    INT NOT NULL,
  fecha_retiro    DATETIME NOT NULL,
  kg_totales      DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (kg_totales >= 0),
  observaciones   VARCHAR(300) NULL,
  CONSTRAINT fk_retiro_solicitud FOREIGN KEY (id_solicitud)
    REFERENCES solicitudes(id_solicitud)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Detalle N:M entre retiros y artículos, con cantidad y peso
CREATE TABLE items_retiro (
  id_item         INT AUTO_INCREMENT PRIMARY KEY,
  id_retiro       INT NOT NULL,
  id_articulo     INT NOT NULL,
  cantidad        INT NOT NULL DEFAULT 1 CHECK (cantidad > 0),
  kg              DECIMAL(10,2) NULL CHECK (kg IS NULL OR kg >= 0),
  CONSTRAINT fk_item_retiro FOREIGN KEY (id_retiro)
    REFERENCES retiros(id_retiro)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_item_articulo FOREIGN KEY (id_articulo)
    REFERENCES articulos(id_articulo)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  UNIQUE KEY uq_detalle (id_retiro, id_articulo)
) ENGINE=InnoDB;
