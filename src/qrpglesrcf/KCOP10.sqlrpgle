**free
Ctl-opt Option(*srcstmt:*nodebugio ) AlwNull(*usrctl) UsrPrf(*owner)
        DatFmt(*eur) DatEdit(*dmy) TimFmt(*hms) dftactgrp(*no);

// Appel ligne de commande :
// CALL PGM(KCOP10) PARM((GER  (*CHAR 4)) (LIVCON (*CHAR 6))
//  ('Gestion livraison consignes' (*CHAR 30)))

///
// --------------------------------------------------------------
//       NOM        : KCOP10              TYPE : Interactif
//
//  TITRE      : Suivi des articles consignés.: Gestion livraisons des consignes
//
//  FONCTIONS  :
//              Gestion des livraisons et retours des consignes chez les clients.
//              Appel du programme KCOP20 pour saisie de la livraison/retour des consignes
//              Le sous-fichier est chargé en fonction de la table KCOENT pour les entêtes des liv-
//              raisons
//
//              Touches de fonction :
//                      F2 : Utilisateur
//                      F3 : Fin
//                      F6 : Services
//                      F9 : Nouvelle livraison
//
//              Filtres disponibles (type "Commence par" et additionnel) :
//                      - Numéro de livraison
//                      - Numéro de facture
//                      - Tournée
//                      - Code client
//                      - Désignation client (Filtre type "Contient")
//                      - Date de livraison confirmée
//              Option "Masquer les retours traités" (activée par défaut)
//              pour n'afficher que les livraisons sans retour
//
//              Actions possibles sur les livraisons :
//                      1 : Modifier une livraison
//                      2 : Visualiser une livraison
//                      3 : Créer un nouveau retour
//                      4 : Modifier un retour
//                      5 : Visualiser un retour
//
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
//  ECRIT DU   : 11/11/2024            PAR : ANg (Antilles Glaces)
//        AU   : 19/11/2024
//
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
// ECRANLIVRAISSANSRETOURFILTRE char(1);   // Filtre pour masquer les livraisons sans retour

// Variables du format GESTIONSFL
// ECRANLIGNEACTION char(1);                // Option utilisateur sur la ligne
// ECRANLIGNENUMEROLIVRAISON packed(8:0);  // Numéro de livraison de la ligne
// ECRANLIGNEDESIGNATIONCLIENT char(30);   // Désignation du client de la ligne
// ECRANLIGNENUMEROFACTURE packed(8:0);    // Numéro de facture de la ligne
// ECRANLIGNECODETOURNEE packed(2:0);      // Code tournée de la ligne
// ECRANLIGNECODECLIENT packed(9:0);       // Code client de la ligne
// ECRANLIGNEDATELIVRAISON date;           // Date de livraison de la ligne

// --- Appels de prototypes et de leurs DS-------------------------------
// Prototype des programmes appelés
// Dcl-Pr KCOP20 ExtPgm;
//     NumeroLivraison Packed(7:0) const;
//     Mode Char(13) const;//Livraison ou retour
//     Droits Char(13) const;//Visualiser, modifier, créer,...
//     CodeSociete Char(2) const;
//     ReturnOperationEffectuee char(1);
// End-Pr ;

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
Dcl-S NombreTotalLignesSF Packed(4:0);
Dcl-S Fin ind;
Dcl-S Refresh ind;
Dcl-Ds Societe qualified;
    Code Char(2);
    Libelle Char(26);
    BilbiothequeFichier Char(9);
End-Ds;

Dcl-Ds ParametresConsignes qualified;
    XLIPAR Char(100);
    TypeArticle Char(1) Overlay(XLIPAR);
    CodeMouvement Char(2) Overlay(XLIPAR:*NEXT);
    TopPrealimentationRetour Char(1) Overlay(XLIPAR:*NEXT);
    NombreExemplairesBL Packed(2:0) Overlay(XLIPAR:*NEXT);
End-Ds;


// --- Constantes -------------------------------------------------------
Dcl-C CREATION 'CREATION';
Dcl-C MODIFICATION 'MODIFICATION';
Dcl-C VISUALISATION 'VISUALISATION';
Dcl-C TABVV_PARAMETRESCONSIGNES 'XCOPAR';

// --- Tables -------------------------------------------------------
Dcl-Ds KCOENT_t extname('KCOENT') qualified template;
End-Ds;

