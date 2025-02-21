CREATE SCHEMA idea_godoymir;
USE idea_godoymir;

# TABLA CLIENTES
CREATE TABLE clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    CUIT VARCHAR(20) UNIQUE NOT NULL,
    direccion VARCHAR(100) NOT NULL,
    email VARCHAR(100)
);

# TABLA CHOFERES
CREATE TABLE choferes (
    id_chofer INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    CUIL BIGINT NOT NULL UNIQUE,  # CUIL tiene 11 dígitos numéricos
    direccion VARCHAR(100) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    tipo_carnet ENUM('A', 'B', 'C', 'D', 'E', 'F', 'G') NOT NULL
);


# TABLA VEHICULOS
CREATE TABLE vehiculos (
    id_vehiculo INT AUTO_INCREMENT PRIMARY KEY,
    marca VARCHAR(100) NOT NULL,
    modelo VARCHAR(100) NOT NULL,
    anio INT NOT NULL,
    tara DECIMAL(10, 2) NOT NULL,
    carnet_requerido ENUM('A', 'B', 'C', 'D', 'E', 'F', 'G') NOT NULL
);

# TABLA VIAJES
CREATE TABLE viajes (
    id_viaje INT AUTO_INCREMENT PRIMARY KEY,
    fecha_viaje TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    id_pedido INT NOT NULL,
    id_chofer INT NOT NULL,
    id_vehiculo INT NOT NULL,
    origen VARCHAR(255) NOT NULL,
    destino VARCHAR(255) NOT NULL,
    estado_viaje ENUM('Pendiente', 'En tránsito', 'Completado', 'Cancelado') DEFAULT 'Pendiente',
    CONSTRAINT fk_viajes_chofer FOREIGN KEY (id_chofer) REFERENCES choferes(id_chofer),
    CONSTRAINT fk_viajes_vehiculo FOREIGN KEY (id_vehiculo) REFERENCES vehiculos(id_vehiculo)
);

# TABLA PEDIDOS
CREATE TABLE pedidos (
    id_pedido INT AUTO_INCREMENT PRIMARY KEY,
    fecha_pedido TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    id_cliente INT NOT NULL,
        descripcion_pedido VARCHAR(500) NOT NULL,
    peso DECIMAL(10,2) NOT NULL,
    volumen DECIMAL(10,2),
    estado_pedido ENUM('Pendiente', 'En tránsito', 'Entregado', 'Cancelado') DEFAULT 'Pendiente',
    id_viaje INT NOT NULL,
    CONSTRAINT fk_pedido_cliente FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
    CONSTRAINT fk_pedido_viaje FOREIGN KEY (id_viaje) REFERENCES viajes(id_viaje)
);

# MODIFICA TABLA VIAJES
ALTER TABLE viajes
ADD CONSTRAINT fk_viajes_pedido FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido);

# TABLA FACTURAS
CREATE TABLE facturas (
    id_factura INT AUTO_INCREMENT PRIMARY KEY,
    fecha_factura TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    id_cliente INT NOT NULL,
    id_pedido INT NOT NULL,
    monto_factura DECIMAL(10,2) NOT NULL,
    estado_pago ENUM('Pendiente', 'Pagado', 'Vencido') DEFAULT 'Pendiente',
    CONSTRAINT fk_facturas_cliente FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
);


# TABLA MANTENIMIENTO_VEHICULO
CREATE TABLE mantenimiento_vehiculo (
    id_mantenimiento INT AUTO_INCREMENT PRIMARY KEY,
    id_vehiculo INT NOT NULL,
    fecha_mantenimiento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    tipo_mantenimiento ENUM('Preventivo', 'Correctivo') NOT NULL,
    descripcion_mantenimiento TEXT NOT NULL,
    costo_mantenimiento DECIMAL(10,2),
    CONSTRAINT fk_mantenimiento_vehiculo FOREIGN KEY (id_vehiculo) REFERENCES vehiculos(id_vehiculo)
    );
