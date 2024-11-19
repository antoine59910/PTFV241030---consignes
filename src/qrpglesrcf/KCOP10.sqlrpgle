**free
Ctl-opt Option(*srcstmt:*nodebugio ) AlwNull(*usrctl) UsrPrf(*owner)
        DatFmt(*eur) DatEdit(*dmy) TimFmt(*hms) dftactgrp(*no);

// Appel ligne de commande :
// CALL PGM(KCOP10) PARM((GER  (*CHAR 4)) (LIVCON (*CHAR 6))
//  ('Gestion livraison consignes' (*CHAR 30)))

///
/// --------------------------------------------------------------
///       NOM        : KCOP10              TYPE : Interactif
///
///  TITRE      : Suivi des articles consignés.: Gestion livraisons des consignes
///
///  FONCTIONS  :
///              Gestion des livraisons et retours des consignes chez les clients.
///              Appel du programme KCOP20 pour saisie de la livraison/retour des consignes
///
///              Touches de fonction :
///                      F2 : Utilisateur
///                      F3 : Fin
///                      F6 : Services
///                      F9 : Nouvelle livraison
///
///              Filtres disponibles (type "Commence par" et additionnel) :
///                      - Numéro de livraison
///                      - Numéro de facture
///                      - Tournée
///                      - Code client
///                      - Désignation client (Filtre type "Contient")
///                      - Date de livraison confirmée
///              Option "Masquer les retours traités" (activée par défaut) 
///              pour n'afficher que les livraisons sans retour
///
///              Actions possibles sur les livraisons :
///                      1 : Modifier une livraison
///                      2 : Visualiser une livraison
///                      3 : Créer un nouveau retour
///                      4 : Modifier un retour
///                      5 : Visualiser un retour
///
///  APPELE PAR : - Moniteur
///
///  PARAMETRES :
/// - D'appel :
///      - £CodeVerbe
///      - £CodeObjet
///      - £LibelleAction
///
/// - Retournés
///
///  ECRIT DU   : 11/11/2024            PAR : ANg (Antilles Glaces)
///        AU   : 19/11/2024
///
/// ---------------------------------------------------------------------

// Déclaration fichier

// --- Fichiers --------------------------------------------------------
Dcl-F KCOP10E  WorkStn
               SFile(GESTIONSFL:fichierDS.rang_sfl)//SFILE(Format:rang)
               InfDS(fichierDS)//Permet d'avoir des informations sur le sous-fichier en cours
               IndDs(Indicateur)
               Alias;//pour mettre les indicateurs dans une DS et les nommer


// --- Appels de prototypes et de leurs DS-------------------------------
// Permet de faire des commandes CL
Dcl-Pr QCMDEXC ExtPgm('QCMDEXC') ;
    cde Char(200) const;
    cdl Packed(15:5) const;
End-Pr ;

// Prototype des programmes appelés
Dcl-Pr KCOP20 ExtPgm;
    NumeroLivraison Packed(7:0) const;
    Mode Char(13) const;//Livraison ou retour
    Droits Char(13) const;//Visualiser, modifier, créer,...
    CodeSociete Char(2) const;
    ReturnOperationEffectuee char(1);
End-Pr ;

// Recherche valeur table chartreuse
/DEFINE PR_VORPAR
// Fenêtre utilisateur
/DEFINE PR_GOAFENCL
// Fenêtre service
/DEFINE PR_GOASER

/INCLUDE qincsrc,prototypes

/UNDEFINE PR_VORPAR
/UNDEFINE PR_GOAFENCL
/UNDEFINE PR_GOASER

// --- Variables -------------------------------------------------------
Dcl-S CommandeCL                                  VarChar(200);
Dcl-S BibliothequeFichier                         Char(9);
Dcl-S NombreTotalLignesSF                         Packed(4:0);
Dcl-S Fin                                         Ind();

// --- Constantes -------------------------------------------------------
Dcl-C VISUALISATION 'VISUALISATION';
Dcl-C MODIFICATION 'MODIFICATION';
Dcl-C CREATION 'CREATION';


// --- Data-structures Ecran    --------------------------------------
Dcl-Ds DSPFSauve Qualified;
    Totalite                                Char(4000);
    Element                                 Char(80) Dim(50) Overlay(Totalite);
    Clef                                    Char(30) Overlay(Element);
    Valeur                                  Char(50) Overlay(Element:*Next);
End-Ds;


// --- Data-structures Indicateurs--------------------------------------
Dcl-Ds Indicateur qualified;

    SousFichierDisplay                              Ind Pos(51);
    SousFichierDisplayControl                       Ind Pos(52);
    SousFichierClear                                Ind Pos(53);
    SousFichierEnd                                  Ind Pos(54);

End-Ds ;

// --- Data-structure système ------------------------------------------
/INCLUDE qincsrc,rpg_PSDS

// --- Data-structure sous-fichier -------------------------------------
/INCLUDE qincsrc,rpg_INFDS

// ---------------------------------------------------------------------
//
//                              PROGRAMME   PRINCIPAL
//
// ---------------------------------------------------------------------
// Initialisation SQL :
Exec Sql
     Set Option Commit = *None;

// Paramètres
Dcl-Pi *N;
    // entrées
    £CodeVerbe                                   Char(4);
    £CodeObjet                                   Char(6);
    £LibelleAction                               Char(30);

    // sorties
End-Pi ;

// Initialisation du programme
InitialisationProgramme();

Fin = *Off;
DoW not Fin;

    Fin=*On;
EndDo;

*Inlr=*On;


// ----------------------------------------------------------------------------
//
//                                  PROCEDURES
//
// ----------------------------------------------------------------------------

///
// Initialisation du programme
// Initialisations :
// - Récupération Bibliothèque des fichiers
// - Création du UserIndex si non existant
// - Purge du fichier des blocages antérieurs à J-1
///

Dcl-Proc InitialisationProgramme;

End-Proc;
