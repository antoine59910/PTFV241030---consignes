CREATE TABLE FIDVALSAC.SQLERRORS (
    ERROR_ID INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    TIMESTAMP TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- Informations Job
    JOB_NAME VARCHAR(28),      -- Nom complet du job (ex: 123456/USER/JOBNAME)
    USER_NAME VARCHAR(10),     -- Utilisateur
    JOB_NUMBER CHAR(6),        -- Numéro du job
    -- Informations Programme
    PROGRAM_NAME VARCHAR(10),  -- Programme qui a généré l'erreur
    PROGRAM_LIB VARCHAR(10),   -- Bibliothèque du programme
    MODULE_NAME VARCHAR(10),   -- Nom du module 
    PROCEDURE_NAME VARCHAR(256), -- Nom de la procédure
    SOURCE_LINE INTEGER,       -- Ligne de code source
    -- Informations SQL
    SQLCODE INTEGER,          -- Code d'erreur SQL
    SQLSTATE CHAR(5),         -- État SQL
    MESSAGE_ID CHAR(7),       -- ID du message d'erreur
    MESSAGE_TEXT VARCHAR(1000), -- Texte du message d'erreur
    -- Informations Requête
    SCHEMA_NAME VARCHAR(128),  -- Schéma concerné
    TABLE_NAME VARCHAR(128),   -- Table concernée 
    COLUMN_NAME VARCHAR(128),  -- Colonne concernée
    SQL_STATEMENT VARCHAR(2000), -- Requête SQL qui a généré l'erreur
    -- Données complémentaires
    ADDITIONAL_INFO VARCHAR(1000) -- Pour stocker des infos supplémentaires si besoin
);

SELECT FIELD_NAME, FIELD_DATATYPE_NAME, FIELD_DESCRIPTION
FROM QSYS2.STATEMENT_DIAG_ITEMS 
ORDER BY FIELD_NAME;