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
--            AU : 21/11/2024 
--------------------------------------------------------------------------------

Create Table FIDVALSAC.KCOENT
(
   NumeroLivraison        For Column  NUMLIV Decimal(8, 0)   Not Null,
   NumeroEdition          For Column  NUMEDI Decimal(2, 0)   Not Null,
   LivraisonTimeStamp     For Column  LIVDAT Timestamp       Not Null,
   LivraisonUtilisateur   For Column  LIVUSR Char(10)        Not Null,
   TopRetour              For Column  TOPRET Char(1)         Not Null,
   RetourTimeStamp        For Column  RETDAT Timestamp       Not Null,
   RetourUtilisateur      For Column  RETUSR Char(10)        Not Null
) ;


Label On Table FIDVALSAC.KCOENT Is 'Consignes.: entetes des livraisons';

-- Définition de la clé primaire
Alter Table FIDVALSAC.KCOENT
   Add Primary Key (NumeroLivraison);

-- Column headings are defined in 20-character sections

Label On FIDVALSAC.KCOENT
(
   NumeroLivraison        Is    'Numero              Livraison',
   NumeroEdition          Is    'Numero              Edition',
   LivraisonTimeStamp     Is    'Livraison           TimeStamp',
   LivraisonUtilisateur   Is    'Livraison           Utilisateur',
   TopRetour              Is    'Top                 Retour',
   RetourTimeStamp        Is    'Retour              TimeStamp',
   RetourUtilisateur      Is    'Retour              Utilisateur'
);

Label On FIDVALSAC.KCOENT
(
   NumeroLivraison        Text Is    'Numero Livraison',
   NumeroEdition          Text Is    'Numero Edition',
   LivraisonTimeStamp     Text Is    'Horodatage Livraison',
   LivraisonUtilisateur   Text Is    'Utilisateur Livraison',
   TopRetour              Text Is    'Top Retour',
   RetourTimeStamp        Text Is    'Horodatage Retour',
   RetourUtilisateur      Text Is    'Utilisateur Retour'
);