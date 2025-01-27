**free
Ctl-opt Option(*srcstmt:*nodebugio ) AlwNull(*usrctl) UsrPrf(*owner)
        DatFmt(*eur) DatEdit(*dmy) TimFmt(*hms) dftactgrp(*no);

// Appel ligne de commande :
// CALL PGM(KUTP30) PARM((GER  (*CHAR 4)) (DRUNAP (*CHAR 6))
//  ('Gestion unités de transport' (*CHAR 30)))

//
// --------------------------------------------------------------
//       NOM        : KUTP30               TYPE : Interactif
//
//  TITRE      : Unité Transport.: Gestion interactif
//
//  FONCTIONS  :
//               Gestion en 2 étapes  :
//               . 1er écran de filtre de sélection des UT selon :
//                   - Unité de transport
//                       - Numéro
//                       - Identifiant
//                       - Type
//                   - Evènement
//                       - Compagnie
//                       - Transporteur
//                       - Nom bateau
//                       - Date évènement
//                   - Filtre
//                       - UT clôturées
//                       - Date de création
//                   - Dossiers
//                       - Dossier de revient
//                       - Dossier interne
//
//               . 2e écran de saisie d'action de l'UT en fonction des droits :
//                      1 - Gestion UT
//                      2 - Visualisation UT
//                      3 - Gestion évènements
//                      4 - Visualisation évènements
//                      5 - Gestion constat ouverture
//                      6 - Visualisation constat ouverture
//                      7 - Entrée dépôt
//                      8 - Gestion contenu UT
//                      9 - Visualisation contenu UT
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
//  ECRIT DU   : 29/09/2023            PAR : ANg (Antilles Glaces)
//        AU   : 25 /10/2023
//
// ---------------------------------------------------------------
//  MODIFIE DU   : 08/11/2023            PAR : ANg (Antilles Glaces)
//        AU   :   26/11/2024
// Correction  :
// - Limiter le nombre d'UT sélectionné au max à 20
// - Inverser Code action Gst/visu contenu UT et Gst/visu évènement
// - Rafraichissement de l'écran des UTs après un retour de programme
// ---------------------------------------------------------------------

// Déclaration fichier

// --- Fichiers --------------------------------------------------------
Dcl-F KUTP30E  WorkStn
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

//Prototype des programmes appelés
Dcl-Pr KUTP31 ExtPgm;
    NumeroUT Packed(7:0) const;
    Mode Char(13) const;
    CodeSociete Char(2) const;
    ReturnOperationEffectuee char(1);
End-Pr ;

Dcl-Pr KUTP32 ExtPgm;
    NumeroUT Packed(7:0) const;
    Mode Char(13) const;
    CodeSociete Char(2) ;
    ReturnOperationEffectuee char(1);
End-Pr ;

Dcl-Pr KUTP33 ExtPgm;
    UTATraiter Packed(7:0) dim(20) const;
    CodeSociete Char(2) const;
    Mode Char(13) const;
    ReturnOperationEffectuee char(1); //Valeur retournée Création/Modification/Suppression
End-Pr ;

Dcl-Pr KUTP34 ExtPgm;
    NumeroUT Packed(7:0) const;
    CodeSociete Char(2) const;
    Mode Char(13) const;
    ReturnOperationEffectuee char(1); //Valeur retournée Création/Modification/Suppression
End-Pr ;

Dcl-Pr KUTP36 ExtPgm;
    NumeroUT Packed(7:0) const;
    CodeSociete Char(2) const;
    Mode Char(13) const;
    ReturnOperationEffectuee char(1); //Valeur retournée Création/Modification/Suppression
End-Pr ;

Dcl-Pr KGDP100CL ExtPgm;
    COVER Char(4);
    COOBJ Char(6);
    LIACT Char(30);
End-Pr ;

Dcl-Pr KUTP120CL ExtPgm;
    COVER Char(4);
    COOBJ Char(6);
    LIACT Char(30);
    USELEC char(256);
    USELA1 char(256);
    USELA2 char(256);
End-Pr;

Dcl-Pr RAUP200CL ExtPgm;
    COVER Char(4);
    COOBJ Char(6);
    LIACT Char(30);
End-Pr;

// Recherche multi-critères sur numéro d'OA
/DEFINE PR_VAIOAF
// Recherche valeur table chartreuse
/DEFINE PR_VORPAR
// Fenêtre utilisateur
/DEFINE PR_GOAFENCL
// Fenêtre service
/DEFINE PR_GOASER

/INCLUDE qincsrc,prototypes

/UNDEFINE PR_VAIOAF
/UNDEFINE PR_VORPAR
/UNDEFINE PR_GOAFENCL
/UNDEFINE PR_GOASER


// --- Variables -------------------------------------------------------
Dcl-S CommandeCL                                  VarChar(200);
Dcl-S Etape                                       VarChar(40);
Dcl-S BibliothequeFichier                         Char(9);
Dcl-S NombreTotalLignesSF                         Packed(4:0);
Dcl-S UTATraiter                                  Packed(7:0) Dim(20);
Dcl-S ActionUT                                    Char(1);
Dcl-S NombreUTATraiter                            Packed(2:0);

// --- Constantes -------------------------------------------------------
Dcl-C VISUALISATION 'VISUALISATION';
Dcl-C MODIFICATION 'MODIFICATION';
Dcl-C CREATION 'CREATION';
Dcl-C CODEOBJETAPPRO 'DRUNAP';
Dcl-C CODEOBJETLOG 'DRUNLO';
Dcl-C CODEOBJETREV 'DRUNRE';
Dcl-C ETAPE_AFFICHAGE_ECRAN_1 'AffichageEcran1';
Dcl-C ETAPE_AFFICHAGE_ECRAN_2 'AffichageEcran2';
Dcl-C ETAPE_FIN 'Fin';
Dcl-C CHAR_N 'N';

// --- Data-structures Ecran    --------------------------------------
Dcl-Ds DSPFSauve Qualified;
    Totalite                                Char(4000);
    Element                                 Char(80) Dim(50) Overlay(Totalite);
    Clef                                    Char(30) Overlay(Element);
    Valeur                                  Char(50) Overlay(Element:*Next);
End-Ds;

// Recherche F4
Dcl-Ds RechercheF4_t Qualified template;
    CodeRacine                              Char(6);
    Position                                Packed(2:0);
    NumeroContenu                           Packed(2:0);
    CodeRetour                              Char(1);
    Argument                                Char(12);
    Libelle                                 Char(90);
End-Ds;

// --- Data-structures Indicateurs--------------------------------------
Dcl-Ds Indicateur qualified;

    SousFichierDisplay                              Ind Pos(51);
    SousFichierDisplayControl                       Ind Pos(52);
    SousFichierClear                                Ind Pos(53);
    SousFichierEnd                                  Ind Pos(54);

    MSGERR_DateCreationInvalide                     Ind Pos(60);
    MSGERR_DateEvenementInvalide                    Ind Pos(61);
    MSGERR_CompagnieInconnue                        Ind Pos(62);
    MSGERR_TransporteurInconnu                      Ind Pos(63);
    MSGERR_AucunEnregistrement                      Ind Pos(64);
    MSGERR_CodeSocieteInconnu                       Ind Pos(65);
    MSGERR_CodestatutUTInconnu                      Ind Pos(66);
    MSGERR_CodeTypeUTInconnu                        Ind Pos(67);
    MSGERR_UtClotureesIncorrect                     Ind Pos(68);
    MSGERR_CodeBateauInconnu                        Ind Pos(69);
    MSGERR_CodestatutRVInconnu                      Ind Pos(70);

    MasquerMessageErreurEcran1                      Ind Pos(81) Inz(*On);
    MasquerMessageErreurEcran2                      Ind Pos(82) Inz(*On);
    MasquerMessageInfoEcran2                        Ind Pos(83) Inz(*On);
    MasquerActionsAppro                             Ind Pos(84) Inz(*Off);
    MasquerActionsLog                               Ind Pos(85) Inz(*Off);
    MasquerActionsRevient                           Ind Pos(86) Inz(*Off);

End-Ds ;

// --- Data-structure KUTF11 ------------------------
Dcl-Ds kutf11_t EXTNAME('KUTF11') qualified template end-ds;

// LDA pour communiquer avec le programme VAIOAF
Dcl-Ds LDA dtaara(*LDA) Qualified;
    ZoneTotale  Char(256);
    NumeroOA    Char(8) pos(01);
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

// Initialisation de début de programme
InitialisationProgramme();
// Initialisation écran 1
InitialisationEcran1() ;

Etape = ETAPE_AFFICHAGE_ECRAN_1;
// Boucle de traitement du programme
DoW Etape <> ETAPE_FIN;
    Select;

        When Etape = ETAPE_AFFICHAGE_ECRAN_1 ;
            AffichageEcran1() ;

        When Etape = ETAPE_AFFICHAGE_ECRAN_2 ;
            AffichageEcran2() ;

        Other ;
    EndSl;
EndDo;

*Inlr= *On;

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
// - Purge du fichier des blocages KUTF30
///

Dcl-Proc InitialisationProgramme;

    Dcl-Ds OBJD Qualified;
        NomObjet char(10) inz('VRESTK');//On prend le nom d'un fichier au pif.
        TypeObjet char(6) inz('*FILE');
    End-Ds;

    // Commande CL permettant de récupérer des informations sur un fichier.
    // La sortie de la commande sera stockée sur QTEMP/OBJD
    CommandeCL = 'DSPOBJD OBJ(' + %trimr(OBJD.NomObjet) + ') ' +
                 'OBJTYPE(' + %trimr(OBJD.TypeObjet) + ') ' +
                 'OUTPUT(*OUTFILE) OUTFILE(QTEMP/OBJD)';
    ExecCL(CommandeCL);

    // Récupération du nom de la bilbiothèque
    Exec SQL
    SELECT ODLBNM INTO :BibliothequeFichier FROM QTEMP.OBJD WHERE ODOBNM = :OBJD.NomObjet;


    // Création du UserIndex s'il n'existe pas
    CreationUserIndex(psds.Proc:BibliothequeFichier);

    // Purge du fichier des blocages
    // On supprime toutes les restrictions qui sont antiérieurs à la veille
    Exec SQL
    DELETE FROM KUTF30 WHERE StartTimestamp < CURRENT_DATE - 1 DAY;
    GestionErreurSQL();

End-Proc;


///
// Ecran 1 : Initialisations pour l'écran 1
// Suite du programme : Affichage Ecran 1
// - Affichage écran libellé de l'action
// - Récupération et affichage du dernier code société utilisé
// - Récupération et affichage du libellé de la société
// - Initialisations des dates
// - Initialisation Filtre UT Cloturées
// - Définition Variable écran Verbe/Objet
// - Restrictions actions selon profil utilisateur
// - Positionnement curseur
///