// --- Data-structures Indicateurs--------------------------------------
Dcl-Ds Indicateur qualified;

    SousFichierDisplay                              Ind Pos(51);
    SousFichierDisplayControl                       Ind Pos(52);
    SousFichierClear                                Ind Pos(53);
    SousFichierEnd                                  Ind Pos(54);

    // Indicateurs d'affichage
    MasquerMessageErreur                        Ind Pos(82);
    MasquerMessageInfo                          Ind Pos(83);

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


// Chargement initial du sous-fichier
ChargerSousFichier();

Fin = *Off;
DoW not Fin;
    AffichageEcran();

    // Traitement des actions
    Action();

    // Si rafraîchissement nécessaire, rechargement du sous-fichier
    If Refresh;
        ChargerSousFichier();
        Refresh = *Off;
    EndIf;
    
EndDo;

*Inlr=*On;


// ----------------------------------------------------------------------------
//
//                                  PROCEDURES
//
// ----------------------------------------------------------------------------

///
// InitialisationProgramme()
// ------------------------
// Objectif : Initialise les variables et paramètres nécessaires au programSme
//
// Traitements : 
// 1. Initialisation des variables globales
//    - Indicateurs de fin de programme et de rafraîchissement
//    - Message d'erreur
//
// 2. Récupération paramètres société
//    - Code société (TABVV STE)
//    - Libellé société 
//    - Bibliothèque des fichiers
//
// 3. Chargement paramètres consignes
//    - Lecture table XCOPAR pour paramètres consignes
//
// 4. Nettoyage des données temporaires
//    - Purge du fichier des blocages (KUTF30) pour les enregistrements antérieurs à J-1
//
// 5. Initialisation de l'écran
//    - Masquage des messages d'erreur et d'information
//    - RAZ et préparation du sous-fichier (clear + display)
//    - Définition des libellés (action, verbe/objet, société)
//    - Initialisation des filtres à vide
//    - Positionnement initial du curseur
//
// Paramètres : 
//   Entrée : Aucun
//   Sortie : Aucun
//
// Particularités :
// - Le filtre 'Masquer les retours traités' est activé par défaut ('X')
// - Message d'avertissement ('?') si le libellé société n'est pas trouvé
///
Dcl-Proc InitialisationProgramme;
    Dcl-Pi *N;
    End-Pi;
    
    //--- 1. Initialisation des variables globales ----------------------------
    // Indicateurs de contrôle
    Fin = *Off;                               // Indicateur de fin
    Refresh = *Off;                           // Indicateur rafraîchissement
    
    //--- 2. Récupération paramètres société --------------------------------
    // Récupération des informations société
    Societe.Code = GetCodeSociete();
    Societe.Libelle = GetLibelleSociete();
    Societe.BilbiothequeFichier = GetBibliothequeFichierSociete();
    
    //--- 3. Chargement paramètres consignes --------------------------------
    // Lecture des paramètres dans XCOPAR
    Exec SQL
        Select XLIPAR
        Into :ParametresConsignes.XLIPAR
        FROM VPARAM
        Where XCORAC = :TABVV_PARAMETRESCONSIGNES 
        and XCOARG = :Societe.Code;
    GestionErreurSQL();
    
    //--- 4. Nettoyage des données temporaires ------------------------------
    // Purge des blocages antérieurs à J-1
    Exec SQL
        DELETE FROM KUTF30 
        WHERE StartTimestamp < CURRENT_DATE - 1 DAY;
    GestionErreurSQL();
    
    //--- 5. Initialisation de l'écran ------------------------------------
    // Masquage des messages
    Indicateur.MasquerMessageErreur = *On;
    Indicateur.MasquerMessageInfo = *On;

    // Préparation du sous-fichier
    Indicateur.SousFichierClear = *On;
    Write GESTIONCTL;
    Indicateur.SousFichierClear = *Off;
    
    Indicateur.SousFichierDisplay = *On;
    Indicateur.SousFichierEnd = *On;
    Indicateur.SousFichierDisplayControl = *On;
    
    // Définition des libellés
    If Societe.Libelle = *Blanks;
        EcranLibelleSociete = *ALL'?';
    Else;
        EcranLibelleSociete = Societe.Libelle;
    EndIf;
    EcranLibelleAction = £LibelleAction;
    EcranVerbeObjet = £CodeVerbe + £CodeObjet;
    ECRANMESSAGEERREUR = *Blanks;             // Message d'erreur
    ECRANMESSAGEINFO = *Blanks;               // Message d'information
    
    // Initialisation des filtres
    ECRANLIVRAISSANSRETOURFILTRE = 'X';      // Filtre retours traités (activé par défaut)
    ECRANNUMEROLIVRAISONFILTRE = 0;         // Filtre numéro livraison
    ECRANNUMEROFACTUREFILTRE = 0;            // Filtre numéro facture  
    ECRANNUMEROTOURNEEFILTRE = *Blanks;      // Filtre tournée
    ECRANCODECLIENTFILTRE = *BLANKS;          // Filtre code client
    ECRANDESIGNATIONCLIENTFILTRE = *Blanks;  // Filtre désignation client
    ECRANDATELIVRAISONFILTRE = *LOVAL;      // Filtre date livraison

