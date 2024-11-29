**free
Ctl-opt Option(*srcstmt:*nodebugio ) AlwNull(*usrctl) UsrPrf(*owner)
        DatFmt(*eur) DatEdit(*dmy) TimFmt(*hms) dftactgrp(*no);

// Appel ligne de commande :
// Création : 
// CALL PGM(KCOP11) PARM(('LIVRAISON' (*CHAR 30)) ('CREATION' (*CHAR 30)) 
// (75034677 (*DEC 8 0)))

///
// --------------------------------------------------------------
//       NOM        : KCOP10              TYPE : Interactif
//
//  TITRE      : Suivi des articles consignés.: Gestion livraisons des consignes : saisies
//
//  FONCTIONS  :
//              Saisie des livraisons et retours des consignes chez les clients.
//              Les articles chargés sont ceux ayant le type défini 
//              dans la TABVV des consignes (XCOPAR)
//              La validation de la saisie insère les valeurs dans les tables suivantes : 
//               - KCOENT : Table des entêtes des livraisons de consignes
//               - KCOLIG : Table des lignes des livraisons de consignes
//               - KCOCUM : Table des cumuls par clients (VCUMUL)
//
//              La validation d'une livraison édite un bon de mise à disposition
//
//              Livraison/retour
//              - Dans le cas d'une livraison : Les quantités retournées ne sont pas affichées 
//              - Dans le cas d'un retour : Les quantités retournées sont affichées
//                                          Les quantités livrées sont pré-remplies
//
//              Mode :
//              - En Création/Modification, les quantités peuvent être saisies
//              - En Visualisation, les quantités sont affichées mais protégées
//
//              Touches de fonction :
//                      F2 : Utilisateur
//                      F3 : Fin
//                      F6 : Services
//                      F12 : Abandon
//
//              Filtres disponibles :
//                      - Code article (commence par)
//                      - Libellé article
//
//  APPELE PAR : - KCOP10 
//
//
//  PARAMETRES :
// - D'appel :
//      - Opération : Livraison ou retour => £Operation
//      - Mode (création/modification/Visualisation) => £Mode
//      - Numéro de livraison => £NumeroLivraison
//
// - Retournés
//
//  ECRIT DU   : 27/11/2024            PAR : ANg (Antilles Glaces)
//        AU   : 27/11/2024
//
/// ---------------------------------------------------------------------
Dcl-F KCOP11E  WorkStn
               SFile(GESTIONSFL:fichierDS.rang_sfl)//SFILE(Format:rang)
               InfDS(fichierDS)//Permet d'avoir des informations sur le sous-fichier en cours
               IndDs(Indicateur)
               Alias;//pour mettre les indicateurs dans une DS et les nommer


// --- Tables -------------------------------------------------------
//Entête des livraisons/retour
Dcl-Ds KCOENT_t extname('KCOENT') qualified template;
End-Ds;
//Lignes des livraisons/retour
Dcl-Ds KCOLIG_t extname('KCOLIG') qualified template;
End-Ds;
//Consignes : Cumul des articles par clients
Dcl-Ds KCOCUM_t extname('KCOCUM') qualified template;
End-Ds;
//TABVV XCOPAR
Dcl-Ds ParametresConsigne qualified;
    XLIPAR Char(100);
    TypeArticle Char(1) Overlay(XLIPAR);
    CodeMouvement Char(2) Overlay(XLIPAR:*NEXT);
    TopPrealimentationRetour Char(1) Overlay(XLIPAR:*NEXT);
    NombreExemplairesBL Packed(2:0) Overlay(XLIPAR:*NEXT);
End-Ds;

// --- Appel de PGM  --------------------------------------------------
// Fenêtre utilisateur
/DEFINE PR_GOAFENCL
// Fenêtre service
/DEFINE PR_GOASER

