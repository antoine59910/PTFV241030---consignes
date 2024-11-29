**free
Ctl-opt Option(*srcstmt:*nodebugio ) AlwNull(*usrctl) UsrPrf(*owner)
        DatFmt(*eur) DatEdit(*dmy) TimFmt(*hms) dftactgrp(*no);

// Appel ligne de commande :
// CALL PGM(KCOP10) PARM((GER  (*CHAR 4)) (LIVCON (*CHAR 6))
//  ('Gestion livraison consignes' (*CHAR 30)))

// TODO: 
// - Gestion multi-users
// - Appel PGM KCOP11

// FIXME: 
//

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
//              Filtres disponibles :
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
// ECRANNUMEROLIVRAISONFILTRE char(8); // Filtre sur le numéro de livraison
// ECRANNUMEROFACTUREFILTRE char(8);   // Filtre sur le numéro de facture
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
///
// KCOP11 : Gestion des livraisons et retours des consignes : saisies
//
// @param £Operation - Type d'opération (LIVRAISON ou RETOUR)
// @param £Mode - Mode de fonctionnement (CREATION/MODIFICATION/VISUALISATION) 
// @param £NumeroLivraison - Numéro de la livraison à traiter
///
Dcl-PR KCOP11 ExtPgm('KCOP11');
    £Operation          Char(30) Const;    // Type d'opération
    £Mode              Char(30) Const;     // Mode de fonctionnement
    £NumeroLivraison   Packed(8:0) Const; // Numéro de livraison
End-PR;
Dcl-ds KCOP11_p qualified;
    Operation          Char(30);    // Type d'opération
    Mode              Char(30);     // Mode de fonctionnement
    NumeroLivraison   Packed(8:0); // Numéro de livraison
End-Ds;
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
Dcl-s Compteur Packed(10:0);