Dcl-Proc InitialisationEcran1;

    // Suite normale du programme : AffichageEcran1
    Etape = ETAPE_AFFICHAGE_ECRAN_1;

    // Récupération du libellé de l'action
    EcranLibelleAction = £LibelleAction;

    // Initialisation message erreur
    Indicateur.MasquerMessageErreurEcran1 = *On;

    // Récupération des dernières valeurs utilisées par l'utilisateur lors du
    // dernier lancement du PGM
    DSPFSauve.TOTALITE = GetValeursUserIndex(psds.Proc:BibliothequeFichier:psds.User);
    // Initialisation code société
    If (DSPFSauve.Valeur(1) <> *BLANKS);
        EcranCodeSociete = DSPFSauve.Valeur(1);
    EndIf;
    // Initialisation Filtre UT Cloturées
    If (DSPFSauve.Valeur(2) <> *BLANKS);
        ECRANUTCLOTUREES = DSPFSauve.Valeur(2);
    EndIf;

    // Récupération et affichage du libellé de la société
    If EcranCodeSociete <> *BLANKS;

        EcranLibelleSociete = GetLibelleSociete(EcranCodeSociete);

        If (EcranLibelleSociete = *BLANKS);
            EcranLibelleSociete = *ALL'?';
        EndIf;
    EndIf;

    // Initialisation des dates de création
    EcranDateCreationDebut = %Date() - %months(6);
    EcranDateCreationFin = %Date();
    ECRANDATERECEPTIONFIN = %Date();



    // Restriction actions selon profil utilisateur
    Indicateur.MasquerActionsLog = *On;
    Indicateur.MasquerActionsAppro = *On;
    Indicateur.MasquerActionsRevient = *On;

    Select;
        //Pour les utilisateurs appro
        when (£CodeObjet = CODEOBJETAPPRO);
            Indicateur.MasquerActionsAppro = *Off;

        //Pour les utilisateurs log
        when (£CodeObjet = CODEOBJETLOG);
            Indicateur.MasquerActionsLog = *Off;

        //Pour les utilisateurs revient
        when (£CodeObjet = CODEOBJETREV);
            Indicateur.MasquerActionsRevient = *Off;
        other;
        // handle other conditions
    EndSl;

    // Définition Verbe/Objet
    EcranVerbeObjet = £CodeVerbe + £CodeObjet;

    // Positionnement curseur
    // Sur code société si vide
    If (EcranCodeSociete = *BLANKS);
        EcranDeplacerCurseurLigne = 06;
        EcranDeplacerCurseurColonne = 14;
    Else;
    // Sur Numéro UT sinon
        EcranDeplacerCurseurLigne = 09;
        EcranDeplacerCurseurColonne = 13;
    EndIf;
End-Proc;


///
// Ecran 1 : Affichage-lecture de l'écran
// Actions utilisateurs :
// - F2 : Affichage fenetre utilisateur
// - F3 : Sauvegarde saisies utilisateurs et fin de programme
// - F4 : Recherche sur zone
// - F5 : Verification et reaffichage
// - F6 : Affichage fenetre service
// - F12 : Fin de programme
// - F23 : Recherche multi-critères
// - Entrée : Vérification des saisies et si pas d'erreur, initialisation écran 2
///

Dcl-Proc AffichageEcran1;
    // Affichage - lecture d'écran
    EXFMT SELECTION;

    // Initialisation des erreurs :
    Indicateur.MSGERR_DateCreationInvalide  = *Off;
    Indicateur.MSGERR_DateEvenementInvalide = *Off;
    Indicateur.MSGERR_CompagnieInconnue = *Off;
    Indicateur.MSGERR_TransporteurInconnu = *Off;
    Indicateur.MSGERR_AucunEnregistrement = *Off;
    Indicateur.MSGERR_CodeSocieteInconnu = *Off;
    Indicateur.MSGERR_CodestatutUTInconnu = *Off;
    Indicateur.MSGERR_UtClotureesIncorrect = *Off;

    Indicateur.MasquerMessageErreurEcran1 = *On;

    // Repositionnement du curseur là Où il se trouvait
    EcranDeplacerCurseurLigne = fichierDS.ligne;
    EcranDeplacerCurseurColonne = fichierDS.colonne;

    // Gestion action utilisateur
    Select ;
        When fichierDS.TouchePresse = F2;
            AffichageFenetreUtilisateur(£CodeVerbe:£CodeObjet);
            Etape = ETAPE_AFFICHAGE_ECRAN_1 ;

        When fichierDS.TouchePresse = F3;
            SauvegardeSaisiesUtilisateur();
            Etape = ETAPE_FIN;

        When fichierDS.TouchePresse = F4;
            RechercheEcran1() ;
            Etape = ETAPE_AFFICHAGE_ECRAN_1;

        When fichierDS.TouchePresse = F6;
            AffichageFenetreServices();
            Etape = ETAPE_AFFICHAGE_ECRAN_1 ;

        When fichierDS.TouchePresse = F12;
            Etape = ETAPE_FIN;

        When fichierDS.touchePresse = F23;
            RechercheMultiCriteres();
            Etape = ETAPE_AFFICHAGE_ECRAN_1 ;

        When fichierDS.TouchePresse = ENTREE;
            // On vérifie qu'il y a au moins un enregistrement
            // et on initialise les valeurs du sous fichier avec les enregistrements
            If VerificationEcran1() And InitialiseSousFichierSiExistant();
                SauvegardeSaisiesUtilisateur();
                InitialisationEcran2();
            Else;
                Etape = ETAPE_AFFICHAGE_ECRAN_1;
            EndIf;
        Other;

    EndSl;
End-Proc;


///
// RechercheEcran1
// Recherche des valeurs possibles pour la zone où se trouve le curseur
// - Recherche sur code Compagnie
// - Recherche sur code Transporteur
// - Recherche sur code société
// - Recherche sur code statut
// - Recherche sur type UT
// - Recherche sur code bateau
// - Recherche sur statut RV
///

Dcl-Proc RechercheEcran1;

    Dcl-Ds RetourRechercheF4 LikeDs(RechercheF4_t);
    Dcl-C CODE_RETOUR_ERREUR '1';

    Select;
      // Recherche sur code Compagnie
        When (EcranZoneCurseur = 'ECOCOM');
            RetourRechercheF4 = RechercheF4CodeCompagnie();
            If (RetourRechercheF4.CodeRetour <> CODE_RETOUR_ERREUR );
                EcranCodeCompagnie = RetourRechercheF4.Argument;
                EcranLibelleCompagnie = RetourRechercheF4.Libelle;
            EndIf;

      // Recherche sur code Transporteur
        When (EcranZoneCurseur = 'ECOTRS');
            RetourRechercheF4 = RechercheF4Intervenant();
            If (RetourRechercheF4.CodeRetour <> CODE_RETOUR_ERREUR );
                EcranCodeTransporteur = RetourRechercheF4.Argument;
                EcranLibelleTransporteur = RetourRechercheF4.Libelle;
            EndIf;

      // Recherche sur code Société
        When (EcranZoneCurseur = 'ECOSTE');
            RetourRechercheF4 = RechercheF4CodeSociete();
            If (RetourRechercheF4.CodeRetour <> CODE_RETOUR_ERREUR );
                EcranCodeSociete = RetourRechercheF4.Argument;
                EcranLibelleSociete = RetourRechercheF4.Libelle;
            EndIf;

      // Recherche sur code statut
        When (EcranZoneCurseur = 'ESTAUT');
            RetourRechercheF4 = RechercheF4StatutUT();
            If (RetourRechercheF4.CodeRetour <> CODE_RETOUR_ERREUR );
                EcranStatutUT = RetourRechercheF4.Argument;
                EcranLibelleStatutUT = RetourRechercheF4.Libelle;
            EndIf;

      // Recherche sur type UT
        When (EcranZoneCurseur = 'ETYPUT');
            RetourRechercheF4 = RechercheF4TypeUT();
            If (RetourRechercheF4.CodeRetour <> CODE_RETOUR_ERREUR );
                EcranTypeUT = RetourRechercheF4.Argument;
                EcranLibelleTypeUT = RetourRechercheF4.Libelle;
            EndIf;

        // Recherche sur nom bateau
        When (EcranZoneCurseur = 'ECODBA');
            RetourRechercheF4 = RechercheF4NomBateau();
            If (RetourRechercheF4.CodeRetour <> CODE_RETOUR_ERREUR );
                EcranCodeBateau = RetourRechercheF4.Argument;
                EcranLibelleBateau = RetourRechercheF4.Libelle;
            EndIf;

        When (EcranZoneCurseur = 'ESTARV');
            RetourRechercheF4 = RechercheF4StatutRevient();
            If (RetourRechercheF4.CodeRetour <> CODE_RETOUR_ERREUR );
                EcranStatutRevient = RetourRechercheF4.Argument;
                EcranLIbelleStatutRevient = %subst(RetourRechercheF4.Libelle:1:10);
            EndIf;

        Other;
    EndSl;
End-Proc;


///
// RechercheMultiCritères
// Recherche des valeurs possibles pour la zone où se trouve le curseur
// - Recherche sur numéro OA
///

Dcl-Proc RechercheMultiCriteres;

  // Recherche sur numéro d'OA
    If EcranZoneCurseur = 'ENUMOA' ;
        LDA.ZONETOTALE = *BLANKS ;
        Out LDA ;
        VAIOAF.UCOVER = £CodeVerbe;
        VAIOAF.UCOOBJ = £CodeObjet;
        VAIOAF.ULIACT = £LibelleAction;
        VAIOAF.UCOPGP = *BLANKS;
        VAIOAF.UCOREP = *BLANKS;
        VAIOAF.UCOSTE = EcranCodeSociete;
        VAIOAF.UCOETC = *BLANKS;
        VAIOAF.UCOETL = *BLANKS;
        VAIOAF.UCOFRC = *BLANKS;
        VAIOAF.UCORET = *BLANKS;
        PR_VAIOAF(
            VAIOAF.UCOVER
            :VAIOAF.UCOOBJ
            :VAIOAF.ULIACT
            :VAIOAF.UCOPGP
            :VAIOAF.UCOREP
            :VAIOAF.UCOSTE
            :VAIOAF.UCOETC
            :VAIOAF.UCOETL
            :VAIOAF.UCOFRC
            :VAIOAF.UCORET
        );
        In LDA;
        If LDA.NumeroOA <> *BLANKS;
            EcranNumeroOA = %dec(LDA.NumeroOA:8:0);
        EndIf;
    EndIf;
End-Proc;


///
// Ecran 1 :  Vérification des saisies de l'écran 1
// Vérifications :
//  - La date de fin de création doit être supérieure à la date de début
//  - La date de fin d'évènement doit être supérieure à la date de début
//  - La compagnie doit exister
//  - Le transporteur doit exister
//  - La société doit exister
//  - Le code statut UT doit exister
//  - Le code statut REVIENT doit exister
//  - Le type d'UT doit exister
//  - Le filtre UT Clôturées doit être "O" ou "N"
//  - Le code bateau doit exister
//
// @return *On si OK, *Off si KO
///

