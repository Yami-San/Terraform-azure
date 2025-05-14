-- scripts/drop_database.sql
DROP DATABASE ejemplo;
-- Elimina las tres tablas si existen
DROP TABLE IF EXISTS seguro CASCADE;
DROP TABLE IF EXISTS avion CASCADE;
DROP TABLE IF EXISTS piloto CASCADE;