End-Proc;

///
// ChargerSousFichier()
// Charge le sous-fichier avec les données de KCOENT
// Recherche num VENTLV
// Initialise les positions d'affichage et le curseur
///
Dcl-Proc ChargerSousFichier;
    Dcl-Pi *n ;
    End-Pi;
  
    // Nettoyage initial du sous-fichier
    Indicateur.SousFichierClear = *On;
    Write GESTIONCTL;
    Indicateur.SousFichierClear = *Off;

    // Initialisation du rang
    fichierDS.rang_sfl = 0;

    // Préparation de la requête
    Exec SQL 
        DECLARE C1 CURSOR FOR
        SELECT DISTINCT 
            K.NUMEROLIVRAISON, 
            V.ENUFAC,
            V.ECOTRA,
            V.ECOCLL,
            C.CLISOC as DESIGNATION_CLIENT,
            DATE(TIMESTAMP_ISO(
                DIGITS(V.EXXDLV) CONCAT 
                DIGITS(V.EAADLV) CONCAT '-' CONCAT 
                DIGITS(V.EMMDLV) CONCAT '-' CONCAT 
                DIGITS(V.EJJDLV)
            )) as DATE_LIVRAISON
        FROM FIDVALSAC.KCOENT K
        LEFT JOIN FIDVALSAC.VENTLV V ON V.ENULIV = K.NUMEROLIVRAISON
        LEFT JOIN FIDVALSAC.CLIENT C ON C.CCOCLI = V.ECOCLL
        WHERE 1=1
            AND (:ECRANNUMEROLIVRAISONFILTRE = 0 OR K.NUMEROLIVRAISON = :ECRANNUMEROLIVRAISONFILTRE)
            AND (:ECRANNUMEROFACTUREFILTRE = 0 OR V.ENUFAC = :ECRANNUMEROFACTUREFILTRE)
            AND (:ECRANNUMEROTOURNEEFILTRE = '' OR V.ECOTRA = :ECRANNUMEROTOURNEEFILTRE) 
            AND (:ECRANCODECLIENTFILTRE = '' OR V.ECOCLL = :ECRANCODECLIENTFILTRE)
            AND (:ECRANDESIGNATIONCLIENTFILTRE = '' OR UPPER(C.CLISOC) LIKE UPPER('%' CONCAT :ECRANDESIGNATIONCLIENTFILTRE CONCAT '%'))
            AND (:ECRANDATELIVRAISONFILTRE = DATE('0001-01-01') 
                OR DATE(TIMESTAMP_ISO(
                    DIGITS(V.EXXDLV) CONCAT 
                    DIGITS(V.EAADLV) CONCAT '-' CONCAT 
                    DIGITS(V.EMMDLV) CONCAT '-' CONCAT 
                    DIGITS(V.EJJDLV)
                )) = :ECRANDATELIVRAISONFILTRE)
        ORDER BY K.NUMEROLIVRAISON DESC;
    GestionErreurSQL();

    // Ouverture du curseur
    Exec SQL OPEN C1;
    GestionErreurSQL();

    // Premier FETCH pour initialiser SQLCODE
    Exec SQL 
        FETCH NEXT FROM C1 
        INTO :ECRANLIGNENUMEROLIVRAISON,
             :ECRANLIGNENUMEROFACTURE,
             :ECRANLIGNECODETOURNEE,
             :ECRANLIGNECODECLIENT,
             :ECRANLIGNEDESIGNATIONCLIENT,
             :ECRANLIGNEDATELIVRAISON;
    GestionErreurSQL();

    // Lecture des données tant que SQLCODE = 0
    DoW SQLCODE = 0;
        // Incrémentation du rang
        fichierDS.rang_sfl += 1;

        // Initialisation des autres champs
        ECRANLIGNEACTION = ' ';

        // Écriture de la ligne dans le sous-fichier
        Write GESTIONSFL;

        // Lecture suivante
        Exec SQL 
            FETCH NEXT FROM C1 
            INTO :ECRANLIGNENUMEROLIVRAISON,
                 :ECRANLIGNENUMEROFACTURE,
                 :ECRANLIGNECODETOURNEE,
                 :ECRANLIGNECODECLIENT,
                 :ECRANLIGNEDESIGNATIONCLIENT,
                 :ECRANLIGNEDATELIVRAISON;
        GestionErreurSQL();
    EndDo;

    // Fermeture du curseur
    Exec SQL CLOSE C1;
    GestionErreurSQL();

    // Mémorisation du nombre total de lignes
    NombreTotalLignesSF = fichierDS.rang_sfl;
    
    // Positionnement initial
    EcranLigneSousFichier = 1;
    EcranDeplacerCurseurLigne = 8;
    EcranDeplacerCurseurColonne = 3;