Dcl-Proc VerificationEcran1;
    Dcl-Pi *N Ind;
    End-Pi;

    Dcl-S VerificationReturn Ind Inz(*On);

  //  - La date de fin de création doit être supérieure à la date de début
    If (EcranDateCreationFin < EcranDateCreationDebut And VerificationReturn = *On);
        Indicateur.MSGERR_DateCreationInvalide = *On;
        VerificationReturn = *Off;
    EndIf;


  //  - La date de fin d'évènement doit être supérieure à la date de début
    If (VerificationReturn = *On And EcranDateReceptionFin < EcranDateReceptionDebut);
        Indicateur.MSGERR_DateEvenementInvalide = *On;
        VerificationReturn = *Off;
    EndIf;


  //  - La compagnie doit exister
    If (VerificationReturn = *On And EcranCodeCompagnie <> *BLANKS);
        EcranLibelleCompagnie = GetLibelleCompagnie(EcranCodeCompagnie);

        If (EcranLibelleCompagnie = *BLANKS);
            VerificationReturn = *Off;
            Indicateur.MSGERR_CompagnieInconnue = *On;
        EndIf;

    Elseif (EcranCodeCompagnie = *BLANKS);
        EcranLibelleCompagnie = *BLANKS;

    EndIf;


  //  - Le transporteur doit exister
    If (VerificationReturn = *On And EcranCodeTransporteur <> *BLANKS);
        EcranLibelleTransporteur = GetLibelleIntervenant(EcranCodeTransporteur) ;

        If (EcranLibelleTransporteur = *ALL'?');
            Indicateur.MSGERR_TransporteurInconnu = *On;
            VerificationReturn = *Off;
        EndIf;

    Elseif (EcranCodeTransporteur = *BLANKS);
        EcranLibelleTransporteur = *BLANKS;
    EndIf;

  // La société doit exister
    If (VerificationReturn = *On);
        EcranLibelleSociete = GetLibelleSociete(EcranCodeSociete);

        If (EcranLibelleSociete = *ALL'?');
            Indicateur.MSGERR_CodeSocieteInconnu= *On;
            VerificationReturn = *Off;
        EndIf;

    Elseif (EcranCodeSociete = *BLANKS);
        EcranLibelleSociete = *BLANKS;

    EndIf;

  // Le statut de l'UT doit exister
    If (VerificationReturn = *On and EcranStatutUT <> *BLANKS);
        EcranLibelleStatutUT = GetLibelleStatutUT(EcranStatutUT);

        If (EcranLibelleStatutUT = *ALL'?');
            Indicateur.MSGERR_CodestatutUTInconnu = *On;
            VerificationReturn = *Off;
        EndIf;

    Elseif (EcranStatutUT = *BLANKS);
        EcranLibelleStatutUT = *BLANKS;

    EndIf;

  // Le statut revient doit exister
    If (VerificationReturn = *On and EcranStatutRevient <> *BLANKS);
        EcranLibelleStatutRevient = %subst(GetLibelleStatutUTRevient(ECRANSTATUTREVIENT):1:10);

        If (EcranLibelleStatutRevient = *ALL'?');
            Indicateur.MSGERR_CodestatutRVInconnu = *On;
            VerificationReturn = *Off;
        EndIf;

    Elseif (EcranStatutRevient = *BLANKS);
        EcranLibelleStatutRevient = *BLANKS;

    EndIf;

  // Le type d'UT doit exister
    If (VerificationReturn = *On and EcranTypeUT <> *BLANKS);
        EcranLibelleTypeUt = GetLibelleTypeUT(EcranTypeUt);

        If (EcranLibelleTypeUt = *ALL'?');
            Indicateur.MSGERR_CodeTypeUTInconnu = *On;
            VerificationReturn = *Off;
        EndIf;

    Elseif (EcranTypeUT = *BLANKS);
        EcranLibelleTypeUT = *BLANKS;

    EndIf;

  // Le Filtre UT Clôturée doit être 'O' ou 'N'
    If (VerificationReturn = *On);
        If (EcranUTCloturees <> CHAR_N And EcranUTCloturees <> 'O');
            VerificationReturn = *Off;
            Indicateur.MSGERR_UtClotureesIncorrect = *On;
        EndIf;
    EndIf;

  // - le bateau doit exister s'il est renseigné
    If (VerificationReturn = *On And EcranCodeBateau <> *BLANKS);
        EcranLibelleBateau = GetLibelleBateau(EcranCodeBateau) ;

        If (EcranLibelleBateau = *ALL'?');
            Indicateur.MSGERR_CodeBateauInconnu = *On;
            VerificationReturn = *Off;
        EndIf;

    Elseif VerificationReturn = *On and EcranCodeBateau = *BLANKS;
        EcranLibelleBateau = *BLANKS;
    EndIf;

    Return VerificationReturn;
End-Proc ;


///
// Ecran 1 : Sauvegarde des saisies utilisateurs
// - Sauvegarde des sélections dans le fichier des critères
///

Dcl-Proc SauvegardeSaisiesUtilisateur;

    DSPFSauve.Clef(1) = 'Code société';
    DSPFSauve.Valeur(1) = %Char(EcranCodeSociete);
    DSPFSauve.Clef(2) = 'Filtre UT Clôturées';
    DSPFSauve.Valeur(2) = %Char(ECRANUTCLOTUREES);

    PutValeursUserIndex(DSPFSauve.Totalite:psds.PROC:BibliothequeFichier:psds.USER);
End-Proc;


///
// Ecran 2 : Initialisation pour l'écran GESTIONCTL2
//  Initialisations
//  - Affichage de la première ligne du sous-fichier
//  - Positionnement du curseur
//  - Initialisation des valeurs
///

Dcl-Proc InitialisationEcran2;

    Dcl-S i Zoned(4:0);

  // Suite normale du programme : affichage de l'écran 2
    Etape = ETAPE_AFFICHAGE_ECRAN_2;

  // Initialisations
    Indicateur.SousFichierDisplay = *On;
    Indicateur.SousFichierEnd = *On;
    Indicateur.SousFichierDisplayControl = *On;

  // Réinitialisation des actions
    For i = 1 to NombreTotalLignesSF;
        Chain i GESTIONSFL;

        If %Found();
            EcranLigneOptionUT = *BLANKS;
            Update GESTIONSFL;
        EndIf;
    EndFor;

  // Positionnement sur la première ligne du sous-fichier
    EcranLigneSousFichier = 1;

  // Positionnement du curseur
    EcranDeplacerCurseurLigne = 10;
    EcranDeplacerCurseurColonne = 09;


End-Proc;


///
// Ecran 2 : Affichage-lecture de l'écran 2
// Actions utilisateurs :
//     - F2 => Affichage de la Fenêtre utilisateur
//      - F3 => Fin programme
//      - F6 => Affichage de la fenêtre services
//      - F12 => Repositionnement du curseur et affichage écran 1
//      - F9 => Création U.T -> Interdit user appro
//      - entrée => delete fichier de travail et VerificationSaisies
///

Dcl-Proc AffichageEcran2;

    Dcl-S Mode Char(13);
    Dcl-C CREATION 'CREATION';
    Dcl-s ActionCreationUT Char(1) Inz('C');
    Dcl-S ReturnOperationEffectuee Char(1);
    Dcl-S NouveauNumeroUT like(EcranNumeroUT);
    Dcl-S UtilisateurVerrou Like(psds.User) Inz(*BLANKS);

  // Affichage/Lecture de l'écran
    Write GESTIONBAS;
    ExFmt GESTIONCTL;


  // Suites exceptionnelles du programme :
    Select;
        When fichierDS.TouchePresse = F2;
            AffichageFenetreUtilisateur(£CodeVerbe:£CodeObjet);
            Etape = ETAPE_AFFICHAGE_ECRAN_2;

        When fichierDS.TouchePresse = F3;
            Etape = ETAPE_FIN;

        When fichierDS.TouchePresse = F6;
            AffichageFenetreServices();
            Etape = ETAPE_AFFICHAGE_ECRAN_2;

        When fichierDS.touchePresse = F9
            And (£CodeObjet = CODEOBJETAPPRO OR £CodeObjet = CODEOBJETREV);
            //Récupération du numéro de l'UT
            Exec SQL
                select DEC(XLIPAR) + 1
                Into :NouveauNumeroUT
                from VPARAM
                Where XCORAC = 'XUTNUM';
                GestionErreurSQL();

            //Vérification que l'UT n'est pas verrouillée
            //(quelqu'un créé déjà une UT)
            UtilisateurVerrou = VerificationLockUT(NouveauNumeroUT);

            //Si vérouillée, on affiche un message d'erreur
            //Sinon, on autorise la création de l'UT et on le verrouille
            // On le déverrouille à la fin de la création
             If UtilisateurVerrou <> *BLANKS;

                    ECRAN2MESSAGEERREUR =
                    'UT '+ %char(NouveauNumeroUT)
                    + ' bloqué par ' + UtilisateurVerrou;
                    Indicateur.MasquerMessageErreurEcran2 = *Off;

                    Write GESTIONBAS;

                    Else;
                    Indicateur.MasquerMessageErreurEcran2 = *On;

                    VerrouillageUT(NouveauNumeroUT:ActionCreationUT);
                    Mode = CREATION;
                    KUTP31(NouveauNumeroUT
                            :Mode
                            :EcranCodeSociete
                            :ReturnOperationEffectuee);
            EndIf;



            //Gestion si une opération a été effectuée
            If (ReturnOperationEffectuee = 'C');
                InitialiseSousFichierSiExistant();
                Ecran2MessageInfo = 'UT: ' + %Char(NouveauNumeroUT) + ' créée avec succès';
                Indicateur.MasquerMessageInfoEcran2 = *Off;
                Write GESTIONBAS;
            EndIf;

            //Déverrouillage de l'UT
            DeverrouillageUT(NouveauNumeroUT:ActionCreationUT);


        When fichierDS.TouchePresse = F12;
            EcranDeplacerCurseurLigne =  09;
            EcranDeplacerCurseurColonne =  13;
            Etape = ETAPE_AFFICHAGE_ECRAN_1;


        When  fichierDS.touchePresse = ENTREE;

            If VerificationEcran2();
                SauvegardeActionUT();
                GestionActionUtilisateur();
                If InitialiseSousFichierSiExistant();
                    InitialisationEcran2();
                Else;
                    Etape = ETAPE_AFFICHAGE_ECRAN_1;
                EndIf;
            EndIf;

        Other;
            Etape = ETAPE_AFFICHAGE_ECRAN_2;
    EndSl;



End-Proc;


///
// Verification Ecran 2
// - On vérifie qu'il n'y a pas plusieurs actions choisies en même temps
// - On limite le nombre d'actions à 10
// - Multi-sélection impossible sauf pour gestion évènement (code action 4)
// - Vérification constat ouverture en mode gestion : statut UT doit être réceptionné
// - Vérification on peut faire une gestion d'évènement
//   seulement si l'UT n'est pas rattaché à un OA
// @return *On si OK, *Off si KO
///

Dcl-Proc VerificationEcran2;
    Dcl-Pi *n Ind;
    End-Pi;

    Dcl-S i Zoned(4:0);
    Dcl-S Rang Zoned(2:0);
    Dcl-S SauvegardeAction Char(1);
    Dcl-S VerificationReturn Ind Inz(*On);
    Dcl-S statutUt Char(1);

    Dcl-C STATUT_UT_RECEPTIONNE 'R';
    Dcl-C STATUT_UT_CLOTURE 'X';
    Dcl-C CODE_ACTION_GEST_EVENEMENT '5';
    Dcl-C CODE_ACTION_VISU_EVENEMENT '6';
    Dcl-C CODE_ACTION_IMPRESSION 'R';
    Dcl-C CODE_ACTION_IMPRESSION_DETAIL 'D';
    Dcl-C CODE_ACTION_GEST_CONTENU '3';



    // Initialisations
    Indicateur.MasquerMessageErreurEcran2 = *On;
    Indicateur.MasquerMessageInfoEcran2 = *On;
    SauvegardeAction = *BLANKS;

    Rang = 1;
    For i = 1 to NombreTotalLignesSF;
        Chain i GESTIONSFL;

    // Vérifications
        If EcranLigneOptionUT <> *BLANKS;


      // Vérification qu'il n'y ait pas plusieurs actions
            If VerificationReturn = *On And SauvegardeAction <> *BLANKS
                And SauvegardeAction <> EcranLigneOptionUt;
                Ecran2MessageErreur = '  Une seule action à la fois';
                Indicateur.MasquerMessageErreurEcran2 = *Off;
                VerificationReturn = *Off;
            EndIf;

      // Vérification du nombre limite d'actions possible en même temps
            If VerificationReturn = *On And Rang > 20;
                Ecran2MessageErreur = '    Action limitée à 20 UT';
                Indicateur.MasquerMessageErreurEcran2 = *Off;
                VerificationReturn = *Off;
            EndIf;

      // Vérification Multi-sélection impossible sauf
      // - pour visualisation & gestion évènement (code action 5 & 6)
      // - pour impression des UT
            If VerificationReturn = *On And Rang > 1
            And SauvegardeAction <> *BLANKS
            And SauvegardeAction <> CODE_ACTION_VISU_EVENEMENT
            And SauvegardeAction <> CODE_ACTION_GEST_EVENEMENT
            And SauvegardeAction <> CODE_ACTION_IMPRESSION
            And SauvegardeAction <> CODE_ACTION_IMPRESSION_DETAIL;
                Ecran2MessageErreur = '  Plusieurs UT sélectionnées';
                Indicateur.MasquerMessageErreurEcran2 = *Off;
                VerificationReturn = *Off;
            EndIf;


        // Vérification constat ouverture en mode gestion (pas en mode visu) :
        // - le statut de l'UT au niveau du suivi des étapes
        //     doit être à 'R' (UT réceptionnée)
            If VerificationReturn = *On And EcranLigneOptionUt = '8'
            And £CodeObjet = CODEOBJETLOG;
                exec Sql
            Select RGESUI
            Into :statutUt
            From RUTFEN
            Where RCOSTE = :EcranCodeSociete And RNUMUT = :EcranLigneNumeroUT;

                If statutUt <> STATUT_UT_RECEPTIONNE;
                    If statutUt = STATUT_UT_CLOTURE;
                        ECRAN2MESSAGEERREUR = 'UT clôturée';
                    Else;
                        ECRAN2MESSAGEERREUR = ' l''UT n''a pas été receptionnée';
                    EndIf;

                    Indicateur.MasquerMessageErreurEcran2 = *Off;
                    VerificationReturn = *Off;
                EndIf;
            EndIf;

        // Vérification
        // Pas de modification possible sur le contenu d'une UT sur une UT déjà réceptionnée
            If VerificationReturn = *On
            And EcranLigneOptionUT = CODE_ACTION_GEST_CONTENU
            And (£CodeObjet = CODEOBJETAPPRO Or £CodeObjet = CODEOBJETREV);
                exec Sql
            Select RGESUI
            Into :statutUt
            From RUTFEN
            Where RCOSTE = :EcranCodeSociete And RNUMUT = :EcranLigneNumeroUT;

                If statutUt >= STATUT_UT_RECEPTIONNE;
                    ECRAN2MESSAGEERREUR = 'l''UT est receptionnée';
                    Indicateur.MasquerMessageErreurEcran2 = *Off;
                    VerificationReturn = *Off;
                EndIf;
            EndIf;

            Rang = Rang + 1;
            SauvegardeAction = EcranLigneOptionUT;
        EndIf;
    EndFor;


    Return VerificationReturn;

