**free
Ctl-opt Option(*srcstmt:*nodebugio ) AlwNull(*usrctl) UsrPrf(*owner)
        DatFmt(*eur) DatEdit(*dmy) TimFmt(*hms) dftactgrp(*no);

// Appel ligne de commande :
// CALL PGM(KCOP20) PARM((GER  (*CHAR 4)) (INVCON (*CHAR 6))
//  ('Gestion inventaire consignes' (*CHAR 30)))

///
// --------------------------------------------------------------
//       NOM        : KCOP20              TYPE : Interactif
//
//  TITRE      : Suivi des articles consignés.: Gestion des inventaires des consignes
//
//  FONCTIONS  :
//              Gestion des inventaires  des articles consignés
//              Appel du programme KCOP11 pour saisie de la livraison/retour des consignes
//              Le sous-fichier est chargé en fonction de la table KCOENT pour les entêtes des liv-
//              raisons

//  APPELE PAR : - Moniteur
//
//  PARAMETRES :
// - D'appel :
//      - £CodeVerbe
//      - £CodeObjet
//      - £LibelleAction
//
// - Retournés
//
//  ECRIT DU   : 12/03/2025            PAR : ANg (Antilles Glaces)
//        AU   : 12/03/2025
//
/// ---------------------------------------------------------------------

// --- Fichiers --------------------------------------------------------
Dcl-F KCOP20E  WorkStn
               SFile(GESTIONSFL:fichierDS.rang_sfl)//SFILE(Format:rang)
               InfDS(fichierDS)//Permet d'avoir des informations sur le sous-fichier en cours
               IndDs(Indicateur)
               Alias;//pour mettre les indicateurs dans une DS et les nommer

// --- Tables -----------------------------------------------------------
//Consignes : Cumul des articles par clients
Dcl-Ds KCOCUM_t extname('KCOCUM') qualified template alias;
End-Ds;
//Mouvements de stock en attente d'intégration
Dcl-Ds VRESTK_t extname('VRESTK') qualified template;
End-Ds;

//Variables pour K£PIMP
Dcl-Ds K£PIMP qualified ;
    p_CodeEdition char(10);
    p_CodeModule Char(2);
    p_User Char(10);
    r_outq char(20);
    r_nbexj char(2);    
    r_nbexs char(2);
    r_nbexm char(2);
    r_suspe char(4);  //C est le paramètre HOLD de OVRPRTF qui permet de        suspendre 
                    //le fichier spoule avant impression (hold=*YES/hold=*NO)
    r_conserver char(4);
End-Ds;

//Societe
Dcl-Ds Societe qualified;
    Code Char(2);
    Libelle Char(26);
    BilbiothequeFichier Char(9);
End-Ds;

Dcl-Ds VRESTKDS Qualified;
    CodeSociete                   Char(2);
    CodeDepot                     Char(3);
    NumeroMouvement               Zoned(8:0);
    MouvementJour                 Zoned(2:0);
    MouvementMois                 Zoned(2:0);
    MouvementSiecle               Zoned(2:0);
    MouvementAnnee                Zoned(2:0);
    CodeMouvement                 Char(2);
    CodeArticle                   Char(20);
    QuantiteMouvement             Zoned(11:3);
    CodeSection                   Char(9);
    CodeProjet                    Char(9);
    CodeUniteDeGestion            Char(3);
    PrixUnitaireMouvement         Zoned(13:4);
    CodeEdition                   Char(1);
    PumpAnterieur                 Zoned(13:4);
    QuantiteAcheteeDelaisAppro    Zoned(13:3);
    QuantiteModifiantEncours      Zoned(13:3);
    PrixAchat_Fabrication         Zoned(13:4);
    CodeGenerationCompta          Char(1);
    LibelleMouvement              Char(30);
    RefMouvementNumBLNumRecep     Char(8);
    Emplacement                   Char(7);
    Lot                           Char(13);
    ElementDeLot                  Char(8);
    CodeProfil                    Char(10);
    CreationJour                  Zoned(2:0);
    CreationMois                  Zoned(2:0);
    CreationAnnee                 Zoned(2:0);
    CreationSiecle                Zoned(2:0);
    NomProgramme                  Char(10);
    ModifHeure                    Zoned(2:0);
    ModifMinute                   Zoned(2:0);
    ModifSeconde                  Zoned(2:0);
    VALS                          Char(1);
    CodeEtablissement             Char(3);
    NumeroDePoste                 Zoned(3:0);
    TopReaj                       Char(1);
    ClientOuFournisseur           Char(9);
    DesignationMouvement          Char(15);
    DepotTransf                   Char(3);
    QuantiteLogistique            Zoned(11:3);
    VariableLogistique            Char(2);
    VariablePromo                 Char(2);
    FlagTop1                      Char(1);
    FlagTop2                      Char(1);
    SpecifAlpha25                 Char(25);
