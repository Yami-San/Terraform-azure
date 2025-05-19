-- Usar la base de datos existente
USE mySqlDb;
GO

-- --------------------------------------------
-- TABLA Piloto
-- --------------------------------------------
IF OBJECT_ID('dbo.Piloto', 'U') IS NOT NULL
  DROP TABLE dbo.Piloto;
GO

CREATE TABLE dbo.Piloto (
    piloto_id   INT   IDENTITY(1,1) PRIMARY KEY,
    nombre      NVARCHAR(100) NOT NULL
);
GO

-- --------------------------------------------
-- TABLA Avion
-- --------------------------------------------
IF OBJECT_ID('dbo.Avion', 'U') IS NOT NULL
  DROP TABLE dbo.Avion;
GO

CREATE TABLE dbo.Avion (
    avion_id    INT   IDENTITY(1,1) PRIMARY KEY,
    piloto_id   INT   NOT NULL,
    modelo      NVARCHAR(100) NOT NULL,
    matricula   NVARCHAR(50) NOT NULL,
    CONSTRAINT FK_Avion_Piloto
      FOREIGN KEY (piloto_id) REFERENCES dbo.Piloto(piloto_id)
);
GO  -- :contentReference[oaicite:0]{index=0} :contentReference[oaicite:1]{index=1}

-- --------------------------------------------
-- TABLA Seguro
-- --------------------------------------------
IF OBJECT_ID('dbo.Seguro', 'U') IS NOT NULL
  DROP TABLE dbo.Seguro;
GO

CREATE TABLE dbo.Seguro (
    seguro_id   INT   IDENTITY(1,1) PRIMARY KEY,
    avion_id    INT   NOT NULL,
    poliza      NVARCHAR(100) NOT NULL,
    CONSTRAINT FK_Seguro_Avion
      FOREIGN KEY (avion_id) REFERENCES dbo.Avion(avion_id)
);
GO  -- :contentReference[oaicite:2]{index=2}