End-Proc;

// ----------------------------------------------------------------------------
//
//                                 UTILITAIRES
//                  Procédures qui sont spécifiques au programme
//
// -----------------------------------------------------------------------------


///
// InitialiseSousFichierSiExistant
// Permet de vérifier si un enregistrement existe
// et initialise les valeurs du sous-fichier
// selon les filtres appliqués par l'utilisateur
//  - Si des enregistrements existent, on initialise les valeurs du sous fichier
// du second écran et on revoie true
//  - Sinon, on fait rien et on renvoie false
//
// @Return : EnregistrementsTrouves Ind
///

Dcl-Proc InitialiseSousFichierSiExistant;
    Dcl-Pi *n Ind;
    End-Pi;

    Dcl-S Requete char(2048);
    Dcl-S EnregistrementsTrouves Ind Inz(*Off);

    Dcl-S ClauseSelect char(2048);
    Dcl-S ClauseFROM char(2048);
    Dcl-S ClauseWhere char(2048);
    Dcl-S ClauseOrderBy char(2048);

    Dcl-S NumeroUT Zoned(7:0);
    Dcl-S IdentifiantUT Char(20);
    Dcl-S StatutUt Char(1);
    Dcl-S DescriptionUt Char(30);
    Dcl-S CommentaireUT Char(60);

    Dcl-C ESPACE ' ';

    ClauseSelect = 'SELECT DISTINCT RGESUI, RNUMUT, RIDUT, RDESCR, RLIRSV ';
    ClauseFROM = 'FROM RUTFEN LEFT JOIN KUTFOA ON RUTFEN.RNUMUT = KUTFOA.PUTNUM';
    ClauseWhere = CreationClauseWhere();
    ClauseOrderBy = 'ORDER BY RNUMUT Desc ';

    Requete =
        %trimr(ClauseSelect) + ESPACE
        + %Trimr(ClauseFROM) + ESPACE
        + %Trimr(ClauseWhere) + ESPACE
        + %Trimr(ClauseOrderBy);

  // Préparation du curseur pour récupérer les résultats de la requête
    exec sql PREPARE S1 FROM :Requete;
    GestionErreurSQL();

  // Déclaration du curseur
    exec sql DECLARE C1 CURSOR FOR S1;
    GestionErreurSQL();

  // Ouverture du curseur
    exec sql OPEN C1;
    GestionErreurSQL();

  // Fetch
    exec sql FETCH FROM C1 INTO
            :StatutUt,
            :NumeroUT,
            :IdentifiantUT,
            :DescriptionUt,
            :CommentaireUT;
    If SQLCode = 100; //Aucun enregistrement n'a été trouvé
        Ecran1MessageErreur = '      Aucune UT trouvée';
        Indicateur.MasquerMessageErreurEcran1 = *Off;
        EnregistrementsTrouves = *Off;
    ElseIf SQLCode = 0;// Des enregistrements ont été trouvés

        EnregistrementsTrouves = *On;

    // Remise à blanc du sous-fichier
        Indicateur.SousFichierClear = *On;
        Write GESTIONCTL;
        Indicateur.SousFichierClear = *off;

    // Chargement du sous-fichier
        fichierDS.rang_sfl = 0;

        DoW SQLCode = 0;

            fichierDS.rang_sfl = fichierDS.rang_sfl + 1;

            EcranLigneNumeroUt = NumeroUT;
            EcranLigneIdentifiantUT = IdentifiantUT;
            EcranLigneDescriptionUt = DescriptionUt;

            If StatutUt <> *BLANKS;
                EcranLigneStatutUt = GetLibelleStatutUT(StatutUt);
            Else;
                EcranLigneStatutUt = *BLANKS;
            EndIf;

            Write GESTIONSFL;

      // Fetch
            exec sql FETCH FROM C1
            INTO :StatutUt,
            :NumeroUT,
            :IdentifiantUT,
            :DescriptionUt,
            :CommentaireUT;
            GestionErreurSQL();

        EndDo;
    // Affectation du nombre total de ligne
        NombreTotalLignesSF = fichierDS.rang_sfl;

    Else;//Erreur requete
        GestionErreurSQL();
    EndIf;


  // Fermeture du curseur
    exec sql CLOSE C1;
    GestionErreurSQL();

    Return EnregistrementsTrouves;
End-Proc ;


///
// Création clause Where
// Permet de construire la clause where en fonction des filtres
// Filtres possibles :
//      - Numéro UT
//      - Statut UT
//      - Type UT
//      - Description
//      - Identifiant
//      - Date de création
//      - UT Cloturées
//      - Dossier revient
//      - Statut Revient
//      - Dossier interne
//      - Compagnie
//      - Transporteur
//      - Nom du bateau
//      - Numero OA
//      - Date de réception
//
// @Return : ClauseWhere
///

