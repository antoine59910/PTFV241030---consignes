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
// Variables :
// Variables du format GESTIONBAS
// ECRAN2MESSAGEERREUR char(30);           // Message d'erreur affiché à l'écran 2
// ECRAN2MESSAGEINFO char(40);             // Message d'information affiché à l'écran 2
// ECRANVERBEOBJET char(10);               // Verbe et objet de l'écran

// Variables du format GESTIONCTL
// ECRANLIGNESOUSFICHIER packed(4:0);      // Numéro de la ligne du sous-fichier
// ECRANLIBELLESOCIETE char(20);           // Libellé de la société
// ECRANLIBELLEACTION char(30);            // Libellé de l'action en cours
// ECRANNUMEROLIVRAISONFILTRE packed(8:0); // Filtre sur le numéro de livraison
// ECRANNUMEROFACTUREFILTRE packed(8:0);   // Filtre sur le numéro de facture
// ECRANNUMEROTOURNEEFILTRE char(2);       // Filtre sur le numéro de tournée
// ECRANCODECLIENTFILTRE packed(9:0);      // Filtre sur le code client
// ECRANDESIGNATIONCLIENTFILTRE char(30);  // Filtre sur la désignation du client
// ECRANDATELIVRAISONFILTRE date;          // Filtre sur la date de livraison
// ECRANAFFICHERLIVRAISONFILTRE char(1);   // Filtre pour afficher ou masquer les livraisons

// Variables du format GESTIONSFL
// ECRANLIGNEOPTIONUT char(1);             // Option utilisateur sur la ligne
// ECRANLIGNENUMEROLIVRAISON packed(8:0);  // Numéro de livraison de la ligne
// ECRANLIGNEDESIGNATIONCLIENT char(30);   // Désignation du client de la ligne
// ECRANLIGNENUMEROFACTURE packed(8:0);    // Numéro de facture de la ligne
// ECRANLIGNECODETOURNEE packed(2:0);      // Code tournée de la ligne
// ECRANLIGNECODECLIENT packed(9:0);       // Code client de la ligne
// ECRANLIGNEDATELIVRAISON date;           // Date de livraison de la ligne

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
Dcl-S CommandeCL VarChar(200);

Dcl-S NombreTotalLignesSF Packed(4:0);
Dcl-s Fin ind;
dcl-ds Societe qualified;
  Code Char(2);
  Libelle Char(26);
  BilbiothequeFichier Char(9);
end-ds;

// --- Constantes -------------------------------------------------------
Dcl-C CREATION 'CREATION';
Dcl-C MODIFICATION 'MODIFICATION';
Dcl-C VISUALISATION 'VISUALISATION';


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
// - Récupération Bibliothèque des fichiers & code société
// - Création du userIndex si il n'existe pas
// - TODO: Purge du fichier des blocages antérieurs à J-1
// - Initialisation de l'écran
///
Dcl-Proc InitialisationProgramme;

    //Récupération du code société et de la bibliothèque des fichiers
    Societe.Code = GetCodeSociete();
    Societe.Libelle = GetLibelleSociete(Societe.Code);
    Societe.BilbiothequeFichier = GetBibliothequeFichierSociete(Societe.Code);

     If (Societe.Libelle = *BLANKS);
            EcranLibelleSociete = *ALL'?';
            Else;
            EcranLibelleSociete = Societe.Libelle;
        EndIf;

    // Récupération du libellé de l'action
    EcranLibelleAction = £LibelleAction;

    // Création du UserIndex s'il n'existe pas
    CreationUserIndex(psds.Proc:BibliothequeFichier);

End-Proc;



// ----------------------------------------------------------------------------
//
//                                 SERVICES
//                  Réutilisable dans d'autres programmes
//
// -----------------------------------------------------------------------------

///
// GET libellé société
// La procédure renvoie le libellé de la société en fonction de son code
// TABVV : STE
//
// @param Code de la société
// @return Libellé de la société si erreur renvoi *ALL'?'
///

