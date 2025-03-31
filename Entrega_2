# CREACIÓN DE 5 VISTAS

# Vista N°1:  Cuantos viajes completó cada chofer
CREATE OR REPLACE VIEW VIAJES_COMPLETADOS_POR_CHOFER AS
SELECT c.id_chofer, c.nombre, v.estado_viaje,  COUNT(v.id_viaje) AS total_viajes_completados FROM choferes c
JOIN viajes v ON c.id_chofer=v.id_chofer
WHERE v.estado_viaje="Completado"
GROUP BY c.id_chofer, c.nombre
ORDER By total_viajes_completados DESC

SELECT * from VIAJES_COMPLETADOS_POR_CHOFER

# Vista N°2:  Ingresos por cliente
CREATE OR REPLACE VIEW INGRESOS_POR_CLIENTE AS
SELECT cl.id_cliente, cl.nombre, f.estado_pago, count(id_pedido) AS Cantidad_pedidos, SUM(f.monto_factura) AS Ingreso_total FROM clientes cl
JOIN facturas f ON cl.id_cliente=f.id_cliente
WHERE f.estado_pago="Pagado"
GROUP BY cl.id_cliente, cl.nombre
ORDER By Ingreso_total DESC

SELECT * from INGRESOS_POR_CLIENTE

# Vista N°3:  Pedidos pendientes de entrega
CREATE OR REPLACE VIEW PEDIDOS_PENDIENTES AS
SELECT p.id_pedido, p.id_cliente, cl.nombre, p.estado_pedido FROM pedidos p
JOIN clientes cl ON cl.id_cliente=p.id_cliente
WHERE p.estado_pedido!="Entregado" and p.estado_pedido!="Cancelado"

SELECT * from PEDIDOS_PENDIENTES

VISTA N°4: RESUMEN DE VIAJES Y CARGA TRANSPORTADA
CREATE OR REPLACE VIEW RESUMEN_VIAJES_CARGA AS
SELECT v.origen, v.destino, COUNT(v.id_viaje) AS total_viajes, SUM(p.peso) AS total_peso_transportado, SUM(p.volumen) AS total_volumen_transportado
FROM viajes v
LEFT JOIN pedidos p ON v.id_pedido = p.id_pedido
GROUP BY v.origen, v.destino;

SELECT * from RESUMEN_VIAJES_CARGA

VISTA N°5 FACTURAS PENDIENTES DE COBRO

CREATE OR REPLACE VIEW FACTURAS_PENDIENTES_PAGO AS
SELECT f.id_cliente, count(f.id_factura) AS cantidad_facturas, sum(f.monto_factura) AS monto_total_pendiente_pago FROM facturas f
GROUP BY f.id_cliente

SELECT * from FACTURAS_PENDIENTES_PAGO

# CREACIÓN DE 2 FUNCIONES

#FUNCIÓN N°1: Ver si un pedido fué entregado o no.
DELIMITER //

CREATE FUNCTION pedido_entregado(id_pedido INT) 
RETURNS TINYINT(1)  
DETERMINISTIC
BEGIN
    DECLARE entregado TINYINT(1) DEFAULT 0;  
    
    SELECT 1 INTO entregado
    FROM pedidos
    WHERE estado_pedido = 'Entregado'
    LIMIT 1;
    
    RETURN entregado;
END;
//

DELIMITER ;


#FUNCIÓN N°2: Calcular peso total de un viaje
DELIMITER //

CREATE FUNCTION calcular_peso_total_viaje(id_viaje INT) 
RETURNS DECIMAL (10,2)  
DETERMINISTIC
BEGIN
    DECLARE peso_total_viaje DECIMAL (10,2);  
    SELECT SUM(p.peso) into peso_total_viaje FROM pedidos p
    JOIN viajes v ON p.id_pedido=v.id_pedido
    WHERE v.id_viaje = id_viaje;
    RETURN peso_total_viaje;
END;
//

DELIMITER ;

# CREACIÓN DE 2 STORED PROCEDURES

# STORED PROCEDURE N°1
# 1) Crear tabla para guardar historial de estados de viaje que guardará los cambios de estado con la fecha y hora exacta del cambio.
CREATE TABLE historial_estados_viajes (
    id_historial INT AUTO_INCREMENT PRIMARY KEY,
    id_viaje INT NOT NULL,
    estado_anterior ENUM('Pendiente', 'En tránsito', 'Completado', 'Cancelado') NOT NULL,
    estado_nuevo ENUM('Pendiente', 'En tránsito', 'Completado', 'Cancelado') NOT NULL,
    fecha_cambio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_viaje) REFERENCES viajes(id_viaje)
);

# 2) 
DELIMITER //

CREATE PROCEDURE actualizar_estado_viaje(
    IN viaje_id INT, 
    IN nuevo_estado ENUM('Pendiente', 'En tránsito', 'Completado', 'Cancelado')
)
BEGIN
    DECLARE estado_actual ENUM('Pendiente', 'En tránsito', 'Completado', 'Cancelado');

    -- Obtener el estado actual del viaje antes de actualizarlo
    SELECT estado_viaje INTO estado_actual 
    FROM viajes 
    WHERE id_viaje = viaje_id;
    
    -- Actualizar el estado del viaje
    UPDATE viajes 
    SET estado_viaje = nuevo_estado 
    WHERE id_viaje = viaje_id;

    -- Insertar el cambio en la tabla de historial
    INSERT INTO historial_estados_viajes (id_viaje, estado_anterior, estado_nuevo, fecha_cambio) 
    VALUES (viaje_id, estado_actual, nuevo_estado, NOW());