// --- Constantes -------------------------------------------------------
Dcl-C LIVRAISON 'LIVRAISON';
Dcl-C RETOUR 'RETOUR';
Dcl-C CREATION 'CREATION';
Dcl-C MODIFICATION 'MODIFICATION';
Dcl-C VISUALISATION 'VISUALISATION';
Dcl-C QUOTE '''';
Dcl-C ESPACE ' ';
Dcl-C POURCENTAGE '%';
Dcl-C CODE_ACTION_MODIFIER_LIVRAISON '1';
Dcl-C CODE_ACTION_VISUALISER_LIVRAISON '2';
Dcl-C CODE_ACTION_CREER_RETOUR '3';
Dcl-C CODE_ACTION_MODIFIER_RETOUR '4';
Dcl-C CODE_ACTION_VISUALISER_RETOUR '5';

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
// Paramètres
Dcl-Pi *N;
    // entrées
    £CodeVerbe                                   Char(4);
    £CodeObjet                                   Char(6);
    £LibelleAction                               Char(30);

    // sorties
End-Pi ;
// ---------------------------------------------------------------------

// Initialisation SQL :
Exec Sql
     Set Option Commit = *None;

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
    ECRANNUMEROLIVRAISONFILTRE = *BLANKS;         // Filtre numéro livraison
    ECRANNUMEROFACTUREFILTRE = *BLANKS;            // Filtre numéro facture  
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
  
    Dcl-S Requete char(2048);

    Dcl-S ClauseSelect char(2048);
    Dcl-S ClauseFROM char(2048);
    Dcl-S ClauseWhere char(2048);
    Dcl-S ClauseOrderBy char(2048);

    // Nettoyage initial du sous-fichier
    Indicateur.SousFichierClear = *On;
    Write GESTIONCTL;
    Indicateur.SousFichierClear = *Off;

    // Initialisation du rang
    fichierDS.rang_sfl = 0;

    ClauseSelect = 'SELECT DISTINCT K.NUMEROLIVRAISON, ' +
                  'V.ENUFAC, V.ECOTRA, V.ECOCLL, C.CLISOC, ' +
                  'CASE ' +
                    'WHEN V.EJJDLV > 0 AND V.EMMDLV > 0 AND V.EAADLV > 0 ' +
                    'THEN DATE(' +
                        'CAST(' +
                            'CASE ' +
                                'WHEN V.EXXDLV = 0 THEN ''20'' ' +
                                'ELSE DIGITS(V.EXXDLV) ' +
                            'END ' +
                            'CONCAT RIGHT(''00'' CONCAT DIGITS(V.EAADLV), 2) ' +
                            'CONCAT ''-'' ' +
                            'CONCAT RIGHT(''00'' CONCAT DIGITS(V.EMMDLV), 2) ' +
                            'CONCAT ''-'' ' +
                            'CONCAT RIGHT(''00'' CONCAT DIGITS(V.EJJDLV), 2) ' +
                            'AS VARCHAR(10)' +
                        ')' +
                    ') ' +
                    'ELSE NULL ' +
                  'END as DATE_LIVRAISON';
                  
    ClauseFROM = 'FROM KCOENT K ' +
                 'LEFT JOIN VENTLV V ON V.ENULIV = K.NUMEROLIVRAISON ' +
                 'LEFT JOIN CLIENT C ON C.CCOCLI = V.ECOCLL';

    ClauseWhere = CreationClauseWhere();
    
    ClauseOrderBy = 'ORDER BY K.NUMEROLIVRAISON DESC';

    Requete = %trimr(ClauseSelect) + ESPACE +
              %Trimr(ClauseFROM) + ESPACE +
              %Trimr(ClauseWhere) + ESPACE +
              %Trimr(ClauseOrderBy);

    // Préparation du curseur pour récupérer les résultats de la requête
    exec sql PREPARE S1 FROM :Requete;
    GestionErreurSQL();

    // Déclaration du curseur
    exec sql DECLARE C1 CURSOR FOR S1;
    GestionErreurSQL();

    // Ouverture du curseur
    exec sql OPEN C1;
    GestionErreurSQL();

    // Premier FETCH
    exec sql FETCH FROM C1 INTO 
            :ECRANLIGNENUMEROLIVRAISON,
            :ECRANLIGNENUMEROFACTURE,
            :ECRANLIGNECODETOURNEE,
            :ECRANLIGNECODECLIENT,
            :ECRANLIGNEDESIGNATIONCLIENT,
            :ECRANLIGNEDATELIVRAISON;
    GestionErreurSQL();

    If SQLCode = 100; //Aucun enregistrement n'a été trouvé
        ECRANMESSAGEERREUR = 'Aucune livraison trouvée';
        Indicateur.MasquerMessageErreur = *Off;
        
    ElseIf SQLCode = 0;// Des enregistrements ont été trouvés
        DoW SQLCode = 0;
            // Incrémentation du rang
            fichierDS.rang_sfl += 1;

            // Initialisation ligne action
            ECRANLIGNEACTION = ' ';

            // Écriture dans le sous-fichier  
            Write GESTIONSFL;

            // Lecture suivante
            exec sql FETCH FROM C1 INTO 
                    :ECRANLIGNENUMEROLIVRAISON,
                    :ECRANLIGNENUMEROFACTURE,
                    :ECRANLIGNECODETOURNEE,
                    :ECRANLIGNECODECLIENT,
                    :ECRANLIGNEDESIGNATIONCLIENT,
                    :ECRANLIGNEDATELIVRAISON;
            GestionErreurSQL();
        EndDo;

    Else;//Erreur requete
        GestionErreurSQL();
    EndIf;
    // Fermeture du curseur
    exec sql CLOSE C1;
    GestionErreurSQL();

    // Mémorisation du nombre total de lignes
    NombreTotalLignesSF = fichierDS.rang_sfl;
    
    // Positionnement initial
    EcranLigneSousFichier = 1;
    EcranDeplacerCurseurLigne = 8;
    EcranDeplacerCurseurColonne = 3;  
End-Proc;

///
// Création clause Where
// Permet de construire la clause where en fonction des filtres
// Filtres disponibles :
//  - Numéro de livraison (commence par)  
//  - Numéro de facture (commence par)
//  - Numéro de tournée (exact)
//  - Code client (exact)
//  - Désignation client (contient)
//  - Date de livraison (exact)
//  - Masquer les retours traités
//
// @Return : ClauseWhere char(2048)
///
Dcl-Proc CreationClauseWhere;
    Dcl-Pi *n Char(2048);
    End-Pi;

    Dcl-S ClauseWhere char(2048);

    // Construction clause where de base avec Filtre désignation client (contient)
    ClauseWhere = 'WHERE UPPER(C.CLISOC) LIKE ' + QUOTE +
                      POURCENTAGE + %Trim(ECRANDESIGNATIONCLIENTFILTRE) + 
                      POURCENTAGE + QUOTE;

    // Filtre numéro livraison (commence par)
    If ECRANNUMEROLIVRAISONFILTRE <> *BLANKS;
        ClauseWhere = %trimr(ClauseWhere) 
                      +  ' AND DIGITS(K.NUMEROLIVRAISON) LIKE ' + QUOTE
                      + %trim(ECRANNUMEROLIVRAISONFILTRE) + POURCENTAGE + QUOTE;
    EndIf;

    // Filtre numéro facture (commence par)
    If ECRANNUMEROFACTUREFILTRE <> *BLANKS;
        ClauseWhere = %trimr(ClauseWhere)
                     + ' AND DIGITS(V.ENUFAC) LIKE ' + QUOTE 
                     + %trim(ECRANNUMEROFACTUREFILTRE) + POURCENTAGE + QUOTE;
    EndIf;

    // Filtre tournée
    If ECRANNUMEROTOURNEEFILTRE <> *Blanks;
        ClauseWhere = %trimr(ClauseWhere)
                    + ' AND V.ECOTRA LIKE ' + QUOTE +
                      ECRANNUMEROTOURNEEFILTRE + QUOTE;
    EndIf;

    // Filtre code client
    If ECRANCODECLIENTFILTRE <> *Blanks;
        ClauseWhere = %trimr(ClauseWhere)
                        + ' AND V.ECOCLL LIKE ' + QUOTE + 
                        ECRANCODECLIENTFILTRE + QUOTE;
    EndIf;

    // Filtre date livraison
    If ECRANDATELIVRAISONFILTRE <> *Loval 
    AND ECRANDATELIVRAISONFILTRE <> %Date('1940-01-01');
        ClauseWhere = %trimr(ClauseWhere) 
                    + ' AND DATE(TIMESTAMP_ISO('
                    + 'DIGITS(V.EXXDLV) CONCAT '
                    + 'DIGITS(V.EAADLV) CONCAT ''-'' CONCAT '
                    + 'DIGITS(V.EMMDLV) CONCAT ''-'' CONCAT '
                    + 'DIGITS(V.EJJDLV)'
                    + ')) = ' + QUOTE + %Char(ECRANDATELIVRAISONFILTRE) + QUOTE;
    EndIf;

    // Filtre masquer retours traités
    If ECRANLIVRAISSANSRETOURFILTRE = 'X';
        ClauseWhere = %trimr(ClauseWhere)+ ' AND K.TOPRETOUR <> ''O''';
    EndIf;

    Return ClauseWhere;
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
// Gestion des différentes actions possibles de l'utilisateur
//
///
Dcl-Proc Action;
    Dcl-s FinCreation Ind Inz(*Off);
    Dcl-S VENTLV_LivraisonExiste Ind;
    Dcl-S KCOENT_LivraisonExiste Ind;
    Indicateur.MasquerMessageErreur = *On;  
    ECRANMESSAGEERREUR = *BLANKS;
    Indicateur.MasquerMessageInfo = *On;
    ECRANMESSAGEINFO = *BLANKS;

    Select;
        When fichierDS.TouchePresse = F2;
            AffichageFenetreUtilisateur(£CodeVerbe:£CodeObjet);

        When fichierDS.TouchePresse = F3;
            Fin=*On;

        When fichierDS.TouchePresse = F6;
            AffichageFenetreServices();

        When fichierDS.touchePresse = F9;
        //Réinitialisation numéro de livraison
            ECRANCREATIONLIVRAISON = 0;
            EXFMT ECREAT;
            dow not FinCreation;
                Select;
                When fichierDS.touchePresse = F12;
                    FinCreation = *On;
                When fichierDS.touchePresse = ENTREE;
                    //On vérifie que la livraison existe dans VENTLV
                    Exec SQL
                        select COUNT(ENULIV)
                        Into :Compteur
                        FROM VENTLV
                        Where ENULIV = :EcranCreationLivraison;
                        GestionErreurSQL();
                        If Compteur = 0;
                            VENTLV_LivraisonExiste = *Off;
                        ELse;
                            VENTLV_LivraisonExiste = *On;
                        EndIf;
                    
                    If VENTLV_LivraisonExiste = *On;
                    //On vérifie que la livraison n'existe pas déjà (qu'une livraison a déjà été saisie)
                    Exec SQL
                        select COUNT(NumeroLivraison)
                        Into :Compteur
                        FROM KCOENT
                        Where NumeroLivraison = :EcranCreationLivraison;
                        GestionErreurSQL();
                        If Compteur = 0;
                            KCOENT_LivraisonExiste = *Off;
                        ELse;
                            KCOENT_LivraisonExiste = *On;
                        EndIf;
                        
                        If KCOENT_LivraisonExiste = *Off;//Ouverture de la création de la livraison
                            KCOP11(LIVRAISON:CREATION:EcranCreationLivraison);
                        Else;//La livraison a déjà été crée
                            ECRANMESSAGEERREUR='LIV : ' 
                            + %EDITC(EcranCreationLivraison:'Z') 
                            + ' déjà créée';
                            Indicateur.MasquerMessageErreur = *Off;
                        EndIf;
                    Else;
                        ECRANMESSAGEERREUR='LIV : ' 
                        + %EDITC(EcranCreationLivraison:'Z') 
                        + ' inexistante';
                        Indicateur.MasquerMessageErreur = *Off;
                    EndIf;
                    FinCreation = *On;
                Other;
                EndSl;
            enddo;
            Refresh = *On;

        When fichierDS.TouchePresse = F12;
            Fin=*On;

        When  fichierDS.touchePresse = ENTREE;
            If Verification();
                If KCOP11_p.NumeroLivraison <> 0;
                KCOP11(KCOP11_p.Operation:KCOP11_p.Mode:KCOP11_p.NumeroLivraison);
                EndIf;
            EndIf;
            Refresh = *On;

            
        Other;
    EndSl;
  
