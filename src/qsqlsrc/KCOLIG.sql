-------------------------------------------------------------------------------
--   Table des lignes des livraisons de consignes
--
--                      - Clé : Numéro de livraison + Code article
--
-- Fichier des lignes des livraisons de consignes
--      - Numéro de Livraison
--      - Code article
--      - Quantité livrée
--      - Quantité retournée
-----------------------------------------------------------------------------
--
--    ECRIT   DU : 21/11/2024                 PAR : Ang (Antilles Glaces)
--            AU : 21/11/2024 
--------------------------------------------------------------------------------

Create Table FIDVALSAC.KCOLIG
(
   NumBLConsignes         For Column  NUMBLC Decimal(8, 0)   Not Null,
   CodeArticle            For Column  CODART Char(20)        Not Null,
   QuantiteLivree         For Column  QTLIVR Decimal(4, 0)   Not Null,
   QuantiteRetournee      For Column  QTRET  Decimal(4, 0)   Not Null
) ;

-- Définition de la clé primaire
Alter Table FIDVALSAC.KCOLIG
   Add Primary Key (NumBLConsignes, CodeArticle);

Label On Table FIDVALSAC.KCOLIG Is 'Consignes.: lignes des livraisons';

-- Column headings are defined in 20-character sections
Label On FIDVALSAC.KCOLIG
(
   NumBLConsignes         Is    'Numero              BL Consignes',
   CodeArticle            Is    'Code                Article',
   QuantiteLivree         Is    'Quantite            Livree',
   QuantiteRetournee      Is    'Quantite            Retournee'
);

Label On FIDVALSAC.KCOLIG
(
   NumBLConsignes         Text Is    'Numero BL Consignes',
   CodeArticle            Text Is    'Code Article',
   QuantiteLivree         Text Is    'Quantite Livree',
   QuantiteRetournee      Text Is    'Quantite Retournee'
);