Dcl-Proc CreationClauseWhere;
    Dcl-Pi *n Char(2048);
    End-Pi;

    Dcl-S ClauseWhere char(2048);
    Dcl-C STATUT_UT_CLOTURE 'X';
    Dcl-C QUOTE '''';
    Dcl-C ESPACE ' ';
    Dcl-C POURCENTAGE '%';

  // Construction clause where code societe
    ClauseWhere = 'WHERE RCOSTE LIKE ' + QUOTE + EcranCodeSociete + QUOTE + ESPACE;
    // - On ne prend pas les UT supprimés
    ClauseWhere = %trimr(ClauseWhere)
                        + 'And RTPCMS NOT LIKE '
                        + QUOTE + 'S' + QUOTE
                        + ESPACE;

  // Filtres:
  // - Numéro UT : Commence par
    If (EcranNumeroUT <> 0);
        ClauseWhere = %trimr(ClauseWhere)
                        + 'And RNUMUT LIKE '
                        + QUOTE + %Char(EcranNumeroUT) + POURCENTAGE + QUOTE
                        + ESPACE;
    EndIf;

  // - Statut UT : Identique
    If (EcranStatutUT <> *BLANKS);
        ClauseWhere = %trimr(ClauseWhere)
                    + 'And RGESUI LIKE '
                    + QUOTE + EcranStatutUT + QUOTE
                    + ESPACE;
    EndIf;

  // - Type UT : Identique
    If (EcranTypeUT <> *BLANKS);
        ClauseWhere = %trimr(ClauseWhere)
                    + 'And RTYPUT LIKE '
                    + QUOTE + EcranTypeUT + QUOTE
                    + ESPACE;
    EndIf;

  // - Description UT : Contient
    If (EcranDescriptionUt <> *BLANKS);
        ClauseWhere = %trimr(ClauseWhere)
                        + 'And UPPER(RDESCR) LIKE '
                        + QUOTE + POURCENTAGE + %Trim(EcranDescriptionUt) + POURCENTAGE + QUOTE
                        + ESPACE;
    EndIf;

  // - Identifiant UT : Contient
    If (EcranIdentifiantUT <> *BLANKS);
        ClauseWhere = %trimr(ClauseWhere)
                        + 'And UPPER(RIDUT) LIKE '
                        + QUOTE + POURCENTAGE + %Trim(EcranIdentifiantUT) + POURCENTAGE + QUOTE
                        + ESPACE;
    EndIf;

  // - Date de création de.. à .. RDTCRE
    ClauseWhere = %trimr(ClauseWhere)
                    + 'And RDTCRE BETWEEN '
                    + QUOTE  + %Char(EcranDateCreationDebut) + QUOTE
                    + ESPACE + 'And' + ESPACE
                    + QUOTE +  %Char(EcranDateCreationFin) + QUOTE
                    + ESPACE;

  // - Filtre UT Clôturées : Identique
    If (EcranUTCloturees = CHAR_N);
        ClauseWhere = %trimr(ClauseWhere)
                    + 'And RGESUI NOT LIKE '
                    + QUOTE + STATUT_UT_CLOTURE + QUOTE
                    + ESPACE;
    EndIf;

  // - Dossier de revient : Commence par
    If (EcranNumeroDossierRevient <> 0);
        ClauseWhere = %trimr(ClauseWhere)
                    + 'And RNUMDR LIKE '
                    + QUOTE + %Char(EcranNumeroDossierRevient) + POURCENTAGE + QUOTE
                    + ESPACE;
    EndIf;

  // - Statut UT : Identique
    If (EcranStatutRevient <> *BLANKS);
        ClauseWhere = %trimr(ClauseWhere)
                    + 'And RSTATU LIKE '
                    + QUOTE + EcranStatutRevient + QUOTE
                    + ESPACE;
    EndIf;

  // - Dossier interne : Commence par
    If (EcranNumeroDossierInterne <> *BLANKS);
        ClauseWhere = %trimr(ClauseWhere)
                    + 'And UPPER(RNUDOI) LIKE '
                    + QUOTE + EcranNumeroDossierInterne + POURCENTAGE + QUOTE
                    + ESPACE;
    EndIf;

  // - Compagnie : Identique
    If (EcranCodeCompagnie <> *BLANKS);
        ClauseWhere = %trimr(ClauseWhere)
                    + 'And RCOCMA LIKE '
                    + QUOTE + EcranCodeCompagnie + QUOTE
                    + ESPACE;
    EndIf;

  // - Transporteur : Identique
    If (EcranCodeTransporteur <> *BLANKS);
        ClauseWhere = %trimr(ClauseWhere)
                    + 'And RCOINT LIKE '
                    + QUOTE +  %Char(EcranCodeTransporteur) + QUOTE
                    + ESPACE;
    EndIf;

  // - Nom du bateau : Identique
    If (EcranCodeBateau <> *BLANKS);
        ClauseWhere = %trimr(ClauseWhere)
                    + 'And RCDBAT LIKE '
                    + QUOTE +  %Char(EcranCodeBateau) + QUOTE
                    + ESPACE;
    EndIf;

  // - Numéro OA
    If EcranNumeroOa <> 0;
        ClauseWhere = %trimr(ClauseWhere)
                    + 'And PNUOHA = '
                    + QUOTE +  %EditC(EcranNumeroOa:STATUT_UT_CLOTURE) + QUOTE
                    + ESPACE;
    EndIf;

  // - Date Réception de.. à..
    If EcranDateReceptionDebut <> *LOVAL And EcranDateReceptionFin <> *LOVAL;
        ClauseWhere = %trimr(ClauseWhere)
                    + ' And RDTDEP BETWEEN '
                    + QUOTE + %Char(EcranDateReceptionDebut) + QUOTE
                    + ' And '
                    + QUOTE + %Char(EcranDateReceptionFin) + QUOTE;
    EndIf;

    Return ClauseWhere;
End-Proc;

///
// Sauvegarde Action UT
//
// Sauvegarde l'action sur le(s) UT(s) demandé par l'utilisateur
// On sauvegarde les valeurs suivantes dans la ds UTATraiter dim(20)
//  .Rang
//  .Numero UT
//  .Action
// On sauvegarde également le nombre d'UT à traiter
///

Dcl-Proc SauvegardeActionUT;
    Dcl-S i Zoned(4:0);

    //Réinitialisation du tableau des UT a traiter
    For i = 1 to 20;
        UTATraiter(i) = 0;
    EndFor;

    // Rang = 1;
    NombreUTATraiter = 0;
    ActionUT = *BLANKS;
    For i = 1 to NombreTotalLignesSF;
        Chain i GESTIONSFL;

        If (EcranLigneOptionUT <> *BLANKS);
            NombreUTATraiter = NombreUTATraiter + 1;
            UTATraiter(NombreUTATraiter) = EcranLigneNumeroUT;
            ActionUT = EcranLigneOptionUT;
        EndIf;
    EndFor;
End-Proc;

///
// GestionActionUtilisateur
// Vérifie si l'UT est verrouillé
// Gère les différents appels de programmes
// en fonction de l'action choisit par l'utilisateur
// -         1 - Gestion UT -> interdit user Log
// -         2 - Visualisation UT
// -         3 - Gestion constat ouverture -> interdit user Log
// -         4 - Visualisation constat ouverture -> interdit user Log
// -         5 - Gestion évènements
// -         6 - Visualisation évènements
// -         7 - Entrée dépôt -> interdit user Appro
// -         8 - Gestion contenu UT -> interdit Appro
// -         9 - Visualisation contenu UT
// -         I - Impression des lignes
// -         R - Impression détaillée des lignes
//
///

Dcl-Proc GestionActionUtilisateur;

    Dcl-S Mode Char(13);
    Dcl-C CODEVERBEKGDP100CL 'GEN';
    Dcl-C CODEOBJETKGDP100CL 'TRFSTO';
    Dcl-C LIBELLEACTIONKGDP100CL 'Transf. stock sur dépôt palett';

    Dcl-C CODEVERBERAUP200CL 'AJT';
    Dcl-C CODEOBJETRAUP200CL 'DRAFAC';
    Dcl-C LIBELLEACTIONRAUP200CL 'Achats aux U.T.  : affecter';

    Dcl-S VerrouUT ind inz(*Off);
    Dcl-S UtVerrouillee Packed(7:0) Inz(*BLANKS);
    Dcl-S UtilisateurVerrou Like(psds.User) Inz(*BLANKS);
    Dcl-S i packed(2:0);


    Dcl-S ReturnOperationEffectuee Char(1);
    Dcl-C CODE_ACTION_GESTION_UT '1';
    Dcl-C CODE_ACTION_VISU_UT '2';
    Dcl-C CODE_ACTION_GEST_CONTENU '3';
    Dcl-C CODE_ACTION_VISU_CONTENU '4';
    Dcl-C CODE_ACTION_GEST_EVT '5';
    Dcl-C CODE_ACTION_VISU_EVT '6';
    Dcl-C CODE_ACTION_ENTREE_DEPOT '7';
    Dcl-C CODE_ACTION_GEST_CONSTAT_OUVERTURE '8';
    Dcl-C CODE_ACTION_VISU_CONSTAT_OUVERTURE '9';
    Dcl-C CODE_ACTION_IMPRESSION 'R';
    Dcl-C CODE_ACTION_IMPRESSION_DETAIL 'D';
    Dcl-C CODE_ACTION_RATTACHEMENT_FACTURE_ACHAT 'F';
    Dcl-C QUOTE '''';
    Dcl-S CodeVerbePGM Char(4);
    Dcl-S CodeObjetPGM Char(6);
    Dcl-S LibelleActionPGM Char(30);
    Dcl-S ImpressionDetail Char(1);

    // Gestion des verrouillages
    //Déverrouillage des UT de l'utilisateur s'il y en a
    Exec SQL
        DELETE FROM KUTF30 WHERE Utilisateur = :psds.User;
    GestionErreurSQL();

    // En fonction de l'action choisie,
    // Vérification si les UT ne sont pas verrouillées par un autre utilisateur
    // S'il ne l'est pas, on verrouille l'UT
    If (ActionUT = CODE_ACTION_GESTION_UT
    OR ActionUT = CODE_ACTION_GEST_CONTENU
    OR ActionUT = CODE_ACTION_GEST_EVT
    OR ActionUT = CODE_ACTION_ENTREE_DEPOT
    OR ActionUT = CODE_ACTION_GEST_CONSTAT_OUVERTURE
    OR ActionUT = CODE_ACTION_IMPRESSION
    OR ActionUT = CODE_ACTION_RATTACHEMENT_FACTURE_ACHAT);
        For i = 1 to NombreUTATraiter;
            If UTATraiter(i) <> 0;
                //Verification si l'UT est verrouillé
                UtilisateurVerrou = VerificationLockUT(UTATraiter(i));
                If UtilisateurVerrou <> *BLANKS;
                    UtVerrouillee = UTATraiter(i);
                    VerrouUT = *On;

                    ECRAN2MESSAGEERREUR =
                    'UT '+ %char(UtVerrouillee) + ' bloqué par ' + UtilisateurVerrou;
                    Indicateur.MasquerMessageErreurEcran2 = *Off;
                    Write GESTIONBAS;
                EndIf;
            EndIf;
        endfor;
    EndIf;


    If not VerrouUT;
        //Verrouillage des UT
        For i = 1 to NombreUTATraiter;
            VerrouillageUT(UTATraiter(i):ActionUT);
        EndFor;

        //Gestion des actions
        Select;
            // 1 - Modification UT
            when (ActionUT = CODE_ACTION_GESTION_UT
            And (£CodeObjet = CODEOBJETAPPRO Or £CodeObjet = CODEOBJETREV));

                Mode = MODIFICATION;
                KUTP31(UTATraiter(1):Mode:EcranCodeSociete:ReturnOperationEffectuee);

                //Gestion si une opération a été effectuée, affichage du message d'information
                If ( ReturnOperationEffectuee = 'M'
                    OR ReturnOperationEffectuee = 'S');

                    //Affichage du message d'information
                    Ecran2MessageInfo = ' UT: ' + %Char(UTATraiter(1));
                    Select;
                        when (ReturnOperationEffectuee = 'M');
                            Ecran2MessageInfo = %trimr(Ecran2MessageInfo) + ' modifié avec succès';
                        when (ReturnOperationEffectuee = 'S');
                            Ecran2MessageInfo = %trimr(Ecran2MessageInfo) + ' supprimé avec succès';

                        other;
                    // handle other conditions
                    EndSl;

                    Indicateur.MasquerMessageInfoEcran2 = *Off;
                    Write GESTIONBAS;
                EndIf;

            // 2 - Visualisation UT
            when (ActionUT = CODE_ACTION_VISU_UT);
                Mode = VISUALISATION;
                KUTP31(UTATraiter(1):Mode:EcranCodeSociete:ReturnOperationEffectuee);

            // 3 - Gestion contenu UT :
            when (ActionUT = CODE_ACTION_GEST_CONTENU And £CodeObjet = CODEOBJETAPPRO);
                Mode = CreationOuModification(UTATraiter(1):EcranCodeSociete);
                KUTP36(UTATraiter(1):Mode:EcranCodeSociete:ReturnOperationEffectuee);

            // 4 - Visualisation contenu UT
            when (ActionUT = CODE_ACTION_VISU_CONTENU And £CodeObjet = CODEOBJETAPPRO);
                Mode = VISUALISATION;
                KUTP36(UTATraiter(1):Mode:EcranCodeSociete:ReturnOperationEffectuee);

            // 5 - Gestion MONO évènement
            when (ActionUT = CODE_ACTION_GEST_EVT And NombreUTATraiter = 1
            And (£CodeObjet = CODEOBJETAPPRO OR £CodeObjet = CODEOBJETLOG));
                Mode = MODIFICATION;
                KUTP32(UTATraiter(1):Mode:EcranCodeSociete:ReturnOperationEffectuee);

            // 5 - Gestion MULTI évènements
            when (ActionUT = CODE_ACTION_GEST_EVT And NombreUTATraiter > 1
            And (£CodeObjet = CODEOBJETAPPRO OR £CodeObjet = CODEOBJETLOG));
                KUTP33(UTATraiter:EcranCodeSociete:MODIFICATION:ReturnOperationEffectuee);

            // 6 - Visualisation MONO évènement
            when (ActionUT = CODE_ACTION_VISU_EVT And NombreUTATraiter = 1);
                Mode = VISUALISATION;
                KUTP32(UTATraiter(1):Mode:EcranCodeSociete:ReturnOperationEffectuee);

            // 6 - Visualisation MULTI évènements
            when (ActionUT = CODE_ACTION_VISU_EVT And NombreUTATraiter > 1);
                KUTP33(UTATraiter:EcranCodeSociete:VISUALISATION:ReturnOperationEffectuee);

            // 7 - Entrée dépôt
            when (ActionUT = CODE_ACTION_ENTREE_DEPOT And £CodeObjet = CODEOBJETLOG);

                CodeVerbePGM = CODEVERBEKGDP100CL;
                CodeObjetPGM = CODEOBJETKGDP100CL;
                LibelleActionPGM = LIBELLEACTIONKGDP100CL;

                KGDP100CL(CodeVerbePGM:CodeObjetPGM:LibelleActionPGM);

            // 8 - Gestion constat ouverture
            when (ActionUT = CODE_ACTION_GEST_CONSTAT_OUVERTURE And £CodeObjet = CODEOBJETLOG);
                Mode = CreationOuModification(UTATraiter(1):EcranCodeSociete);
                KUTP34(UTATraiter(1):Mode:EcranCodeSociete:ReturnOperationEffectuee);

            // 9 - Visualisation constat ouverture
            when (ActionUT = CODE_ACTION_VISU_CONSTAT_OUVERTURE);
                Mode = VISUALISATION;
                KUTP34(UTATraiter(1):Mode:EcranCodeSociete:ReturnOperationEffectuee);

            // R - Impression des UT sélectionnées pas un 'R'
            when (ActionUT = CODE_ACTION_IMPRESSION);
                ImpressionDetail = 'N';
                ImpressionUT(UTATraiter:ImpressionDetail);
                Ecran2MessageInfo = 'impression effectuée';
                Indicateur.MasquerMessageInfoEcran2 = *Off;
                Write GESTIONBAS;

            // D - Impression détaillée des UT sélectionnées par un 'D'
            when (ActionUT = CODE_ACTION_IMPRESSION_DETAIL);
                ImpressionDetail = 'O';
                ImpressionUT(UTATraiter:ImpressionDetail);
                Ecran2MessageInfo = 'impression effectuée';
                Indicateur.MasquerMessageInfoEcran2 = *Off;
                Write GESTIONBAS;

            // F = Rattachement facture/achat
            when (ActionUT = CODE_ACTION_RATTACHEMENT_FACTURE_ACHAT And £CodeObjet = CODEOBJETREV);

                CodeVerbePGM = CODEVERBERAUP200CL;
                CodeObjetPGM = CODEOBJETRAUP200CL;
                LibelleActionPGM = LIBELLEACTIONRAUP200CL;

                RAUP200CL(CodeVerbePGM:CodeObjetPGM:LibelleActionPGM);


            // Autres - Message d'erreur
            when ActionUT <> *BLANKS;
                Ecran2MessageErreur = 'Code action ' + QUOTE + ActionUT + QUOTE + ' interdit';
                Indicateur.MasquerMessageErreurEcran2 = *Off;
                Write GESTIONBAS;

            other;
            // handle other conditions
        EndSl;

        //Déverrouillage des UT
        For i = 1 to NombreUTATraiter;
            DeverrouillageUT(UTATraiter(i):ActionUT);
        EndFor;

    EndIf;