End-Proc;

///
// Vérification des saisies et sauvegarde de l'action de l'utilisateur
// Vérifications :
//  - On vérifie qu'il n'y a pas plusieurs actions choisies en même temps
//
// @return *On si OK, *Off si KO
///

Dcl-Proc Verification;
    Dcl-Pi *n Ind;
    End-Pi;

    Dcl-S i Zoned(4:0);
    Dcl-S Rang Zoned(2:0);
    Dcl-S SauvegardeAction Char(1);
    Dcl-S VerificationReturn Ind Inz(*On);

    // Initialisations
    Indicateur.MasquerMessageErreur = *On;
    SauvegardeAction = *BLANKS;
    KCOP11_p.Operation = *BLANKS;
    KCOP11_p.Mode = *BLANKS;
    KCOP11_p.NumeroLivraison = 0;

    Rang = 1;
    For i = 1 to NombreTotalLignesSF;
        Chain i GESTIONSFL;

    // Vérifications
        If ECRANLIGNEACTION <> *BLANKS;
            // Vérification qu'il n'y ait pas plusieurs actions
            If VerificationReturn = *On And SauvegardeAction <> *BLANKS;
                EcranMessageErreur = 'Une seule action à la fois';
                Indicateur.MasquerMessageErreur = *Off;
                VerificationReturn = *Off;
            EndIf;


            //Sauvegarde de l'action
            select;
                when ECRANLIGNEACTION = CODE_ACTION_MODIFIER_LIVRAISON;
                    KCOP11_p.Operation = LIVRAISON;
                    KCOP11_p.Mode = MODIFICATION;
                    KCOP11_p.NumeroLivraison = ECRANLIGNENUMEROLIVRAISON;

                when ECRANLIGNEACTION = CODE_ACTION_VISUALISER_LIVRAISON;
                    KCOP11_p.Operation = LIVRAISON;
                    KCOP11_p.Mode = VISUALISATION;
                    KCOP11_p.NumeroLivraison = ECRANLIGNENUMEROLIVRAISON;

                when ECRANLIGNEACTION = CODE_ACTION_CREER_RETOUR;
                    KCOP11_p.Operation = RETOUR;
                    KCOP11_p.Mode = CREATION;
                    KCOP11_p.NumeroLivraison = ECRANLIGNENUMEROLIVRAISON;

                when ECRANLIGNEACTION = CODE_ACTION_MODIFIER_RETOUR;
                    KCOP11_p.Operation = RETOUR;
                    KCOP11_p.Mode = MODIFICATION;
                    KCOP11_p.NumeroLivraison = ECRANLIGNENUMEROLIVRAISON;

                when ECRANLIGNEACTION = CODE_ACTION_VISUALISER_RETOUR;
                    KCOP11_p.Operation = RETOUR;
                    KCOP11_p.Mode = VISUALISATION;
                    KCOP11_p.NumeroLivraison = ECRANLIGNENUMEROLIVRAISON;

                other;
            endsl;
            Rang = Rang + 1;
            SauvegardeAction = ECRANLIGNEACTION;
        EndIf;
    EndFor;


    Return VerificationReturn;

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