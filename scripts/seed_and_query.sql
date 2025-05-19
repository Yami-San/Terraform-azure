USE mySqlDb;
GO

-- Insertar pilotos
INSERT INTO dbo.Piloto (nombre)
VALUES ('Juan Pérez'), ('María López');
GO

-- Insertar aviones (asumimos piloto_id 1 y 2 existen)
INSERT INTO dbo.Avion (piloto_id, modelo, matricula)
VALUES (1, 'Boeing 737', 'ABC-123'),
       (2, 'Airbus A320', 'XYZ-789');
GO

-- Insertar seguros (asumimos avion_id 1 y 2 existen)
INSERT INTO dbo.Seguro (avion_id, poliza)
VALUES (1, 'POL-001'), (2, 'POL-002');
GO

-- Consultas de verificación
SELECT * FROM dbo.Piloto;
SELECT * FROM dbo.Avion;
SELECT * FROM dbo.Seguro;
GO