End-Proc;



///
// AffichageEcran
// Gère l'affichage de l'écran et du sous-fichier
///
Dcl-Proc AffichageEcran;
    // Pour afficher un sous-fichier vide, 
    //on ne doit PAS activer l'affichage du sous-fichier s'il est vide 
    If NombreTotalLignesSF > 0;
        Indicateur.SousFichierDisplay = *On;
    Else;
        Indicateur.SousFichierDisplay = *Off;
    EndIf;
    
    Indicateur.SousFichierDisplayControl = *On;
    Indicateur.SousFichierEnd = *On;

    // Affichage de l'écran avec attente de saisie
    Write GestionBas;
    ExFmt GESTIONCTL;
End-Proc;


///
// Action
// affichage écran
///
Dcl-Proc Action;
    Select;
        When fichierDS.TouchePresse = F2;
            AffichageFenetreUtilisateur(£CodeVerbe:£CodeObjet);

        When fichierDS.TouchePresse = F3;
            Fin=*On;

        When fichierDS.TouchePresse = F6;
            AffichageFenetreServices();

        When fichierDS.touchePresse = F9;
            dsply 'nouvelle livraison';

        When fichierDS.TouchePresse = F12;
            Fin=*On;

        When  fichierDS.touchePresse = ENTREE;
            dsply 'entrée';
            Refresh = *On;
        Other;
    EndSl;
  
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
// @return Libellé de la société si erreur renvoi *ALL'?'
///

Dcl-Proc GetLibelleSociete ;
    Dcl-Pi *n Char(20);

    End-Pi;

    Dcl-S LibelleSocieteReturn Char(20);
    Dcl-C TABLE_CHARTREUSE_SOCIETE 'STE';


    Exec SQL
            Select SUBSTR(XLIPAR, 1, 26)
                Into :LibelleSocieteReturn
                FROM VPARAM
                WHERE XCORAC = :TABLE_CHARTREUSE_SOCIETE;
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
//
// La procédure renvoie la bibliotheque des fichiers utilisé dans la société (FIDVALSXX)
// en fonction du code Société
//
// TABVV : STE
// @return Bilbiotheque de fichier de la société si erreur renvoi *ALL'?'
///
Dcl-Proc GetBibliothequeFichierSociete ;
    Dcl-Pi *n Char(10);
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


//                               Fenetre services & utilisateurs

///
// Appel de la fenêtre utilisateur
// - Appel de la fenêtre utilisateur (par 'F2')
///

Dcl-Proc AffichageFenetreUtilisateur ;
    Dcl-Pi *n;
        CodeVerbe Char(3);
        CodeObjet Char(5);
    End-Pi;

    PR_GOAFENCL(CodeVerbe
         :CodeObjet);
End-Proc;


///
// Appel du menu de services
// - Appel du menu de services (par 'F6')
///

Dcl-Proc AffichageFenetreServices ;
    PR_GOASER();
End-Proc;

///
// InitialiseSousFichier
// initialise les valeurs du sous-fichier
// selon les filtres appliqués par l'utilisateur
//  - Si des enregistrements existent, on initialise les valeurs du sous fichier
// du second écran et on revoie true
//  - Sinon, on fait rien et on renvoie false
//
// @Return : EnregistrementsTrouves Ind
///

// Dcl-Proc InitialiseSousFichier;
//     Dcl-Pi *n Ind;
//     End-Pi;

