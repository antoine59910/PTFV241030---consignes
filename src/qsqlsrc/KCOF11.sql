-------------------------------------------------------------------------------
--   Livraison Consignes.: Saisies: Sauvegarde des saisies des quantités
--
--                      - Clé : Rang
--
-- Fichier de travail
-- Permet de
-- Passer les informations de saisies des utilisateurs à d'autres programmes
-- Pour écriture dans les tables suivantes (PGM KCOP12): 
--  - VRESTK (Insert mouvement de stocks)           
--  - KCOENT (Entête des livraisons de consignes)   
--  - KCOLIG (Lignes des livraisons de consignes)   
--  - KCOCUM (Cumul des consignes par client)       
-- Pour édition du bon de mise à disposition des consignes (PGM KCOP13)
-----------------------------------------------------------------------------
--
--    ECRIT   DU : 02/12/2024                 PAR : Ang (Antilles Glaces)
--            AU : 02/12/2024 
--------------------------------------------------------------------------------

Create Table FIDVALSAC.KCOF11
(
   NumeroLivraison        For Column  NUMLIV Decimal(8, 0)   Not Null,
   CodeArticle            For Column  CODART Char(20) Not null,
   QuantiteLivree         For Column  QTELIV Decimal(5,0),
   QuantiteRetournee      For Column  QTERET Decimal(5,0) 
) ;

-- Définition de la clé primaire
Alter Table FIDVALSAC.KCOF11
   Add Primary Key (NumeroLivraison, CodeArticle);

Label On Table FIDVALSAC.KCOF11 Is 'Consignes.: tsf. des saisies livraisons';

-- Column headings are defined in 20-character sections

Label On FIDVALSAC.KCOF11
(
   NumeroLivraison            Is    'Numero              Livraison',
   CodeArticle                Is    'Code                Article',
   QuantiteLivree             Is    'Quantite            Livree',
   QuantiteRetournee          Is    'Quantite            Retournee'
);

Label On FIDVALSAC.KCOF11
(
   NumeroLivraison           Text Is    'Numero Livraison',
   CodeArticle               Text Is    'Code Article',
   QuantiteLivree            Text Is    'Quantite Livree',
   QuantiteRetournee         Text Is    'Quantite Retournee'     
);