End-Proc;



///
// CreationOuModification
// Cette procédure a pour but de déterminer si le mode de gestion associé
// est est une création ou une modification si l'UT existe dans KUTFOA.
// @param Numéro Unité de transport
// @param Code société
// @return CREATION ou MODIFICATION (Retourne ERROR en cas d'erreur SQL)
///
Dcl-Proc CreationOuModification;
    Dcl-Pi *n Char(13);
        NumeroUt Packed(7:0);
        CodeSociete Char(2);
    End-Pi;

    Dcl-S ReturnMode Char(13) Inz('');
    Dcl-S NbEnregistrements Packed(5:0);


    // requête SQL pour vérifier l'existence de l'entrée dans la table KUTFOA
    exec sql
        SELECT COUNT(*) INTO :NbEnregistrements
        FROM KUTFOA
        WHERE PCOSTE = :CodeSociete AND PUTNUM = :NumeroUt
        And (PQTRCC >0 OR PQTRCR > 0 OR PQTRCD > 0);

    // Vérifier SQLCODE pour déterminer le résultat
    If SQLCODE = 0; // Des enregistrements ont été trouvé
        If NbEnregistrements > 0;
            ReturnMode = MODIFICATION;
        ElseIf NbEnregistrements = 0;
            ReturnMode = CREATION;
        EndIf;
    elseif SQLCODE = 100; // Aucun enregistrement trouvé
        ReturnMode = CREATION;
    else; //Erreur SQL
        GestionErreurSQL();
        ReturnMode = 'ERROR';
    EndIf;

    Return ReturnMode;
End-Proc;

///
// Impression de la liste des UT affichées à l'écran et sélectionnées par un "X"
//  - Réinitialisation du fichier KUTF11
//  - écriture des données sur le fichier KUTF11
//  - Appel du programme KUTP120CL
///
Dcl-Proc ImpressionUT;
    Dcl-Pi *n ;
        UTATraiter Packed(7:0) dim(20);
        detailImpression Char(1);
    End-Pi;

    Dcl-S i Zoned(2:0);
    Dcl-Ds InsertKUTF11 likeds(kutf11_t);
    Dcl-Ds WCRSEL len(256) qualified;// Reprise de KUTP1à
        ECOSTE char(2) pos(1) ;
        ECOSOR char(1) pos(3) ;

        EUTNUM  packed(7:0) pos(20);
        WTRI01  char(1) pos(27);
        WTRI02  char(1) pos(28);
        WTRI03  char(1) pos(29);
        WTRI04  char(1) pos(30);

        EDETAR  char(1) pos(40);

        EBIBLI char(10) pos(101);
        EFICHI char(10) pos(111);
        EAJREM char(1) pos(121);

        EECRAN char(10) pos(201);
        WENCHA char(1) pos(211);
        WQTEMP char(1) pos(212);

        STAR char(1) pos(256) ;
    End-Ds;
    Dcl-S CodeVerbeKUTP120CL Char(4) Inz('INT ');
    Dcl-S CodeObjetKUTP120CL Char(6) Inz('SUTLST');
    Dcl-S LibelleActionKUTP120CL Char(30) Inz('Liste des Unités Transport(UT)');
    Dcl-S USELEC char(256);
    Dcl-S USELA1 char(256) Inz(*BLANKS);
    Dcl-S USELA2 char(256) Inz(*BLANKS);



    // Réinitialisation du fichier KUTF11
    Exec Sql
         Delete KUTF11 Where TCOSTE = :ECRANCODESOCIETE;
    GestionErreurSQL();

    // Impression détail
    WCRSEL.EDETAR = detailImpression;

    // Chargement du fichier de travail pour édition à partir des lignes sélectionnées
    For i = 1 to NombreUTATraiter;
        If UTATraiter(i) <> 0;

            // Récupération des valeurs de l'UT
            InsertKUTF11 = GetKUTF11Values(UTATraiter(i));

            // Ecriture dans KUTF11
            Exec Sql
                 Insert Into KUTF11(TCOSTE,
                                    TUTNUM,
                                    TTYPUT,
                                    TLITYP,
                                    TNUMDR,
                                    TSTATU,
                                    TLISTA,
                                    TDTREC,
                                    TGESUI,
                                    TLIGES,
                                    TIDUT,
                                    TNUPLB,
                                    TCOCMA,
                                    TLICMA,
                                    TDESCR,
                                    TLIRSV,
                                    TDTARR,
                                    TNBJOU,
                                    TDTRES,
                                    TCOINT,
                                    TLIINT,
                                    TDTSAI,
                                    TNUEDR,
                                    TNUDOI,
                                    TUTTUT,
                                    TPUSUR,
                                    TDTDEP,
                                    TDTEVT,
                                    TCOIN2,
                                    TLIIN2,
                                    TDTMOD,
                                    THEMOD,
                                    TPFMOD,
                                    TTPCMS)
                      Values (:InsertKUTF11.TCOSTE,
                              :InsertKUTF11.TUTNUM,
                              :InsertKUTF11.TTYPUT,
                              :InsertKUTF11.TLITYP,
                              :InsertKUTF11.TNUMDR,
                              :InsertKUTF11.TSTATU,
                              :InsertKUTF11.TLISTA,
                              :InsertKUTF11.TDTREC,
                              :InsertKUTF11.TGESUI,
                              :InsertKUTF11.TLIGES,
                              :InsertKUTF11.TIDUT,
                              :InsertKUTF11.TNUPLB,
                              :InsertKUTF11.TCOCMA,
                              :InsertKUTF11.TLICMA,
                              :InsertKUTF11.TDESCR,
                              :InsertKUTF11.TLIRSV,
                              :InsertKUTF11.TDTARR,
                              :InsertKUTF11.TNBJOU,
                              :InsertKUTF11.TDTRES,
                              :InsertKUTF11.TCOINT,
                              :InsertKUTF11.TLIINT,
                              :InsertKUTF11.TDTSAI,
                              :InsertKUTF11.TNUEDR,
                              :InsertKUTF11.TNUDOI,
                              :InsertKUTF11.TUTTUT,
                              :InsertKUTF11.TPUSUR,
                              :InsertKUTF11.TDTDEP,
                              :InsertKUTF11.TDTEVT,
                              :InsertKUTF11.TCOIN2,
                              :InsertKUTF11.TLIIN2,
                              :InsertKUTF11.TDTCRE,
                              :InsertKUTF11.THECRE,
                              :InsertKUTF11.TPFCRE,
                              :InsertKUTF11.TTPCMS);
            GestionErreurSQL();
        EndIf;
    EndFor;

    // Appel du programme d'édition
    //  - Définition de la LDA et de ses paramètres
    WCRSEL.ECOSTE = ECRANCODESOCIETE;
    WCRSEL.ECOSOR = '2';
    WCRSEL.EECRAN = psds.JobName;
    WCRSEL.WQTEMP = 'O';
    WCRSEL.STAR = '*';
    USELEC = WCRSEL ;
    USELA1 = *BLANKS ;
    USELA2 = *BLANKS ;

    // - Appel du prog KUTP120CL
    KUTP120CL(CodeVerbeKUTP120CL:CodeObjetKUTP120CL:LibelleActionKUTP120CL:USELEC:USELA1:USELA2);

End-Proc;


///
// GetKUTF11Values
// Récupère les informations de l'UT pour compléter le fichier KUTF11
// @param numéro UT
// @return KUTF11_t
///
Dcl-Proc GetKUTF11Values;
    Dcl-Pi *n likeDs(kutf11_t);
        NumeroUt Packed(7:0);
    End-Pi;

    Dcl-Ds ReturnKUTF11 likeDs(kutf11_t);

    ReturnKUTF11.TCOSTE = ECRANCODESOCIETE;
    ReturnKUTF11.TUTNUM = NumeroUt;

    // Récupération des informations de l'UT
    Exec Sql
         Select RTYPUT,
                RNUMDR,
                RSTATU,
                RDTREC,
                RGESUI,
                RIDUT,
                RNUPLB,
                RCOCMA,
                RDESCR,
                RLIRSV,
                RDTARR,
                RNBJOU,
                RDTRES,
                RCOINT,
                RDTSAI,
                RNUEDR,
                RNUDOI,
                RUTTUT,
                RPUSUR,
                RDTDEP
              Into :ReturnKUTF11.TTYPUT,
                   :ReturnKUTF11.TNUMDR,
                   :ReturnKUTF11.TSTATU,
                   :ReturnKUTF11.TDTREC,
                   :ReturnKUTF11.TGESUI,
                   :ReturnKUTF11.TIDUT,
                   :ReturnKUTF11.TNUPLB,
                   :ReturnKUTF11.TCOCMA,
                   :ReturnKUTF11.TDESCR,
                   :ReturnKUTF11.TLIRSV,
                   :ReturnKUTF11.TDTARR,
                   :ReturnKUTF11.TNBJOU,
                   :ReturnKUTF11.TDTRES,
                   :ReturnKUTF11.TCOINT,
                   :ReturnKUTF11.TDTSAI,
                   :ReturnKUTF11.TNUEDR,
                   :ReturnKUTF11.TNUDOI,
                   :ReturnKUTF11.TUTTUT,
                   :ReturnKUTF11.TPUSUR,
                   :ReturnKUTF11.TDTDEP
              From RUTFEN
              Where RNUMUT = :NumeroUt ;
    GestionErreurSQL();


    ReturnKUTF11.TLITYP = GetLibelleTypeUT(ReturnKUTF11.TTYPUT);
    ReturnKUTF11.TLISTA = GetLibelleStatutUTRevient(ReturnKUTF11.TSTATU);
    ReturnKUTF11.TLIGES = GetLibelleStatutUT(ReturnKUTF11.TGESUI);
    ReturnKUTF11.TLICMA = GetLibelleCompagnie(ReturnKUTF11.TCOCMA);
    If ReturnKUTF11.TLIINT <> *BLANKS;
        ReturnKUTF11.TLIINT= GetLibelleIntervenant(ReturnKUTF11.TCOINT);
    EndIf;



    //Récupération des informations du dernier évènement de l'UT
    Exec Sql
        Select  QDTEVT,
                QCOINT
        Into    :ReturnKUTF11.TDTEVT,
                :ReturnKUTF11.TCOIN2
        From    KUTFEV
        Where   QUTNUM = :NumeroUt And
                QEVERX = :ReturnKUTF11.TGESUI
        Order by QNUEVT desc
        FETCH FIRST ROW ONLY;

    If SqlCode = 0;
        If ReturnKUTF11.TCOIN2 <> *BLANKS;
            ReturnKUTF11.TLIIN2 = GetLibelleIntervenant(ReturnKUTF11.TCOIN2);
        EndIf;
    ElseIf SqlCode = 100;
        ReturnKUTF11.TDTEVT =  %date('1940-01-01': *iso);
    Else;
        GestionErreurSQL();
    EndIf;



    ReturnKUTF11.TDTCRE = %date();
    ReturnKUTF11.THECRE = %time();
    ReturnKUTF11.TPFCRE = psds.User;

    // ReturnKUTF11.TDTMOD,  /* TDTMOD  DATE           Date modification             */
    // ReturnKUTF11.THEMOD,  /* THEMOD  TIME           Heure modification            */
    // ReturnKUTF11.TPFMOD,  /* TPFMOD  CHARACTER(10)  Profil modification           */

    ReturnKUTF11.TTPCMS = 'C';

    Return ReturnKUTF11;