//     Dcl-S Requete char(2048);
//     Dcl-S EnregistrementsTrouves Ind Inz(*Off);

//     Dcl-S ClauseSelect char(2048);
//     Dcl-S ClauseFROM char(2048);
//     Dcl-S ClauseWhere char(2048);
//     Dcl-S ClauseOrderBy char(2048);

//     Dcl-Ds KCOENT likeDs(KCOENT_t);
//     Dcl-Ds DateLivraison qualified;
//         jour char(2);
//         mois char(2);
//         annee char(2);
//         siecle char(2);
//     End-Ds;

//     Dcl-C ESPACE ' ';

//     ClauseSelect = 'SELECT DISTINCT NUMEROLIVRAISON, NUMEROFACTURE, NUMEROEDITION, '
//     + 'LIVRAISONTIMESTAMP, LIVRAISONUTILISATEUR, TOPRETOUR, RETOURTIMESTAMP, RETOURUTILISATEUR';
//     ClauseFROM = 'FROM KCOENT';
//     //ClauseWhere = CreationClauseWhere();
//     ClauseOrderBy = 'ORDER BY NUMEROLIVRAISON Desc ';

//     Requete =
//         %trimr(ClauseSelect) + ESPACE
//         + %Trimr(ClauseFROM) + ESPACE
//         //+ %Trimr(ClauseWhere) + ESPACE
//         + %Trimr(ClauseOrderBy);

//   // Préparation du curseur pour récupérer les résultats de la requête
//     exec sql PREPARE S1 FROM :Requete;
//     GestionErreurSQL();

//   // Déclaration du curseur
//     exec sql DECLARE C1 CURSOR FOR S1;
//     GestionErreurSQL();

//   // Ouverture du curseur
//     exec sql OPEN C1;
//     GestionErreurSQL();

//   // Fetch
//     exec sql FETCH FROM C1 INTO
//             :KCOENT.NUMLIV,
//             :KCOENT.NUMFAC,
//             :KCOENT.NUMEDI,
//             :KCOENT.LIVDAT,
//             :KCOENT.LIVUSR,
//             :KCOENT.TOPRET,
//             :KCOENT.RETDAT,
//             :KCOENT.RETUSR;
//     If SQLCode = 100; //Aucun enregistrement n'a été trouvé
    
//     ElseIf SQLCode = 0;// Des enregistrements ont été trouvés

//         EnregistrementsTrouves = *On;

//     // Remise à blanc du sous-fichier
//         Indicateur.SousFichierClear = *On;
//         Write GESTIONCTL;
//         Indicateur.SousFichierClear = *off;

//     // Chargement du sous-fichier
//         fichierDS.rang_sfl = 0;

//         DoW SQLCode = 0;

//             fichierDS.rang_sfl = fichierDS.rang_sfl + 1;

//             ECRANLIGNENUMEROLIVRAISON = KCOENT.NUMLIV;
//             ECRANLIGNENUMEROFACTURE = KCOENT.NUMFAC;

//             //Recherche code tournée, client livré, 
//             exec SQL
//             select ECOTRA, ECOCLL, ejjlvc, emmlvc, eaalvc, exxlvc
//             Into :EcranLigneCodeTournee, :EcranLigneCodeClient, :DateLivraison.jour,
//             :DateLivraison.mois, :DateLivraison.annee, :DateLivraison.siecle
//             From VENTLV
//             Where enuliv = :KCOENT.NUMLIV;
            
//             ENCRALIGNEDESIGNATIONCLIENT = *BLANKS;
//             ECRANLIGNEDATELIVRAISON = *BLANKS;

//             Write GESTIONSFL;

//       // Fetch
//             exec sql 
//             FETCH FROM C1 INTO
//             :KCOENT.NUMLIV,
//             :KCOENT.NUMFAC,
//             :KCOENT.NUMEDI,
//             :KCOENT.LIVDAT,
//             :KCOENT.LIVUSR,
//             :KCOENT.TOPRET,
//             :KCOENT.RETDAT,
//             :KCOENT.RETUSR;
//             GestionErreurSQL();

//         EndDo;
//     // Affectation du nombre total de ligne
//         NombreTotalLignesSF = fichierDS.rang_sfl;

//     Else;//Erreur requete
//         GestionErreurSQL();
//     EndIf;


//   // Fermeture du curseur
//     exec sql CLOSE C1;
//     GestionErreurSQL();

//     Return EnregistrementsTrouves;
// End-Proc ;