Dcl-Proc GetLibelleSociete ;
    Dcl-Pi *n Char(20);
        CodeSociete Char(2);
    End-Pi;

    Dcl-S LibelleSocieteReturn Char(20);
    Dcl-C TABLE_CHARTREUSE_SOCIETE 'STE';


    Exec SQL
            Select SUBSTR(XLIPAR, 1, 26)
                Into :LibelleSocieteReturn
                FROM VPARAM
                WHERE XCORAC = :TABLE_CHARTREUSE_SOCIETE
                    AND XCOARG = :CodeSociete;
    If SQLCode <> 0;
        GestionErreurSQL();
        LibelleSocieteReturn = *ALL'?';
    EndIf;

    Return LibelleSocieteReturn;

End-Proc;

///
// GET Code société
// La procédure renvoie le Code de la société
// TABVV : STE
//
// @return Code de la société si erreur renvoi *ALL'?'
///

Dcl-Proc GetCodeSociete ;
    Dcl-Pi *n Char(2);
    End-Pi;

    Dcl-S CodeSocieteReturn Char(2);
    Dcl-C TABLE_CHARTREUSE_SOCIETE 'STE';

    Exec SQL
            Select XCOARG
                Into :CodeSocieteReturn
                FROM VPARAM
                WHERE XCORAC = :TABLE_CHARTREUSE_SOCIETE;
    If SQLCode <> 0;
        GestionErreurSQL();
        CodeSocieteReturn = *ALL'?';
    EndIf;

    Return CodeSocieteReturn;

End-Proc;

///
// GET Bibliotheque Fichier société
// La procédure renvoie la bibliotheque des fichiers utilisé dans la société (FIDVALSXX)
// en fonction du code Société
//
// TABVV : STE
// @param Code de la société
// @return Bilbiotheque de fichier de la société si erreur renvoi *ALL'?'
///

Dcl-Proc GetBibliothequeFichierSociete ;
    Dcl-Pi *n Char(10);
        CodeSociete Char(2);
    End-Pi;

    Dcl-S BibliothequeFichierReturn Char(10);
    Dcl-C TABLE_CHARTREUSE_SOCIETE 'STE';

    Exec SQL
            Select SUBSTR(XLIPAR, 40, 10)
                Into :BibliothequeFichierReturn
                FROM VPARAM
                WHERE XCORAC = :TABLE_CHARTREUSE_SOCIETE;
    If SQLCode <> 0;
        GestionErreurSQL();
        BibliothequeFichierReturn = *ALL'?';
    EndIf;

    Return BibliothequeFichierReturn;

End-Proc;


///
// Gestion des erreurs SQL
// Affiche à l'écran s'il y a une erreur SQL
///

Dcl-Proc GestionErreurSQL ;

    Dcl-S MessageId         Char(10) ;
    Dcl-S MessageText       Char(52) ;
    Dcl-S RowsCount         Int(10) ;
    Dcl-S ReturnedSQLCode   Char(5) ;
    Dcl-S ReturnedSQLState  Char(5) ;


    If (SqlCode <> 0 And SqlCode <> 100) ;

        exec sql GET DIAGNOSTICS
                :RowsCount = ROW_COUNT;

        exec sql GET DIAGNOSTICS CONDITION 1
                :ReturnedSQLCode = DB2_RETURNED_SQLCODE,
                :ReturnedSQLState = RETURNED_SQLSTATE,
                :MessageText = MESSAGE_TEXT,
                :MessageId = DB2_MESSAGE_ID ;

        DSPLY ('Error ID : ' + MessageId);
        DSPLY ('Error Message text : ');
        DSPLY MessageText;
        DSPLY ('SQLCode : ' + ReturnedSQLCode);
        DSPLY ('SQLState : ' + ReturnedSQLState);
        DSPLY ('Nb lignes affectées par le dernier SQL : ' + %Char(RowsCount));

    EndIf ;
End-Proc;
