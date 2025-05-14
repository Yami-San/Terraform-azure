-- crear_tablas.sql
CREATE DATABASE IF NOT EXISTS ejemplo;
USE ejemplo;
-- Crear tabla piloto
CREATE TABLE piloto (
    id_piloto SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);

-- Crear tabla avion
CREATE TABLE avion (
    id_avion SERIAL PRIMARY KEY,
    modelo VARCHAR(100) NOT NULL,
    piloto_id INTEGER REFERENCES piloto(id_piloto)
);

-- Crear tabla seguro
CREATE TABLE seguro (
    id_seguro SERIAL PRIMARY KEY,
    poliza VARCHAR(100) NOT NULL,
    id_avion INTEGER REFERENCES avion(id_avion)
);