End-Proc;

///
// Verification du verrouillage d'une UT
// Permet de vérifier si une UT est déjà verrouillé par un autre utilisateur
// @param: NumeroUT
// @return: Nom de l'utilisateur qui verrouille l'UT. Renvoi *BLANKS si pas de blocage
///
Dcl-Proc VerificationLockUT;
    Dcl-Pi *n Char(10);
        PARAM_NumeroUT Packed(7:0);
    End-Pi;

    Dcl-S UtilisateurVerrou Like(psds.User);

    // Vérification si l'UT n'est pas déjà en cours d'utilisation
    Exec SQL
    Select Utilisateur
    Into :UtilisateurVerrou
    From KUTF30
    Where NumeroUT = :PARAM_NumeroUT And LockFlag = '1';

    If (SqlCode = 100); // Pas de résultat trouvé
        UtilisateurVerrou = *BLANKS; // L'UT n'est pas verrouillée
    ElseIf (SqlCode = 0); // Résultat trouvé

    Else;//Erreur SQL
        GestionErreurSQL();
    EndIf;

    Return UtilisateurVerrou;
End-Proc;


///
// VerrouillageUT
// Ecrit dans la table KUTF30 pour le verrouillage de l'UT
// On vérifie si le couple NumeroUT/Utilisateur existe déjà, s'il existe c'est un update
// Sinon c'est un insert INTO
// @Param NumeroUT
// @Param CodeAction
///
Dcl-Proc VerrouillageUT;
    Dcl-Pi *n ;
        PARAM_NumeroUT packed(7:0);
        PARAM_CodeAction Char(1);
    End-Pi;
    Dcl-Ds KUTF30Ds Qualified;
        NumeroUT        Packed(7:0);
        UserID          Varchar(10);
        StartTimestamp  Timestamp;
        EndTimestamp    Timestamp;
        CodeAction      Varchar(1);
        LockFlag        Char(1);
    End-Ds;

    Dcl-S EnregistrementExistant Packed(1:0);

    KUTF30Ds.NumeroUT = PARAM_NumeroUT;
    KUTF30Ds.UserID = psds.user;
    KUTF30Ds.STARTTIMESTAMP = %timestamp();
    KUTF30Ds.CodeAction = PARAM_CodeAction;
    KUTF30Ds.LOCKFLAG = '1';

    Exec SQL
        SELECT COUNT(*)
        INTO :EnregistrementExistant
        FROM KUTF30
        WHERE NumeroUT = :KUTF30Ds.NumeroUT AND Utilisateur = :KUTF30Ds.UserID;

    If (EnregistrementExistant = 0 );
    // Insertion dans la table
        Exec SQL
                INSERT INTO KUTF30
                (
                    NumeroUT,
                    Utilisateur,
                    StartTimestamp,
                    CodeAction,
                    LockFlag
                    )
                    VALUES
                (
                    :KUTF30Ds.NumeroUT,
                    :KUTF30Ds.UserID,
                    :KUTF30Ds.StartTimestamp,
                    :KUTF30Ds.CodeAction,
                    :KUTF30Ds.LockFlag
                    );
        GestionErreurSQL();
    Else;
        Exec SQL
            UPDATE KUTF30
            SET StartTimestamp = :KUTF30Ds.StartTimestamp,
                EndTimestamp = null,
                LockFlag = :KUTF30Ds.LockFlag
            WHERE NumeroUT = :KUTF30Ds.NumeroUT AND Utilisateur = :KUTF30Ds.UserID;
        GestionErreurSQL();
    EndIf;
End-Proc;

///
// DeverrouillageUT
// Ecrit dans la table KUTF30 pour le verrouillage de l'UT
// @Param NumeroUT
// @Param CodeAction
///
Dcl-Proc DeverrouillageUT;
    Dcl-Pi *n ;
        PARAM_NumeroUT packed(7:0);
        PARAM_CodeAction Char(1);
    End-Pi;
    Dcl-Ds KUTF30Ds Qualified;
        NumeroUT        Packed(7:0);
        UserID          Varchar(10);
        StartTimestamp  Timestamp;
        EndTimestamp    Timestamp;
        CodeAction      Varchar(1);
        LockFlag        Char(1);
    End-Ds;

    KUTF30Ds.EndTimestamp = %timestamp();
    KUTF30Ds.LOCKFLAG = '0';

   // Exécuter la mise à jour
    Exec SQL
    UPDATE KUTF30
    SET EndTimestamp = :KUTF30Ds.EndTimestamp,
        LockFlag = :KUTF30Ds.LOCKFLAG
    WHERE NumeroUT = :PARAM_NumeroUT
    And CodeAction = :PARAM_CodeAction
    And Utilisateur = :psds.User;
    GestionErreurSQL();
End-Proc;



// #region programmes de services
// ----------------------------------------------------------------------------
//
//                                 SERVICES
//                  Réutilisable dans d'autres programmes
//
// -----------------------------------------------------------------------------


//                                  QSYS2API

///
// Vérification de l'existance d'une table
// Vérifie si une table existe, si elle existe, renvoi *On
//
// @param Bibliotheque de Fichier (FIDVALSXX)
// @param Fichier à tester
// @return *On si existe, *Off si n'existe pas
///

Dcl-Proc VerificationExistanceTable;
    Dcl-Pi *N Ind;
        BibliothequeFichier Char(9);
        NomTable Char(10);
    End-Pi;

    Dcl-S Table_exists ind;

    Table_exists = *Off;

  // Vérification existance de la table
    exec sql
        select count(*)
        into :Table_exists
        from qsys2.systables
        where name = :NomTable
        and table_schema = :BibliothequeFichier;
    GestionErreurSQL();

    Return Table_exists;
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


///
// Création user index
// Vérification si le user index n'est pas déjà créé et s'il ne l'est pas, on le créé
// 50 variables du DSPF MAX. Variable de 80 de long : 30 NomVariable + 50 Valeur
///

Dcl-Proc CreationUserIndex ;
    Dcl-Pi *N;
        NomDuProgramme Char(10);
        BibliothequeFichier Char(9);
    End-Pi;

    Dcl-S UserIndexExists Packed(1:0);

  // Création du UserIndex s'il n'existe pas
    Exec Sql
         Select COALESCE(1, 0)
              Into :UserIndexExists
              From QSYS2.USER_INDEX_INFO
              Where USER_INDEX = :NomDuProgramme And
                    USER_INDEX_LIBRARY = :BibliothequeFichier;
  // Le user index n'existe pas
    If UserIndexExists = 0;
        Exec Sql
         // USER_INDEX => Programme (ex : KPBP10)
         // USER_INDEX_LIBRARY => Environnement (ex : FIDVALSAC)
         // KEY => Utilisateur (ex : GCHMINF4) quand on fait des entrées.
         // ENTRY => Les variables du DSPF, on peut aller jusqu'à 50 variables.
         // 50 variables de 80 de long : 30 NomVariable + 50 Valeur
         // donc longueur 4000 au total (voir Ds DSPFSauve)
         Call QSYS2.CREATE_USER_INDEX(
            USER_INDEX => :NomDuProgramme,
            USER_INDEX_LIBRARY => :BibliothequeFichier,
            ENTRY_TYPE => 'VARIABLE',
            MAXIMUM_ENTRY_LENGTH => 4000,
            KEY_LENGTH => 10,
            Replace => 'NO',
            IMMEDIATE_UPDATE => 'YES',
            TEXT_DESCRIPTION =>'Parametres du PGM KUTP30 pour init du DSPF',
            PUBLIC_AUTHORITY => '*USE');
        GestionErreurSQL() ;
    EndIf;
End-Proc;


///
// Récupération des valeurs User Index
// Récupération des valeurs du User Index pour initialiser les variables du DSPF
///

Dcl-Proc GetValeursUserIndex ;
    Dcl-Pi *N Char(4000);
        NomDuProgramme Char(10);
        BibliothequeFichier Char(9);
        Utilisateur Char(10);
    End-Pi;

    Dcl-S DSPFSauveTotaliteReturn Char(4000);

    Exec Sql
         Select ENTRY
              Into :DSPFSauveTotaliteReturn
              From Table(
                QSYS2.USER_INDEX_ENTRIES(
                USER_INDEX_LIBRARY => :BibliothequeFichier,
                USER_INDEX =>:NomDuProgramme
                ))
              Where Key = :Utilisateur ;
    GestionErreurSQL();

    Return DSPFSauveTotaliteReturn;
End-Proc;


///
// Sauvegarde des saisies utilisateurs
// Permet d'insérer dans le user index, les saisies du DSPF de l'utilisateur
///

Dcl-Proc PutValeursUserIndex ;
    Dcl-Pi *N;
        DSPFSauveTotalite Char(4000);
        NomDuProgramme Char(10);
        BibliothequeFichier Char(9);
        Utilisateur Char(10);
    End-Pi;

    Exec Sql
         Call QSYS2.ADD_USER_INDEX_ENTRY(USER_INDEX_LIBRARY => :BibliothequeFichier,
                                         USER_INDEX => :NomDuProgramme,
                                         Replace => 'YES',
                                         ENTRY => :DSPFSauveTotalite,
                                         Key => :Utilisateur) ;
    GestionErreurSQL() ;
End-Proc;


///
// ExecCL
// Execute une commande CL
//
// @param Commande
///

Dcl-Proc ExecCL Export;
    Dcl-Pi *N;
        CommandeCL        VarChar(200);
    End-Pi;

    QCMDEXC(CommandeCL : %Len(CommandeCL));
End-Proc;


//                                  RECHERCHE (F4)

///
// Recherche Code société
// Recherche F4 sur le code société
///

Dcl-Proc RechercheF4CodeSociete ;
    Dcl-Pi *N likeDs(RechercheF4_t);
    End-Pi;

    Dcl-Ds RechercheF4 likeds(RechercheF4_t);
    Dcl-C TABLE_CHARTREUSE_SOCIETE 'STE';

    RechercheF4.CodeRacine = TABLE_CHARTREUSE_SOCIETE;
    RechercheF4.Position      = 1;
    RechercheF4.NumeroContenu = 1;
    RechercheF4.CodeRetour    = '0';
    RechercheF4.Argument      = *BLANKS;
    RechercheF4.Libelle       = *BLANKS;

    PR_VORPAR(
            RechercheF4.CodeRacine
            :RechercheF4.Position
            :RechercheF4.NumeroContenu
            :RechercheF4.CodeRetour
            :RechercheF4.Argument
            :RechercheF4.Libelle);

    Return RechercheF4;
End-Proc;


///
// Recherche Code Compagnie
// Recherche F4 sur le code Compagnie
///

Dcl-Proc RechercheF4CodeCompagnie ;
    Dcl-Pi *N likeDs(RechercheF4_t);
    End-Pi;

    Dcl-Ds RechercheF4 likeds(RechercheF4_t);
    Dcl-C TABLE_CHARTREUSE_COMPAGNIE 'XCOCMA';

    RechercheF4.CodeRacine = TABLE_CHARTREUSE_COMPAGNIE;
    RechercheF4.Position      = 1;
    RechercheF4.NumeroContenu = 1;
    RechercheF4.CodeRetour    = '0';
    RechercheF4.Argument      = *BLANKS;
    RechercheF4.Libelle       = *BLANKS;

    PR_VORPAR(
            RechercheF4.CodeRacine
            :RechercheF4.Position
            :RechercheF4.NumeroContenu
            :RechercheF4.CodeRetour
            :RechercheF4.Argument
            :RechercheF4.Libelle);

    Return RechercheF4;
