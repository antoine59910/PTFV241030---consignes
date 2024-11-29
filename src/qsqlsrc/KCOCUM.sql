-------------------------------------------------------------------------------
--   Table des cumuls consignes par clients
--
--                      - Clé : Code client + Code article
--
-- Fichier des cumuls consignes par clients
--      - Code client
--      - Code article
--      - Quantité livrée : saisie lors d'une livraison
--      - Quantité retournée : saisie lors d'un retour
--      - Quantité cumul écart : saisie lors d'un inventaire
--      - Quantité théorique en stock : livré - retourné + écart
--      - Type opération: Livraison, Retour, Inventaire
--      - Horodatage saisie
--      - Profil utilisateur
-----------------------------------------------------------------------------
--
--    ECRIT   DU : 27/11/2024                 PAR : Ang (Antilles Glaces)
--            AU : 27/11/2024 
--------------------------------------------------------------------------------

Create or Replace Table FIDVALSAC.KCOCUM
(
   CodeClient             For Column CODCLI Char(20)        Not Null,
   CodeArticle            For Column CODART Char(20)        Not Null,
   QuantiteLivree         For Column QTLIVR Decimal(4, 0)   Not Null,
   QuantiteRetournee      For Column QTRET  Decimal(4, 0)   Not Null,
   QuantiteCumulEcart     For Column QTCUME Decimal(4, 0)   Not Null,
   QuantiteTheoriqueStock For Column QTHSTK Decimal(4, 0)   Not Null,
   HorodatageSaisie       For Column HORSAI Timestamp       Not Null,
   TypeOperation          For Column TYPOPE Char(20)         Not Null,
   ProfilUser             For Column PROFUS Char(10)        Not Null
) ;

-- Définition de la clé primaire
Alter Table FIDVALSAC.KCOCUM
   Add Primary Key (CodeClient, CodeArticle);

Label On Table FIDVALSAC.KCOCUM Is 'Consignes.: cumuls par clients';

-- Column headings are defined in 20-character sections
Label On FIDVALSAC.KCOCUM
(
   CodeClient             Is 'Code                Client',
   CodeArticle            Is 'Code                Article',
   QuantiteLivree         Is 'Quantite            Livree',
   QuantiteRetournee      Is 'Quantite            Retournee',
   QuantiteCumulEcart     Is 'Quantite            Cumul Ecart',
   QuantiteTheoriqueStock Is 'Quantite            Stock Theorique',
   HorodatageSaisie       Is 'Horodatage          Saisie',
   TypeOperation          Is 'Type                Operation',
   ProfilUser             Is 'Profil              Utilisateur'
);

Label On FIDVALSAC.KCOCUM
(
   CodeClient             Text Is 'Code Client',
   CodeArticle            Text Is 'Code Article', 
   QuantiteLivree         Text Is 'Quantite Livree',
   QuantiteRetournee      Text Is 'Quantite Retournee',
   QuantiteCumulEcart     Text Is 'Quantite Cumul Ecart',
   QuantiteTheoriqueStock Text Is 'Quantite Stock Theorique',
   HorodatageSaisie       Text Is 'Horodatage Saisie',
   TypeOperation          Text Is 'Type Operation',
   ProfilUser             Text Is 'Profil Utilisateur'
);