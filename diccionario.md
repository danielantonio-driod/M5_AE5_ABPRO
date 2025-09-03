# ECO-ELECTRÓNICOS — Diccionario de Datos

> Versión: 1.0 — Modelo relacional para gestión de clientes, solicitudes, agenda, vehículos y reciclajes.

## Tabla: `clientes`
- **id_cliente** (INT, PK, AI, NOT NULL): Identificador interno del cliente.
- **rut** (VARCHAR(20), NULL): Identificación tributaria (puede quedar vacía).
- **nombre** (VARCHAR(120), NOT NULL): Nombre o razón social.
- **correo** (VARCHAR(150), NOT NULL, UNIQUE): Correo de contacto.
- **telefono** (VARCHAR(30), NULL): Teléfono de contacto.
- **fecha_alta** (DATE, NOT NULL, DEFAULT CURRENT_DATE): Fecha de alta del cliente.

**Ejemplo**
| id_cliente | rut         | nombre              | correo                | telefono     | fecha_alta |
|------------|-------------|---------------------|-----------------------|--------------|------------|
| 1          | 11.111.111-1| Juan Pérez          | juan@ejemplo.cl       | +56 9 1111   | 2025-08-10 |

---

## Tabla: `direcciones`
- **id_direccion** (INT, PK, AI, NOT NULL)
- **id_cliente** (INT, FK→clientes.id_cliente, NOT NULL)
- **calle** (VARCHAR(150), NOT NULL)
- **comuna** (VARCHAR(100), NOT NULL)
- **ciudad** (VARCHAR(100), NOT NULL, DEF 'Santiago')
- **notas** (VARCHAR(250), NULL)

**Ejemplo**
| id_direccion | id_cliente | calle             | comuna      | ciudad   | notas         |
|--------------|------------|-------------------|-------------|----------|---------------|
| 1            | 1          | Av. Siempre Viva  | Ñuñoa       | Santiago | Portón gris   |

---

## Tabla: `articulos`
- **id_articulo** (INT, PK, AI, NOT NULL)
- **nombre** (VARCHAR(100), NOT NULL, UNIQUE)
- **categoria** (VARCHAR(80), NOT NULL) — p.ej. *Notebook*, *Monitor*, *Celular*
- **unidad** (ENUM('unidad','kg'), NOT NULL, DEF 'unidad')
- **peligroso** (TINYINT(1), NOT NULL, DEF 0) — 1 si requiere manejo especial

**Ejemplo**
| id_articulo | nombre   | categoria | unidad | peligroso |
|-------------|----------|----------|--------|-----------|
| 1           | Notebook | Notebook | unidad | 0         |

---

## Tabla: `solicitudes`
- **id_solicitud** (INT, PK, AI, NOT NULL)
- **id_cliente** (INT, FK→clientes, NOT NULL)
- **id_direccion** (INT, FK→direcciones, NOT NULL)
- **fecha_solicitud** (DATETIME, NOT NULL, DEF CURRENT_TIMESTAMP)
- **fecha_deseada** (DATETIME, NOT NULL)
- **estado** (ENUM('pendiente','programada','completada','cancelada'), NOT NULL, DEF 'pendiente')
- **descripcion** (VARCHAR(500), NULL)

**Ejemplo**
| id_solicitud | id_cliente | id_direccion | fecha_deseada     | estado     |
|--------------|------------|--------------|-------------------|------------|
| 10           | 1          | 1            | 2025-08-20 10:00  | programada |

---

## Tabla: `vehiculos`
- **id_vehiculo** (INT, PK, AI, NOT NULL)
- **patente** (VARCHAR(12), NOT NULL, UNIQUE)
- **tipo** (ENUM('furgon','camion_35t','camion_5t'), NOT NULL)
- **capacidad_kg** (DECIMAL(8,2), NOT NULL, CHECK > 0)
- **activo** (TINYINT(1), NOT NULL, DEF 1)

**Ejemplo**
| id_vehiculo | patente | tipo        | capacidad_kg | activo |
|-------------|---------|-------------|--------------|--------|
| 1           | ABCD-12 | camion_35t  | 3500.00      | 1      |

---

## Tabla: `conductores`
- **id_conductor** (INT, PK, AI, NOT NULL)
- **nombre** (VARCHAR(120), NOT NULL)
- **rut** (VARCHAR(20), NULL)
- **licencia** (ENUM('B','C','D','E'), NOT NULL)
- **activo** (TINYINT(1), NOT NULL, DEF 1)

**Ejemplo**
| id_conductor | nombre     | licencia | activo |
|--------------|------------|----------|--------|
| 1            | María Soto | C        | 1      |

---

## Tabla: `asignaciones`
- **id_asignacion** (INT, PK, AI, NOT NULL)
- **id_solicitud** (INT, FK→solicitudes, NOT NULL)
- **id_vehiculo** (INT, FK→vehiculos, NOT NULL)
- **id_conductor** (INT, FK→conductores, NOT NULL)
- **inicio_programado** (DATETIME, NOT NULL)
- **fin_programado** (DATETIME, NOT NULL, CHECK fin > inicio)

**Reglas de negocio**
- `uq_vehiculo_slot` evita reservar el mismo vehículo en el mismo intervalo.
- `uq_conductor_slot` evita asignar un conductor a dos retiros simultáneos.

**Ejemplo**
| id_asignacion | id_solicitud | id_vehiculo | id_conductor | inicio_programado   | fin_programado     |
|---------------|--------------|-------------|--------------|---------------------|--------------------|
| 100           | 10           | 1           | 1            | 2025-08-20 10:00    | 2025-08-20 11:30   |

---

## Tabla: `retiros`
- **id_retiro** (INT, PK, AI, NOT NULL)
- **id_solicitud** (INT, FK→solicitudes, NOT NULL)
- **fecha_retiro** (DATETIME, NOT NULL)
- **kg_totales** (DECIMAL(10,2), NOT NULL, DEF 0, CHECK ≥ 0)
- **observaciones** (VARCHAR(300), NULL)

**Ejemplo**
| id_retiro | id_solicitud | fecha_retiro       | kg_totales |
|-----------|--------------|--------------------|------------|
| 500       | 10           | 2025-08-20 11:35   | 124.80     |

---

## Tabla: `items_retiro`
- **id_item** (INT, PK, AI, NOT NULL)
- **id_retiro** (INT, FK→retiros, NOT NULL)
- **id_articulo** (INT, FK→articulos, NOT NULL)
- **cantidad** (INT, NOT NULL, DEF 1, CHECK > 0)
- **kg** (DECIMAL(10,2), NULL, CHECK ≥ 0)

**Nota**: Si `unidad='kg'`, usa `kg`. Si `unidad='unidad'`, usa `cantidad` y `kg` opcional.

**Ejemplo**
| id_item | id_retiro | id_articulo | cantidad | kg   |
|---------|-----------|-------------|----------|------|
| 1       | 500       | 1           | 3        | 12.5 |