End-Proc;


///
// Recherche Intervenant
// Recherche F4 sur le code Intervenant
///

Dcl-Proc RechercheF4Intervenant ;
    Dcl-Pi *N likeDs(RechercheF4_t);
    End-Pi;

    Dcl-Ds RechercheF4 likeds(RechercheF4_t);
    Dcl-C TABLE_CHARTREUSE_INTERVENANTS 'XUTSIN';

    RechercheF4.CodeRacine = TABLE_CHARTREUSE_INTERVENANTS;
    RechercheF4.Position      = 1;
    RechercheF4.NumeroContenu = 1;
    RechercheF4.CodeRetour    = '0';
    RechercheF4.Argument      = *BLANKS;
    RechercheF4.Libelle       = *BLANKS;

    PR_VORPAR(
            RechercheF4.CodeRacine
            :RechercheF4.Position
            :RechercheF4.NumeroContenu
            :RechercheF4.CodeRetour
            :RechercheF4.Argument
            :RechercheF4.Libelle);

    Return RechercheF4;
End-Proc;


///
// Recherche Statut UT
// Recherche F4 sur le code statut des unités de transport
///

Dcl-Proc RechercheF4StatutUT ;
    Dcl-Pi *N likeDs(RechercheF4_t);
    End-Pi;

    Dcl-Ds RechercheF4 likeds(RechercheF4_t);
    Dcl-C TABLE_CHARTREUSE_STATUTUT 'XUTSST';

    RechercheF4.CodeRacine = TABLE_CHARTREUSE_STATUTUT;
    RechercheF4.Position      = 1;
    RechercheF4.NumeroContenu = 1;
    RechercheF4.CodeRetour    = '0';
    RechercheF4.Argument      = *BLANKS;
    RechercheF4.Libelle       = *BLANKS;

    PR_VORPAR(
            RechercheF4.CodeRacine
            :RechercheF4.Position
            :RechercheF4.NumeroContenu
            :RechercheF4.CodeRetour
            :RechercheF4.Argument
            :RechercheF4.Libelle);

    Return RechercheF4;
End-Proc;

///
// Recherche Statut Revient
// Recherche F4 sur le code statut des revient
///

Dcl-Proc RechercheF4StatutRevient ;
    Dcl-Pi *N likeDs(RechercheF4_t);
    End-Pi;

    Dcl-Ds RechercheF4 likeds(RechercheF4_t);
    Dcl-C TABLE_CHARTREUSE_STATUTUT 'XUTSTT';

    RechercheF4.CodeRacine = TABLE_CHARTREUSE_STATUTUT;
    RechercheF4.Position      = 1;
    RechercheF4.NumeroContenu = 1;
    RechercheF4.CodeRetour    = '0';
    RechercheF4.Argument      = *BLANKS;
    RechercheF4.Libelle       = *BLANKS;

    PR_VORPAR(
            RechercheF4.CodeRacine
            :RechercheF4.Position
            :RechercheF4.NumeroContenu
            :RechercheF4.CodeRetour
            :RechercheF4.Argument
            :RechercheF4.Libelle);

    Return RechercheF4;
End-Proc;


///
// Recherche Type d'UT
// Recherche F4 sur le Type d'UT
///

Dcl-Proc RechercheF4TypeUT ;
    Dcl-Pi *N likeDs(RechercheF4_t);
    End-Pi;

    Dcl-Ds RechercheF4 likeds(RechercheF4_t);
    Dcl-C TABLE_CHARTREUSE_TYPETUT 'XUTTYP';

    RechercheF4.CodeRacine = TABLE_CHARTREUSE_TYPETUT;
    RechercheF4.Position      = 1;
    RechercheF4.NumeroContenu = 1;
    RechercheF4.CodeRetour    = '0';
    RechercheF4.Argument      = *BLANKS;
    RechercheF4.Libelle       = *BLANKS;

    PR_VORPAR(
            RechercheF4.CodeRacine
            :RechercheF4.Position
            :RechercheF4.NumeroContenu
            :RechercheF4.CodeRetour
            :RechercheF4.Argument
            :RechercheF4.Libelle);

    Return RechercheF4;
End-Proc;


///
// Recherche NomBateau
// Recherche F4 sur le NomBateau
///

Dcl-Proc RechercheF4NomBateau ;
    Dcl-Pi *N likeDs(RechercheF4_t);
    End-Pi;

    Dcl-Ds RechercheF4 likeds(RechercheF4_t);
    Dcl-C TABLE_CHARTREUSE_TYPETUT 'XUTBAT';

    RechercheF4.CodeRacine = TABLE_CHARTREUSE_TYPETUT;
    RechercheF4.Position      = 1;
    RechercheF4.NumeroContenu = 1;
    RechercheF4.CodeRetour    = '0';
    RechercheF4.Argument      = *BLANKS;
    RechercheF4.Libelle       = *BLANKS;

    PR_VORPAR(
            RechercheF4.CodeRacine
            :RechercheF4.Position
            :RechercheF4.NumeroContenu
            :RechercheF4.CodeRetour
            :RechercheF4.Argument
            :RechercheF4.Libelle);

    Return RechercheF4;
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


//                              Table valeur chartreuse

///
// GET libellé intervenant
// La procédure renvoi le libellé de l'intervenant en fonction de son code
// TABVV : XUTSIN : S. Suivi des UT : intervenants
//
// @param Code de l'intervenant
// @return Libellé de l'intervenant si erreur renvoi *ALL'?'
///

Dcl-Proc GetLibelleIntervenant ;
    Dcl-Pi *n Char(30);
        CodeIntervenant Char(3);
    End-Pi;

    Dcl-S LibelleTransporteurReturn Char(30);
    Dcl-C TABLE_CHARTREUSE_INTERVENANTS 'XUTSIN';

    Exec Sql
                Select SUBSTR(XLIPAR, 1, 30)
                    Into :LibelleTransporteurReturn
                    From VPARAM
                    Where XCORAC LIKE :TABLE_CHARTREUSE_INTERVENANTS
                    And XCOARG = :CodeIntervenant;
    If SQLCode <> 0;
        GestionErreurSQL();
        LibelleTransporteurReturn = *ALL'?';
    EndIf;

    Return LibelleTransporteurReturn;

End-Proc;


///
// GET libellé compagnie
// La procédure renvoie le libellé de la compagnie maritime en fonction de son code
// TABVV : XCOCMA : (G) S. Compagnies Maritimes
//
// @param Code de la compagnie
// @return Libellé de la compagnie si erreur renvoi *ALL'?'
///

Dcl-Proc GetLibelleCompagnie ;
    Dcl-Pi *n Char(20);
        CodeCompagnie Char(3);
    End-Pi;

    Dcl-S LibelleCompagnieReturn Char(20);
    Dcl-C TABLE_CHARTREUSE_COMPAGNIE 'XCOCMA';

    Exec Sql
                Select SUBSTR(XLIPAR, 1, 20)
                    Into :LibelleCompagnieReturn
                    From VPARAM
                    Where XCORAC LIKE :TABLE_CHARTREUSE_COMPAGNIE
                    And XCOARG = :CodeCompagnie;
    If SQLCode <> 0;
        GestionErreurSQL();
        LibelleCompagnieReturn = *ALL'?';
    EndIf;

    Return LibelleCompagnieReturn;

End-Proc;


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
// GET Libellé Statut UT
// La procédure renvoi le statut de l'UT en fonction de son code
// TABVV : XUTSST
//
// @param Code du statut de l'UT
// @return Libellé du statut de l'UT si erreur renvoi *ALL'?'
///

Dcl-Proc GetLibelleStatutUT ;
    Dcl-Pi *n Char(30);
        CodeStatutUT Char(1);
    End-Pi;

    Dcl-S LibelleStatutUTReturn Char(30);
    Dcl-C TABLE_CHARTREUSE_STATUTUT 'XUTSST';


    Exec SQL
            Select SUBSTR(XLIPAR, 1, 30)
                Into :LibelleStatutUTReturn
                FROM VPARAM
                WHERE XCORAC = :TABLE_CHARTREUSE_STATUTUT
                    AND XCOARG = :CodeStatutUT;
    If SQLCode <> 0;
        GestionErreurSQL();
        LibelleStatutUTReturn = *ALL'?';
    EndIf;

    Return LibelleStatutUTReturn;

End-Proc;


///
// GET Libellé Type UT
// La procédure renvoi le Type de l'UT en fonction de son code
// TABVV : XUTTYP
//
// @param Code du Type de l'UT
// @return Libellé du Type de l'UT si erreur renvoi *ALL'?'
///

Dcl-Proc GetLibelleTypeUT ;
    Dcl-Pi *n Char(20);
        CodeTypeUT Char(5);
    End-Pi;

    Dcl-S LibelleTypeUTReturn Char(20);
    Dcl-C TABLE_CHARTREUSE_TYPETUT 'XUTTYP';

    Exec SQL
            Select SUBSTR(XLIPAR, 1, 30)
                Into :LibelleTypeUTReturn
                FROM VPARAM
                WHERE XCORAC = :TABLE_CHARTREUSE_TYPETUT
                    AND XCOARG = :CodeTypeUT;
    If SQLCode <> 0;
        GestionErreurSQL();
        LibelleTypeUTReturn = *ALL'?';
    EndIf;

    Return LibelleTypeUTReturn;

End-Proc;


///
// GET Libellé BATEAU
// La procédure renvoi le nom du BATEAU en fonction de son code
// TABVV : XUTBAT
//
// @param Code du bateau
// @return Libellé du bateau si erreur renvoi *ALL'?'
///

Dcl-Proc GetLibelleBateau ;
    Dcl-Pi *n Char(30);
        CodeBateau Char(3);
    End-Pi;

    Dcl-S LibelleBateauReturn Char(30);
    Dcl-C TABLE_CHARTREUSE_BATEAUUT 'XUTBAT';

    Exec SQL
            Select SUBSTR(XLIPAR, 1, 30)
                Into :LibelleBateauReturn
                FROM VPARAM
                WHERE XCORAC = :TABLE_CHARTREUSE_BATEAUUT
                    AND XCOARG = :CodeBateau;
    If SQLCode <> 0;
        GestionErreurSQL();
        LibelleBateauReturn = *ALL'?';
    EndIf;

    Return LibelleBateauReturn;

End-Proc;

///
// GET Libellé Statut UT Revient
// La procédure renvoi le statut de l'UT APPRO en fonction de son code
// TABVV : XUTSTT
//
// @param Code du statut de l'UT
// @return Libellé du statut de l'UT si erreur renvoi *ALL'?'
///

Dcl-Proc GetLibelleStatutUTRevient ;
    Dcl-Pi *n Char(20);
        CodeStatutUT Char(1);
    End-Pi;

    Dcl-S LibelleStatutUTReturn Char(20);
    Dcl-C TABLE_CHARTREUSE_STATUTUT 'XUTSTT';

    Exec SQL
            Select SUBSTR(XLIPAR, 1, 20)
                Into :LibelleStatutUTReturn
                FROM VPARAM
                WHERE XCORAC = :TABLE_CHARTREUSE_STATUTUT
                    AND XCOARG = :CodeStatutUT;
    If SQLCode <> 0;
        GestionErreurSQL();
        LibelleStatutUTReturn = *ALL'?';
    EndIf;

    Return LibelleStatutUTReturn;

End-Proc;