/INCLUDE qincsrc,prototypes

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
Dcl-C TABVV_PARAMETRESCONSIGNE 'XCOPAR';
Dcl-C QUOTE '''';
Dcl-C ESPACE ' ';
Dcl-C POURCENTAGE '%';


// --- Data-structures Indicateurs--------------------------------------
Dcl-Ds Indicateur qualified;

    SousFichierDisplay                              Ind Pos(51);
    SousFichierDisplayControl                       Ind Pos(52);
    SousFichierClear                                Ind Pos(53);
    SousFichierEnd                                  Ind Pos(54);

    // Indicateurs d'affichage
    MasquerMessageErreur                        Ind Pos(82);
    MasquerMessageInfo                          Ind Pos(83);
    MasquerQuantiteRetournee                    Ind Pos(40);
    ProtegerQuantiteRetournee                   Ind Pos(41);
    ProtegerQuantiteLivree                      Ind Pos(42);

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
    £Operation                              Char(30);
    £Mode                                   Char(30);
    £NumeroLivraison                        Packed(8:0);

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
// Objectif : Initialise les variables et paramètres nécessaires au programme
//
// Traitements : 
// 1. Initialisation des variables globales
//    - Indicateurs de fin de programme et de rafraîchissement
//    - Messages d'erreur et d'information
//
// 2. Récupération des paramètres société/consignes
//    - Code et libellé société (TABVV STE)
//    - Bibliothèque de fichiers 
//    - Paramètres consignes (XCOPAR)
//
// 3. Initialisation écran
//    - Masquage messages 
//    - Préparation sous-fichier
//    - Initialisation en-têtes (client, livraison, facture, etc.)
//    - RAZ des filtres articles
///
Dcl-Proc InitialisationProgramme;
   //--- 1. Initialisation des variables globales ---
   Fin = *Off;                           
   Refresh = *Off;                      

   //--- 2. Récupération paramètres ---
   // Informations société
   Societe.Code = GetCodeSociete();
   Societe.Libelle = GetLibelleSociete();
   If Societe.Libelle = *Blanks;
       EcranLibelleSociete = *ALL'?';
   Else;
       EcranLibelleSociete = Societe.Libelle;
   EndIf;
   Societe.BilbiothequeFichier = GetBibliothequeFichierSociete();


   // Paramètres consignes
   Exec SQL
       Select XLIPAR
       Into :ParametresConsigne.XLIPAR
       FROM VPARAM
       Where XCORAC = :TABVV_PARAMETRESCONSIGNE 
       and XCOARG = :Societe.Code;
   GestionErreurSQL();
   

   //--- 3. Initialisation écran ---
   // Messages
   Indicateur.MasquerMessageErreur = *On;
   Indicateur.MasquerMessageInfo = *On;
   ECRANMESSAGEERREUR = *Blanks;
   ECRANMESSAGEINFO = *Blanks;

   // Sous-fichier
   Indicateur.SousFichierClear = *On;
   Write GESTIONCTL;
   Indicateur.SousFichierClear = *Off;
   Indicateur.SousFichierDisplay = *On;
   Indicateur.SousFichierEnd = *On;
   Indicateur.SousFichierDisplayControl = *On;

   // En-têtes
   //Dans le cas d'une création de livraison : 
   If (£Mode = CREATION);
    EcranNumeroEdition = 0;

    Exec SQL
    SELECT DISTINCT 
        V.ENULIV as numeroLivraison,
        V.ENUFAC as numeroFacture, 
        V.ECOTRA as codeTournee, 
        V.ECOCLL as codeClient,
        C.CLISOC as nomCommercial,
        C.CLIDES as raisonSociale,
        CASE 
            WHEN V.EJJDLV > 0 AND V.EMMDLV > 0 AND V.EAADLV > 0 
            THEN DATE(
                CAST(
                    CASE 
                        WHEN V.EXXDLV = 0 THEN '20'
                        ELSE DIGITS(V.EXXDLV)
                    END 
                    || RIGHT('00' || DIGITS(V.EAADLV), 2)
                    || '-'
                    || RIGHT('00' || DIGITS(V.EMMDLV), 2)
                    || '-' 
                    || RIGHT('00' || DIGITS(V.EJJDLV), 2)
                    AS VARCHAR(10)
                )
            )
            ELSE NULL
            END AS dateLivraison
    Into 
            :ECRANNUMEROLIVRAISON, 
            :ECRANNUMEROFACTURE, 
            :ECRANNUMEROTOURNEE,
            :ECRANCODECLIENT, 
            :ECRANNOMCOMMERCIALCLIENT, 
            :ECRANRAISONSOCIALECLIENT, 
            :ECRANDATELIVRAISON
    FROM VENTLV V
    LEFT JOIN CLIENT C ON C.CCOCLI = V.ECOCLL
    where V.ENULIV = :£NumeroLivraison;
    GestionErreurSQL();

   Else;

    //Sinon, on récupère les informations également dans la table KCOENT
    exec SQL
    SELECT DISTINCT 
            K.NUMEROLIVRAISON as numeroLivraison,
            K.numeroedition as numeroEdition,
            V.ENUFAC as numeroFacture, 
            V.ECOTRA as codeTournee, 
            V.ECOCLL as codeClient,
            C.CLISOC as nomCommercial,
            C.CLIDES as raisonSociale,
            CASE 
                WHEN V.EJJDLV > 0 AND V.EMMDLV > 0 AND V.EAADLV > 0 
                THEN DATE(
                    CAST(
                        CASE 
                            WHEN V.EXXDLV = 0 THEN '20'
                            ELSE DIGITS(V.EXXDLV)
                        END 
                        || RIGHT('00' || DIGITS(V.EAADLV), 2)
                        || '-'
                        || RIGHT('00' || DIGITS(V.EMMDLV), 2)
                        || '-' 
                        || RIGHT('00' || DIGITS(V.EJJDLV), 2)
                        AS VARCHAR(10)
                    )
                )
                ELSE NULL
            END AS dateLivraison
    Into    :ECRANNUMEROLIVRAISON, 
            :ECRANNUMEROEDITION, 
            :ECRANNUMEROFACTURE, 
            :ECRANNUMEROTOURNEE,
            :ECRANCODECLIENT, 
            :ECRANNOMCOMMERCIALCLIENT, 
            :ECRANRAISONSOCIALECLIENT, 
            :ECRANDATELIVRAISON
    FROM KCOENT K
    LEFT JOIN VENTLV V ON V.ENULIV = K.NUMEROLIVRAISON
    LEFT JOIN CLIENT C ON C.CCOCLI = V.ECOCLL
    Where K.NUMEROLIVRAISON = :£NumeroLivraison;
    GestionErreurSQL();
   EndIf;

   // Filtres articles
   ECRANCODEARTICLEFILTRE = *Blanks;  
   ECRANLIBELLE1ARTICLEFILTRE = *Blanks;

   //Gestion affichage/protection des quantités
    If (£Mode = VISUALISATION);
        Indicateur.ProtegerQuantiteRetournee=*On;
        Indicateur.ProtegerQuantiteLivree=*On;
    Else;
        Indicateur.ProtegerQuantiteRetournee=*Off;
        Indicateur.ProtegerQuantiteLivree=*Off;
    EndIf;
    If (£Operation = LIVRAISON);
        Indicateur.MasquerQuantiteRetournee=*On;
    Else;
        Indicateur.MasquerQuantiteRetournee=*Off;
    EndIf;
End-Proc;


///
// ChargerSousFichier()
// Charge le sous-fichier 
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

    ClauseSelect = 'SELECT DISTINCT ACOART, ALIAR1 ';
                  
    ClauseFROM = 'FROM VARTIC';

    ClauseWhere = CreationClauseWhere();
    
    ClauseOrderBy = 'ORDER BY ACOART';

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
            :ECRANLIGNECODEARTICLE,
            :ECRANLIGNELIBELLE1ARTICLE;
    GestionErreurSQL();

    If SQLCode = 100; //Aucun enregistrement n'a été trouvé
        ECRANMESSAGEERREUR = 'Aucun article trouvé';
        Indicateur.MasquerMessageErreur = *Off;
        
    ElseIf SQLCode = 0;// Des enregistrements ont été trouvés
        DoW SQLCode = 0;
            // Incrémentation du rang
            fichierDS.rang_sfl += 1;

            //Gestion des quantités livrées/retournées
            // On recherche si une quantité a été saisie
            // Si aucune quantité trouvé, on met 0
            exec SQL
                select QuantiteLivree,
                       QuantiteRetournee
                Into :EcranLigneQuantiteLivree,
                     :EcranLigneQuantiteRetournee
                From KCOLIG
                Where numeroLivraison = :£NumeroLivraison 
                AND codeArticle = :EcranLigneCodeArticle;
                If SQLCode = 100; //Pas d'enregistrement trouvé
                    EcranLigneQuantiteLivree = 0;
                    EcranLigneQuantiteRetournee = 0;
                Else;
                    GestionErreurSQL();
                EndIf;

            // Écriture dans le sous-fichier  
            Write GESTIONSFL;

            // Lecture suivante
            exec sql FETCH FROM C1 INTO 
                :ECRANLIGNECODEARTICLE,
                :ECRANLIGNELIBELLE1ARTICLE;
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
    EcranDeplacerCurseurColonne = 61;  
End-Proc;


///
// Création clause Where
// Permet de construire la clause where en fonction des filtres
// Filtres disponibles :
//  - Code article (exact)
//  - type article doit être celui de la table XCOPAR
//  - Libellé 1 article (contient)
//
// @Return : ClauseWhere char(2048)
///
Dcl-Proc CreationClauseWhere;
    Dcl-Pi *n Char(2048);
    End-Pi;

    Dcl-S ClauseWhere char(2048);

    // Construction clause where de base avec Filtre libellé 1 article (contient)
    ClauseWhere = 'WHERE UPPER(ALIAR1) LIKE ' + QUOTE +
                      POURCENTAGE + %Trim(EcranLibelle1ArticleFiltre) + 
                      POURCENTAGE + QUOTE;


    ClauseWhere  = %trimr(ClauseWhere) + ' AND ACOTYA = '+ QUOTE 
    + ParametresConsigne.TypeArticle + QUOTE;
    
    // Filtre code article
    If EcranCodeArticleFiltre <> *Blanks;
        ClauseWhere = %trimr(ClauseWhere)
                        + ' AND ACOART LIKE ' + QUOTE + 
                        EcranCodeArticleFiltre + QUOTE;
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
///
Dcl-Proc Action;

    Dcl-s CodeVerbe char(3) inz('GER');
    Dcl-s CodeObjet char(6) inz('LIVCON');
    Indicateur.MasquerMessageErreur = *On;  
    ECRANMESSAGEERREUR = *BLANKS;
    Indicateur.MasquerMessageInfo = *On;
    ECRANMESSAGEINFO = *BLANKS;

    Select;
        When fichierDS.TouchePresse = F2;
            AffichageFenetreUtilisateur(CodeVerbe:CodeObjet);

        When fichierDS.TouchePresse = F3;
            Fin=AffichageEcranValidation();
            Refresh=*On;

        When fichierDS.TouchePresse = F6;
            AffichageFenetreServices();

        When fichierDS.TouchePresse = F12;
            Fin=*On;

        When  fichierDS.touchePresse = ENTREE;
            
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
// Ecran FIN Validation
// Affichage de l'écran de validation avec ses 5 Options
// Gère les différentes options possibles pour une fin de travail du programme
//  '0' : touche F12 utilisée
//  '1' : mise à jour et retour écran de garde
//  '2' : pas de mise à jour et retour écran de garde
//  '3' : mise à jour et fin de programme
//  '4' : fin de programme sans mise à jour
//  '5' : reprise
//
// @return Ind *On si fin de programme, *Off si pas de fin
///
Dcl-Proc AffichageEcranValidation;
    Dcl-Pi *n ind;

    End-Pi;

    Dcl-S FinProgramme Ind;

    Select;
        When £Mode = CREATION ;
            EcranFinChoix1 = '*';
            EcranFinChoix2 = '2';
            EcranFinChoix3 = '3';
            EcranFinChoix4 = '4';
            EcranFinChoixAction =  3;
        When £Mode = MODIFICATION;
            EcranFinChoix1 = '1';
            EcranFinChoix2 = '2';
            EcranFinChoix3 = '3';
            EcranFinChoix4 = '4';
            EcranFinChoixAction =  3;
        When £Mode = VISUALISATION;
            EcranFinChoix1 = '*';
            EcranFinChoix2 = '2';
            EcranFinChoix3 = '*';
            EcranFinChoix4 = '4';
            EcranFinChoixAction =  5;
        other;
            EcranFinChoix1 = '*';
            EcranFinChoix2 = '2';
            EcranFinChoix3 = '*';
            EcranFinChoix4 = '4';
            EcranFinChoixAction =  5;
    EndSl;

    // Suite du programme en fonction du choix de l'utilisateur
    //              code retour  '0' : F12
    //                           '1' : mise à jour et retour écran gar
    //                           '2' : pas de mise à jour et retour éc
    //                           '3' : mise à jour et fin de programme
    //                           '4' : fin de programme sans mise à j.
    //                           '5' : reprise
    EXFMT FMFIN;
    Select;
        When fichierDS.TouchePresse = F12 Or EcranFinChoixAction = 5;

        When EcranFinChoixAction = 1 AND EcranFinChoix1 <> '*';
            EcritureTables();

        When EcranFinChoixAction = 2 AND EcranFinChoix2 <> '*';

        When EcranFinChoixAction = 3 AND EcranFinChoix3 <> '*';
            EcritureTables();
            FinProgramme = *On;

        When EcranFinChoixAction = 4 AND EcranFinChoix4 <> '*';
            FinProgramme = *On;

        Other;

    EndSl;

    Return FinProgramme;

End-Proc;


// ------------------------------------------------------------------------------------
// EcritureTables()
//
// Ecris dans les tables suivantes :
// Fichier des entêtes des livraisons de consignes : KCOENT
// Fichier des lignes des livraisons de consignes : KCOLIG
// Fichier des cumuls de consignes par client : KCOCUM
// ------------------------------------------------------------------------------------
dcl-proc EcritureTables;

    Dcl-S i Zoned(4:0);
    Dcl-S KCOLIGExiste Ind;
    Dcl-S KCOCUMExiste Ind;
    Dcl-S QuantiteLivree            Packed(4:0);
    Dcl-S QuantiteRetournee         Packed(4:0);
    Dcl-S QuantiteCumulEcart        Packed(4:0);
    Dcl-S QuantiteTheoriqueStock    Packed(4:0);

    //Gestion de la table KCOENT
    If (£Mode = CREATION And £Operation = LIVRAISON);
        //Insert KCOENT
        Exec Sql
        INSERT INTO KCOENT (
            NUMEROLIVRAISON,     
            NUMEROEDITION,       
            LIVRAISONTIMESTAMP,  
            LIVRAISONUTILISATEUR,
            TOPRETOUR
        ) VALUES (
            :£NumeroLivraison,
            0,
            CURRENT TIMESTAMP,
            psds.User,
            'N'
        );
        GestionErreurSQL();

    Else;//UPDATE KCOENT
        // - Update KCOENT LIVRAISON
        If (£Operation = LIVRAISON);
        Exec SQL
        UPDATE KCOENT
        SET 
            LIVRAISONTIMESTAMP = CURRENT TIMESTAMP,
            LIVRAISONUTILISATEUR = :psds.User
        WHERE 
            NUMEROLIVRAISON = :£NumeroLivraison;
        GestionErreurSQL();

        ElseIf (£Operation = RETOUR);
        //Update KCOENT RETOUR
        Exec SQL
        UPDATE KCOENT
        SET 
            TOPRETOUR = 'O',
            RETOURTIMESTAMP = CURRENT TIMESTAMP,
            RETOURUTILISATEUR = :psds.User
        WHERE 
            NUMEROLIVRAISON = :£NumeroLivraison;
        GestionErreurSQL();
        EndIf;

    EndIf;


    For i = 1 to NombreTotalLignesSF;
        Chain i GESTIONSFL;

            // Verification si la ligne n'existe pas dans KCOLIG
            //Pour l'article et la livraison
            // Si n'existe pas => Insert
            // Si existe => Update
            Exec SQL
                Select count(NumeroLivraison)
                Into :Compteur
                From KCOLIG
                Where NumeroLivraison = :£NumeroLivraison
                And CodeArticle = :EcranLigneCodeArticle;
                GestionErreurSQL();
                If compteur = 0;
                    KCOLIGExiste=*Off;
                Else;
                    KCOLIGExiste=*On;
                EndIf;

                //La ligne n'existe pas : Insert
                If KCOLIGExiste = *Off 
                And (EcranLigneQuantiteLivree <> 0 OR EcranLigneQuantiteRetournee <> 0);
                Exec SQL
                    INSERT INTO KCOLIG (
                    NumeroLivraison,
                    CodeArticle, 
                    QuantiteLivree,
                    QuantiteRetournee
                ) VALUES (
                    :£NumeroLivraison,
                    :EcranLigneCodeArticle,
                    :EcranLigneQuantiteLivree,      
                    :EcranLigneQuantiteRetournee        
                );
                GestionErreurSQL();
                Else;
                //La ligne existe : Update
                Exec SQL
                    UPDATE KCOLIG
                    SET 
                        QuantiteLivree = :EcranLigneQuantiteLivree,
                        QuantiteRetournee = :EcranLigneQuantiteRetournee
                    WHERE 
                        NUMEROLIVRAISON = :£NumeroLivraison
                        And CodeArticle = :EcranLigneCodeArticle;
                    GestionErreurSQL();
                EndIf;

            // Vérification si la ligne existe pas dans KCOCUM
            // Pour le client
            // SI SQL = 100 => Insert
            // Si SQL = 0 => Update
            Exec SQL
                Select 
                QuantiteLivree, 
                QuantiteRetournee, 
                QuantiteCumulEcart, 
                QuantiteTheoriqueStock
                Into
                :QuantiteLivree, 
                :QuantiteRetournee, 
                :QuantiteCumulEcart, 
                :QuantiteTheoriqueStock
                From KCOCUM
                Where CodeClient = :ECRANCODECLIENT
                And CodeArticle = :EcranLigneCodeArticle;
                If SQLCode = 0;
                KCOCUMExiste = *On;
                ElseIf SQLCode = 100;
                KCOCUMExiste = *Off;
                Else;
                KCOCUMExiste = *Off;
                GestionErreurSQL();
                EndIf;
            
            //La ligne n'existe pas : Insert
            If KCOCUMExiste = *Off;
            QuantiteTheoriqueStock = EcranLigneQuantiteLivree - EcranLigneQuantiteRetournee;
            Exec SQL
            INSERT INTO KCOCUM (
                CodeClient,
                CodeArticle,
                QuantiteLivree,
                QuantiteRetournee,
                QuantiteCumulEcart,
                QuantiteTheoriqueStock,
                HorodatageSaisie,
                TypeOperation,
                ProfilUser
            ) VALUES (
                :ECRANCODECLIENT,
                :ECRANLIGNECODEARTICLE,
                :ECRANLIGNEQUANTITELIVREE,
                :EcranLigneQuantiteRetournee,
                0,
                :QuantiteTheoriqueStock,
                CURRENT TIMESTAMP,
                :£Operation,
                :psds.User
            );
            GestionErreurSQL();
            Else;

             QuantiteLivree = QuantiteLivree + EcranLigneQuantiteLivree;
             QuantiteRetournee = QuantiteRetournee  + EcranLigneQuantiteRetournee;
             QuantiteTheoriqueStock = 
             QuantiteLivree - QuantiteRetournee + QuantiteCumulEcart;
            Exec SQL
                Update KCOCUM
                SET
                    QuantiteLivree = :QuantiteLivree,
                    QuantiteRetournee = :QuantiteRetournee,
                    QuantiteTheoriqueStock = :QuantiteTheoriqueStock
                Where CodeClient = :EcranCodeClient
                And CodeArticle = :EcranLigneCodeArticle;
                GestionErreurSQL();

            EndIf;
    EndFor;

    // Gestion de l'édition du bon de mise à disposition des consignes
    If (£Operation = LIVRAISON);
        //TODO:Edition du bon de mise à disposition

        //Mise à jour du nombre d'édition
        Exec SQL 
            UPDATE KCOENT
        SET 
            NUMEROEDITION = NUMEROEDITION + 1
        WHERE 
            NUMEROLIVRAISON = :£NumeroLivraison;
    EndIf;
end-proc;