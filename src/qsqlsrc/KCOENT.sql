-------------------------------------------------------------------------------
--   Table des entêtes des livraisons de consignes
--
--                      - Clé : Numéro de livraison
--
-- Fichier des entêtes des livraisons de consignes
--      - Numéro de Livraison
--      - Numéro d'édition du bon de mise à disposition
--      - Horodatage saisie livraison
--      - Utilisateur saisie livraison
--      - Top Retour (Permet de savoir si le retour de livraison a été saisi)
--      - Horodatage saisie retour
--      - Utilisateur saisie retour
-----------------------------------------------------------------------------
--
--    ECRIT   DU : 21/11/2024                 PAR : Ang (Antilles Glaces)
--            AU : 16/04/2025 
--------------------------------------------------------------------------------

Create Table FIDVALSAC.KCOENT
(
   NumeroBLConsignes      For Column  NUMBLC Decimal(8, 0)   Not Null,
   NumeroLivraison        For Column  NUMLIV Decimal(8, 0)           ,
   NumeroFacture          For Column  NUMFAC Decimal(8, 0)           ,
   CodeTournee            For Column  NUMTOU Char(3)                 ,
   CodeClient             For Column  CODCLI Char(9)         Not Null, 
   DesignationClient      For Column  DESCLI Char(30)        Not Null,
   DateLivraison          For Column  DTELIV Date                    ,
   NombreEdition          For Column  NNBEDI Decimal(2, 0)   Not Null,
   LivraisonTimeStamp     For Column  LIVDAT Timestamp               ,
   LivraisonUtilisateur   For Column  LIVUSR Char(10)                ,
   TopRetour              For Column  TOPRET Char(1)                 ,
   RetourTimeStamp        For Column  RETDAT Timestamp               ,
   RetourUtilisateur      For Column  RETUSR Char(10)        
) ;


Label On Table FIDVALSAC.KCOENT Is 'Consignes.: entetes des livraisons';

-- Définition de la clé primaire
Alter Table FIDVALSAC.KCOENT
   Add Primary Key (NumeroBLConsignes);

-- Column headings are defined in 20-character sections

Label On FIDVALSAC.KCOENT
(
   NumeroBLConsignes      Is    'Numero              BL Consignes',
   NumeroLivraison        Is    'Numero              Livraison',
   NumeroFacture          Is    'Numero              Facture',
   CodeTournee            Is    'Code                Tournee',
   CodeClient             Is    'Code                Client',
   DesignationClient      Is    'Désignation         Client',
   DateLivraison          Is    'Date                Livraison',
   NombreEdition          Is    'Nombre              Edition',
   LivraisonTimeStamp     Is    'Livraison           TimeStamp',
   LivraisonUtilisateur   Is    'Livraison           Utilisateur',
   TopRetour              Is    'Top                 Retour',
   RetourTimeStamp        Is    'Retour              TimeStamp',
   RetourUtilisateur      Is    'Retour              Utilisateur'
);

Label On FIDVALSAC.KCOENT
(
   NumeroBLConsignes            Text Is    'Numero BL Consignes',
   NumeroLivraison        Text Is    'Numero Livraison',
   NumeroFacture          Text Is    'Numero Facture',
   CodeTournee            Text Is    'Code Tournee',
   CodeClient             Text Is    'Code Client',
   DesignationClient      Text Is    'Désignation Client',
   DateLivraison          Text Is    'Date Livraison',
   NombreEdition          Text Is    'Nombre Edition',
   LivraisonTimeStamp     Text Is    'Livraison TimeStamp',
   LivraisonUtilisateur   Text Is    'Livraison Utilisateur',
   TopRetour              Text Is    'Top Retour',
   RetourTimeStamp        Text Is    'Retour TimeStamp',
   RetourUtilisateur      Text Is    'Retour Utilisateur'
);