End-Ds;

//TABVV XCOPAR
Dcl-Ds ParametresConsigne qualified;
    XLIPAR Char(100);
    TypeArticle Char(1) Overlay(XLIPAR);
    CodeMouvementEntree Char(2) Overlay(XLIPAR:*NEXT);
    TopPrealimentationRetour Char(1) Overlay(XLIPAR:*NEXT);
    NombreExemplairesBL Char(2) Overlay(XLIPAR:*NEXT);
    CodeDepotConsignes Char(3) Overlay(XLIPAR:*NEXT);
    CodeMouvementSortie Char(2) Overlay(XLIPAR:*NEXT);
End-Ds;

// --- Appels de prototypes et de leurs DS-------------------------------
// Recherche valeur table chartreuse
/DEFINE PR_VORPAR
// Fenêtre utilisateur
/DEFINE PR_GOAFENCL
// Fenêtre service
/DEFINE PR_GOASER
// Récupération données clients
/DEFINE PR_VMRICL
// Permet de savoir si la quantité en stock est suffisante
/DEFINE PR_VMTSTP   
// Recherche tarifaire
/DEFINE PR_VMRPUT 
// Acceptation mouvements de stock VRESTK
/DEFINE PR_VSLMVT2 

/INCLUDE qincsrc,prototypes

/UNDEFINE PR_VORPAR
/UNDEFINE PR_GOAFENCL
/UNDEFINE PR_GOASER
/UNDEFINE PR_VMRICL
/UNDEFINE PR_VMTSTP
/UNDEFINE PR_VSLMVT2 

// --- Variables -------------------------------------------------------
Dcl-S NombreTotalLignesSF Packed(4:0);
Dcl-S Fin ind;
Dcl-S FinFenetre ind;
Dcl-S Refresh ind;
Dcl-S CommandeCL varChar(200);

// Constantes ---------------------------------------------------------
Dcl-C MODIFICATION 'MODIFICATION';
Dcl-C VISUALISATION 'VISUALISATION';
Dcl-C TABVV_PARAMETRESCONSIGNE 'XCOPAR';
Dcl-C TABLE_CHARTREUSE_MOUVEMENT_STOCK_NUM 'NUMT';
Dcl-S PRTF_CODE_MODULE Char(2) Inz('CO');  // Code module pour KPIMP
Dcl-S PRTF_CODE_EDITION Char(10) Inz('KCOP20PM'); // Code édition pour KPIMP
Dcl-S ENTREE_STOCK char(1) Inz('E');
Dcl-S SORTIE_STOCK char(1) Inz('S');

// --- Data-structures Indicateurs--------------------------------------
Dcl-Ds Indicateur qualified;

    SousFichierDisplay                              Ind Pos(51);
    SousFichierDisplayControl                       Ind Pos(52);
    SousFichierClear                                Ind Pos(53);
    SousFichierEnd                                  Ind Pos(54);
    SousFichierCouleurBleu                          Ind Pos(70);

    GESTIONSFL_ProtegerQuantiteInventaire           Ind Pos(40);

    // Indicateurs d affichage
    MasquerMessageErreur                        Ind Pos(82);
    MasquerMessageInfo                          Ind Pos(83);
    MasquerMessageErreurWindow                  Ind Pos(84);    
End-Ds ;

// --- Data-structure système ------------------------------------------
/INCLUDE qincsrc,rpg_PSDS

// --- Data-structure sous-fichier -------------------------------------
/INCLUDE qincsrc,rpg_INFDS

// ---------------------------------------------------------------------
//                     PROGRAMME PRINCIPAL
// ---------------------------------------------------------------------
// Paramètres
Dcl-Pi *N;
     // entrées
    £CodeVerbe                                   Char(4) ;
    £CodeObjet                                   Char(6);
    £LibelleAction                               Char(30);

    // sorties
End-Pi ;
// ---------------------------------------------------------------------

// Initialisation SQL :
Exec Sql
     Set Option Commit = *None;


// Initialisation de début de programme
//InitialisationProgramme();
Select;
    //Création d'inventaire de consigne
    when (£CodeVerbe = CREATION);
        //Protection EcranQuantitéEnStock
        //F9 possible : ouvre fenetre pour saisie code article (F4 possible) + quantité

    when (£CodeVerbe = VISUALISATION);
        //Chargement du sous fichier
        //Protection EcranQuantitéInventorié
    other;
EndSl;

// Affectation des variables de sorties
*Inlr= *On;