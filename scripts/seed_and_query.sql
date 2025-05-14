-- 1) Crear la base de datos
CREATE DATABASE IF NOT EXISTS ejemplo;
-- insertar_datos.sql

USE ejemplo;

-- Insertar datos en piloto
INSERT INTO piloto (nombre)
VALUES 
  ('Juan Pérez'),
  ('María Gómez'),
  ('Carlos Díaz');  -- Sintaxis INSERT INTO columnas + VALUES :contentReference[oaicite:0]{index=0}

-- Insertar datos en avion
INSERT INTO avion (modelo, piloto_id)
VALUES 
  ('Boeing 737', 1),
  ('Airbus A320', 2);  -- Se puede omitir columnas si se insertan todas en orden :contentReference[oaicite:1]{index=1}

-- Insertar datos en seguro
INSERT INTO seguro (poliza, id_avion)
VALUES 
  ('POL-12345', 1),
  ('POL-67890', 2);  -- INSERT múltiple para mejorar eficiencia :contentReference[oaicite:2]{index=2}

-- Visualizar contenido de las tablas
SELECT * FROM piloto;
SELECT * FROM avion;
SELECT * FROM seguro;

