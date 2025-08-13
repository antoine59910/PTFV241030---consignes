-------------------------------------------------------------------------------
--   Livraison Consignes.: Gestion: verrouillage des livraisons
--
--                      - Clé : Rang
--
-- Fichier de travail
-- Permet de 
--  verrouiller un numero de livraison en modification/création
-----------------------------------------------------------------------------
--
--    ECRIT   DU : 21/11/2024                 PAR : Ang (Antilles Glaces)
--            AU : 21/11/2024 
--------------------------------------------------------------------------------

Create Table FIDVALSAC.KCOF10
(
   NumeroBLConsignes      For Column  NUMBLC Decimal(8, 0)   Not Null,
   Utilisateur            For Column  UTILIS Char(10)   Not Null,
   StartTimeStamp         For Column  STTIMS Timestamp   Not Null,
   EndTimeStamp           For Column  EDTIMS Timestamp ,
   CodeAction             For Column  CODEAC Char(1)   Not Null,
   LockFlag               For Column  LOCKFG Char(1)   Not Null
) ;
  

Label On Table FIDVALSAC.KCOF10 Is 'Consignes.: verrouillage des livraisons';

-- Column headings are defined in 20-character sections

Label On FIDVALSAC.KCOF10
(
   NumeroBLConsignes          Is    'Numero              BL Consignes',
   Utilisateur                Is    'Utilisateur',
   StartTimeStamp             Is    'Start               TimeStamp',
   EndTimeStamp               Is    'End                 TimeStamp',   
   CodeAction                 Is    'Code                Action',
   LockFlag                   Is    'Lock                Flag'       
);

Label On FIDVALSAC.KCOF10
(
   NumeroBLConsignes          Text Is    'Numero bon de livraison consignes',
   Utilisateur                Text Is    'Utilisateur',
   StartTimeStamp             Text Is    'Start TimeStamp',
   EndTimeStamp               Text Is    'End TimeStamp',   
   CodeAction                 Text Is    'Code Action',
   LockFlag                   Text Is    'Lock Flag'       
);