END;
//

DELIMITER ;



#STORED PROCEDURE N°2
# Asignar Pedidos a un Viaje sin Exceder la Capacidad del Vehículo
# Primero creamos una tabla intermedia llamada viajes_pedidos 
CREATE TABLE viajes_pedidos (
    id_viaje_pedido INT AUTO_INCREMENT PRIMARY KEY,
    id_viaje INT NOT NULL,
    id_pedido INT NOT NULL,
    peso DECIMAL(10,2) NOT NULL,
    volumen DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_viaje) REFERENCES viajes(id_viaje),
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido),
    UNIQUE (id_viaje, id_pedido)
);

DELIMITER //

CREATE PROCEDURE asignar_pedidos_a_viaje(IN viaje_id INT)
BEGIN
    DECLARE capacidad_max DECIMAL(10,2);
    DECLARE peso_actual DECIMAL(10,2);
    DECLARE pedido_id INT;
    DECLARE pedido_peso DECIMAL(10,2);
    DECLARE done INT DEFAULT 0;

    -- Cursor para recorrer los pedidos no asignados aún
    DECLARE pedidos_cursor CURSOR FOR 
    SELECT id_pedido, peso FROM pedidos 
    WHERE id_pedido NOT IN (
        SELECT id_pedido FROM viajes_pedidos
    ) ORDER BY peso ASC;

    -- Manejo de fin de cursor
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Obtener la capacidad del vehículo asignado al viaje
    SELECT veh.peso_maximo INTO capacidad_max
    FROM viajes v
    JOIN vehiculos veh ON v.id_vehiculo = veh.id_vehiculo
    WHERE v.id_viaje = viaje_id;

    -- Inicializar el peso actual del viaje
    SELECT COALESCE(SUM(peso), 0) INTO peso_actual 
    FROM viajes_pedidos 
    WHERE id_viaje = viaje_id;

    -- Abrir cursor
    OPEN pedidos_cursor;

    -- Iterar sobre los pedidos y asignarlos si hay capacidad
    read_loop: LOOP
        FETCH pedidos_cursor INTO pedido_id, pedido_peso;
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Verificar si se puede asignar sin exceder la capacidad
        IF peso_actual + pedido_peso <= capacidad_max THEN
            -- Insertar el pedido en la tabla intermedia
            INSERT INTO viajes_pedidos (id_viaje, id_pedido, peso, volumen)
            SELECT viaje_id, pedido_id, peso, volumen FROM pedidos WHERE id_pedido = pedido_id;

            -- Actualizar el peso total del viaje
            SET peso_actual = peso_actual + pedido_peso;
        ELSE
            -- Si se excede la capacidad, salir del bucle
            LEAVE read_loop;
        END IF;
    END LOOP;

    -- Cerrar cursor
    CLOSE pedidos_cursor;
    
END;
//

DELIMITER ;


# TRIGGER 1
DELIMITER //

CREATE TRIGGER actualizar_estado_viaje
AFTER UPDATE ON pedidos
FOR EACH ROW
BEGIN
    DECLARE pedidos_pendientes INT;

    -- Verificar si el estado del pedido cambió a "Entregado"
    IF NEW.estado_pedido = 'Entregado' THEN
        -- Contar cuántos pedidos aún no están entregados para el mismo viaje
        SELECT COUNT(*) INTO pedidos_pendientes
        FROM viajes_pedidos vp
        JOIN pedidos p ON vp.id_pedido = p.id_pedido
        WHERE vp.id_viaje = (
            SELECT vp2.id_viaje FROM viajes_pedidos vp2 WHERE vp2.id_pedido = NEW.id_pedido LIMIT 1
        )
        AND p.estado_pedido != 'Entregado';

        -- Si no quedan pedidos pendientes, actualizar el estado del viaje a "Completado"
        IF pedidos_pendientes = 0 THEN
            UPDATE viajes 
            SET estado_viaje = 'Completado'
            WHERE id_viaje = (
                SELECT vp3.id_viaje FROM viajes_pedidos vp3 WHERE vp3.id_pedido = NEW.id_pedido LIMIT 1
            );
        END IF;
    END IF;
END;

//

DELIMITER ;

#TRIGGER N°2
DELIMITER //

CREATE TRIGGER verificar_disponibilidad_chofer
BEFORE UPDATE ON viajes
FOR EACH ROW
BEGIN
    DECLARE viajes_activos INT;

    -- Contar si el chofer tiene otro viaje en tránsito
    SELECT COUNT(*) INTO viajes_activos
    FROM viajes
    WHERE id_chofer = NEW.id_chofer
    AND estado_viaje = 'En transito';

    -- Si ya tiene un viaje activo, evitar asignación
    IF viajes_activos > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: El chofer ya tiene un viaje en tránsito';
    END IF;
END;

//
DELIMITER ;

