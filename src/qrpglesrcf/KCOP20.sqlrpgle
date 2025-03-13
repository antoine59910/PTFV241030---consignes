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

// --- Appels de prototypes et de leurs DS-------------------------------
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

// --- Data-structures Indicateurs--------------------------------------
Dcl-Ds Indicateur qualified;

     // FM1
    FM1_CodeSocieteInvalide                      Ind pos(30);
    FM1_DateLivraisonInvalide                        Ind pos(31);
    FM1_CodeClientInvalide                       Ind Pos(32);
    FM1_CodeRepresentantInvalide                 Ind Pos(33);
    FM1_CodeSpecifiqueInvalide                   Ind Pos(34);
    FM1_AucunCodeRenseigne                       Ind Pos(35);

     // FM2
    FM2_MSGERR_ArticleNonGereParLot              Ind Pos(30);
    FM2_MSGERR_CodeArticleInvalide               Ind Pos(31);
    FM2_MSGERR_ArticleNonGere                    Ind Pos(32);
    FM2_MSGERR_QuantiteObligatoire               Ind Pos(33);
    FM2_MSGERR_QuantiteSuperieureAuDispo         Ind Pos(34);
    FM2_MSGERR_LotManquant                       Ind Pos(35);
    FM2_MSGERR_LotInconnu                        Ind Pos(36);
    FM2_MSGERR_ElementManquant                   Ind Pos(37);
    FM2_MSGERR_ElementInconnu                    Ind Pos(38);
    FM2_MSGERR_EmplacementManquant               Ind Pos(39);
    FM2_MSGERR_EmplacementInconnu                Ind Pos(40);


    FM2_IV_CodeArticleInvalide                   Ind Pos(41);
    FM2_IV_ArticleNonGere                        Ind Pos(42);
    FM2_IV_Quantiteobligatoire                   Ind Pos(43);
    FM2_IV_QuantiteSuperieureAuDispo             Ind Pos(44);
    FM2_IV_Lot                                   Ind Pos(45);
    FM2_IV_Element                               Ind Pos(46);
    FM2_IV_Emplacement                           Ind Pos(47);

    // Sous fichier
    SousFichierDisplay                           Ind Pos(51);
    SousFichierDisplayControl                    Ind Pos(52);
    SousFichierClear                             Ind Pos(53);
    SousFichierEnd                               Ind Pos(54);

    // Affichage
    FM2_Affichage_Emplacement                    Ind Pos(61);
    FM2_Affichage_Lot                            Ind Pos(62);
    FM2_Affichage_DesignationLot                 Ind Pos(63);
    FM2_Affichage_ElementDeLot                   Ind Pos(64);

    HautBasEcran                                 Ind Pos(74);

    // Inverse Vidéo
    IVEliop1                                     Ind Pos(81);
    IVEliop2                                     Ind Pos(82);
    IVEliop3                                     Ind Pos(83);
    IVEliop4                                     Ind Pos(84);
    IVEliop5                                     Ind Pos(85);
    IVEliop6                                     Ind Pos(86);
    IVEliop7                                     Ind Pos(87);
    IVEliop8                                     Ind Pos(88);
End-Ds ;

// Constantes ---------------------------------------------------------
Dcl-C TABLE_CHARTREUSE_GESTION_DEPOT 'LST';
Dcl-C TABLE_CHARTREUSE_GESTION_PUB 'XPBPAR';
Dcl-C MAX_LIGNE_ARTICLE 50;
Dcl-C NOMBRE_RANG_PAR_PAGE 3;
Dcl-C LIGNEDEBUTSOUSFICHIER 10;//Ligne du curseur du début du sous fichier
Dcl-C NOMBREDELIGNEPARRANGSOUSFICHIER 4;//Nombre de ligne pour chaque
//enregistrement du sous fichier

// --- Data-structure système ------------------------------------------
/INCLUDE qincsrc,rpg_PSDS

// --- Data-structure sous-fichier -------------------------------------
/INCLUDE qincsrc,rpg_INFDS

// Appels de prototypes et de leurs DS
/DEFINE PR_AFENCL   // Gestion de la fenêtre utilisateur (F2)
/DEFINE PR_GoASER   // Gestion de la fenêtre de services (F6)
/DEFINE PR_GoAFENCL // Appel de la fenetre utilisateur
/DEFINE PR_RMRBACI  // Constitue la barre d'action
/DEFINE PR_VMIART   // Interrogation des articles par F4
/DEFINE PR_VMRADS   // Récupération de l'adresse de la société
/DEFINE PR_VMRCLM   // Recherche client
/DEFINE PR_VMRICL   // Récupération des données client
/DEFINE PR_VMRNMV   // Numérotation des mouvements de stock
/DEFINE PR_VMRPXR   // récupération du prix unit de l'article +
                    // calcul du montant de la ligne
/DEFINE PR_VMRREP   // Récupération du libellé représentant
/DEFINE PR_VMTADP   // Permet de savoir si l'article est géré dans le dépôt
/DEFINE PR_VMTAR1   // Verif art existe + récup infos
                    // (libellé, unité de gestion, ...)
/DEFINE PR_VMTDEP   // permet la Récupération du nom du dépôt
/DEFINE PR_VMTSTE   // récupération du libellé de la société
/DEFINE PR_VMTSTP   // Permet de savoir si la quantité en stock est suffisante
/DEFINE PR_VoRPAR   // Récup données société
/DEFINE PR_VVRCLI   // Récup libellé client
/DEFINE PR_VSIEMP   // interrogation des emplacements par F4
/DEFINE PR_VSRELO   // Recherche multicritères sur emplacement/lot/élément
/DEFINE LDA         // Pour communiquer avec les programmes VSIEMP et VSRELO
/DEFINE PR_KGDP90   // Vérifie si la quantité en stock est suffisante
/DEFINE PR_VMRARM   // Recherche multicritères des articles

/INCLUDE qincsrc,prototypes

/UNDEFINE PR_VMRARM
/UNDEFINE PR_KGDP90
/UNDEFINE LDA
/UNDEFINE PR_VSRELO
/UNDEFINE PR_VSIEMP
/UNDEFINE PR_AFENCL
/UNDEFINE PR_GoASER
/UNDEFINE PR_GoAFENCL
/UNDEFINE PR_RMRBACI
/UNDEFINE PR_VMIART
/UNDEFINE PR_VMRADS
/UNDEFINE PR_VMRCLM
/UNDEFINE PR_VMRICL
/UNDEFINE PR_VMRNMV
/UNDEFINE PR_VMRPXR
/UNDEFINE PR_VMRREP
/UNDEFINE PR_VMTADP
/UNDEFINE PR_VMTAR1
/UNDEFINE PR_VMTDEP
/UNDEFINE PR_VMTSTE
/UNDEFINE PR_VMTSTP
/UNDEFINE PR_VoRPAR
/UNDEFINE PR_VVRCLI

// --- Définition des zones de l'écran ---------------------------------//
/INCLUDE QRPGLESRCF,KPBP1à

// ---------------------------------------------------------------------
//                     PROGRAMME PRINCIPAL
// ---------------------------------------------------------------------
// Initialisation SQL :
Exec Sql
     Set Option Commit = *None;

// Paramètres
Dcl-Pi *N;
     // - en entrée
    £CodeVerbe                                   Char(4) ;
    £CodeObjet                                   Char(6);
    £LibelleAction                               Char(30);
    £BibliothequeFichier                         Char(10);

     // - en sortie
    £CodeRetour                                  Char(1);
    £CodeSociete                                 Char(2);
    £CodeDepot                                   Char(3);
    £CodeClient                                  Char(9);
    £LibelleClient                               Char(30);
    £CodeRepresentant                            Char(3);
    £LibelleRepresentant                         Char(25);
    £CodeSpecifique                              Char(3);
    £LibelleSpecifique                           Char(25);
    £DateLivraison                               Char(10);
End-Pi ;

// Initialisation de début de programme
InitialisationProgramme();

Etape = 'InitialisationEcran1';
// Boucle de traitement du programme
DoW Etape <> 'Fin';
    Select;

        When Etape = 'InitialisationEcran1' ;
            InitialisationEcran1() ;
        When Etape = 'AffichageEcran1' ;
            AffichageEcran1() ;
        When Etape = 'VerificationEcran1' ;
            VerificationEcran1() ;

        When Etape = 'InitialisationEcran2' ;
            InitialisationEcran2() ;
        When Etape = 'AffichageEcran2' ;
            AffichageEcran2() ;
        When Etape = 'VerificationEcran2' ;
            VerificationEcran2() ;

        When Etape = 'AffichageEcranValidation' ;
            AffichageEcranValidation() ;

        When Etape = 'EcritureDonnees' ;
            EcritureDonnees() ;

        Other ;
    EndSl;
EndDo;

// Affectation des variables de sorties
£CodeSociete = EcranCodeSociete;
£CodeDepot = EcranCodeDepot;
£CodeClient = EcranCodeClient;
£LibelleClient = EcranLibelleClient;
£CodeRepresentant = EcranCodeRepresentant;
£LibelleRepresentant = EcranLibelleRepresentant;
£CodeSpecifique = EcranCodeSpecifique;
£LibelleSpecifique = EcranLibelleSpecifique;
£DateLivraison = %CHAR(EcranDateLivraison);

*Inlr= *On;

// ----------------------------------------------------------------------------
//                                  PROCEDURES
// ----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
///
//                               Initialisation du programme
//
// - Initialisation DSPF de la date
// - Constitution de la barre d'action
// - Lecture des entrées saisies par l'utilisateur lors de
// la dernière utilisation du programme
// - Récupération et affichage du libellé de la société
// - Création du UserIndex
///
//-----------------------------------------------------------------------------

Dcl-Proc InitialisationProgramme;
    // Initialisation des zones de l'écran
    EcranDateLivraison = %DATE();

    //Init FIDVALSXX
    FIDVALSXX = £BibliothequeFichier;

    // Constitution de la barre d'action
    RMRBACI.VerbeSouhaite(1) = £CodeVerbe;
    RMRBACI.objetSouhaite(1) = £CodeObjet;
    PR_RMRBACI(RMRBACI.ListeVerbesSouhaites
               :RMRBACI.ListeobjetsSouhaites
               :RMRBACI.ListeVerbesAutorises
               :RMRBACI.ListeobjetsAutorises
               :RMRBACI.ListeActionsEcran
               :RMRBACI.ListeLibellesActionsAutorisees);

    EcranAction1 = RMRBACI.Action1;
    EcranAction2 = RMRBACI.Action2;
    EcranAction3 = RMRBACI.Action3;
    EcranAction4 = RMRBACI.Action4;
    EcranAction5 = RMRBACI.Action5;
    EcranAction6 = RMRBACI.Action6;
    EcranAction7 = RMRBACI.Action7;
    EcranAction8 = RMRBACI.Action8;

    // VMTSTE : Récupération et affichage du libellé de la société
    VMTSTE.UCoRET = '0' ;
    VMTSTE.UCoSTE = EcranCodeSociete ;
    VMTSTE.ULISTE = *BLANKS ;
    PR_VMTSTE(VMTSTE.UCoRET
          :VMTSTE.UCoSTE
          :VMTSTE.ULISTE) ;
    EcranLibelleSociete = VMTSTE.ULISTE;

    // Création du UserIndex s'il n'existe pas
    Exec Sql
         Select 1
              Into :i
              From QSYS2.USER_INDEX_INFO
              Where USER_INDEX = :psds.PROC And
                    USER_INDEX_LIBRARY = :FIDVALSXX;
    MessageErreurSQL = 'CALL QSYS2 : Select User Index Info';
    GestionErreurSQL(MessageErreurSQL) ;
    If SQLCode = 100;
        Exec Sql
         //80 par élément : 30 NomVariable + 50 Valeur
         //User
         Call QSYS2.CREATE_USER_INDEX(USER_INDEX => :psds.PROC,
                                      USER_INDEX_LIBRARY => :FIDVALSXX,
                                      ENTRY_TYPE => 'VARIABLE',
                                      MAXIMUM_ENTRY_LENGTH => 800,
                                      KEY_LENGTH => 10,
                                      Replace => 'NO',
                                      IMMEDIATE_UPDATE => 'YES',
                                      TEXT_DESCRIPTION =>
                                           'Parametres du PGM KPBP10 pour init du DSPF',
                                      PUBLIC_AUTHORITY => '*USE');
        MessageErreurSQL = 'CALL QSYS2 : Create User Index';
        GestionErreurSQL(MessageErreurSQL) ;
    EndIf;
End-Proc;

//-----------------------------------------------------------------------------
///
//                          Ecran 1 : Initialisations pour l'écran 1
//
// - Mise en inverse vidéo de l'action choisie
// - Positionnement du curseur sur la zone Code Société si vide
//   sinon sur code client
// - Récupération des dernière valeurs utilisées lors du dernier lancement
//   du programme par l'utilisateur
///
//-----------------------------------------------------------------------------

Dcl-Proc InitialisationEcran1;
    Dcl-S boucle Ind;

    // Suite normale du programme : AffichageEcran1
    Etape = 'AffichageEcran1';

    // Mise en inverse vidéo de l'action choisie
    EcranVerbeobjet = £CodeVerbe + £CodeObjet ;
    EcranLibelleAction = £LibelleAction;

    Indicateur.IVEliop1 = *off;
    Indicateur.IVEliop2 = *off;
    Indicateur.IVEliop3 = *off;
    Indicateur.IVEliop4 = *off;
    Indicateur.IVEliop5 = *off;
    Indicateur.IVEliop6 = *off;
    Indicateur.IVEliop7 = *off;
    Indicateur.IVEliop8 = *off;

    i = 0;
    boucle = *On;
    DoW (boucle = *On and i < 8);
        i += 1;
        If (RMRBACI.VerbeAutorise(i) <> *BLANKS);
            If (RMRBACI.VerbeAutorise(i) = £CodeVerbe
                    and RMRBACI.objetAutorise(i) = £CodeObjet);
                boucle = *Off;
                EcranChoixAction = i;
            EndIf;
        EndIf;
    EndDo;

    // Positionnement du curseur sur Code Société si vide, sinon sur code client
    If (EcranCodeSociete = *BLANK); //Positionnement sur société
        EcranDeplacerCurseurLigne = 10;
        EcranDeplacerCurseurColonne = 39;
    Else;
    //Positionnement sur Code client
        EcranDeplacerCurseurLigne = 14;
        EcranDeplacerCurseurColonne = 39;
    EndIf;

    PositionCurseur = 'BAS';
    Indicateur.HautBasEcran = *off;

    // Récupération des dernières valeurs utilisées par l'utilisateur lors du
    //dernier lcmt du PGM
    Exec Sql
         Select ENTRY
              Into :DSPFSauve.TOTALITE
              From Table(QSYS2.USER_INDEX_ENTRIES(USER_INDEX_LIBRARY => :FIDVALSXX, USER_INDEX =>
                   :psds.PROC))
              Where Key = :psds.USER ;
    MessageErreurSQL = 'Select QSYS2 : User Index Entries';
    GestionErreurSQL(MessageErreurSQL) ;

    EcranCodeSociete = DSPFSauve.Valeur(1);
    EcranCodeClient = DSPFSauve.Valeur(2);
    EcranCodeRepresentant = DSPFSauve.Valeur(3);
    EcranCodeSpecifique = DSPFSauve.Valeur(4);
    //Récupération des libellés s'il y a des valeurs
    If (EcranCodeSociete <> *BLANKS
        Or EcranCodeClient <> *BLANKS
        Or EcranCodeRepresentant <> *BLANKS
        Or EcranCodeSpecifique <> *BLANKS);
        VerificationEcran1();
    EndIf;
End-Proc;

//-----------------------------------------------------------------------------
///
//                          Ecran 1 : Affichage-lecture de l'écran
//
// - Sauvegarde du code choix d'action en cours
// - Affichage - lecture d'écran
// - Initialisation des erreurs
// - Repositionnement du curseur là où il se trouvait
// - si le curseur est dans la barre d'action, ré-initialisation de l'écran
// - sinon actions en fonction du choix utilisateur :
//      -- F2 => Affichage fenetre utilisateur
//      -- F3 ou F12 => Sauvegarde saisies utilisateur et fin du programme
//      -- F4 => Recherche sur l'écran 1
//      -- F5 => Verification sur l'écran 1
//      -- F6 => Affichage fenetre services
//      -- F10 => Changement position curseur haut ou bas
//      -- F23 => Recherche multiCriteres sur l'écran 1
//      -- Entrée => vérifications
//              --- si OK : sauvegarde saisies utilisateur
//                          et initialisation de l'écran 2
//              --- si KO : Affichage de l'écran 1 avec les erreurs
///
//-----------------------------------------------------------------------------

Dcl-Proc AffichageEcran1;
    Dcl-S SauvegardeChoixAction                   Packed(1:0);

    // Sauvegarde du code choix d'action en cours
    SauvegardeChoixAction = EcranChoixAction;

    // Affichage - lecture d'écran
    EXFMT FM1;

    // Initialisation des erreurs
    Erreur = *Off;
    Indicateur.FM1_CodeSocieteInvalide = *Off;
    Indicateur.FM1_CodeClientInvalide = *Off;
    Indicateur.FM1_CodeRepresentantInvalide = *Off;
    Indicateur.FM1_CodeSpecifiqueInvalide = *Off;
    Indicateur.FM1_AucunCodeRenseigne = *Off;
    Indicateur.FM1_DateLivraisonInvalide = *Off;

    // Repositionnement du curseur là Où il se trouvait
    EcranDeplacerCurseurLigne = fichierDS.ligne;
    EcranDeplacerCurseurColonne = fichierDS.colonne;

    // Suite exceptionnelle du programme :
    // - si le curseur est dans la barre d'action, ré-initialisation d'écran
    // que l'action choisie soit valide ou non, et même si elle reste identique
    If (PositionCurseur = 'HAUT') ;
        If (EcranChoixAction <> SauvegardeChoixAction);
            i = EcranChoixAction;
            If (RMRBACI.VerbeAutorise(i) <> *BLANK);
                £CodeVerbe = RMRBACI.VerbeAutorise(i);
                £CodeObjet = RMRBACI.objetAutorise(i);
            EndIf;
        EndIf;
        Etape = 'InitialisationEcran1';

    // Sinon, en fonction de l'action utilisateur
    Else;
        Select ;
            When fichierDS.TouchePresse = F2;
                AffichageFenetreUtilisateur();
                Etape = 'AffichageEcran1' ;

            When fichierDS.TouchePresse = F3 Or fichierDS.TouchePresse = F12;
                SauvegardeSaisiesUtilisateur();
                £CodeRetour = '4';
                Etape = 'Fin';

            When fichierDS.TouchePresse = F4;
                RechercheEcran1() ;
                Etape = 'AffichageEcran1';

            When fichierDS.TouchePresse = F5;
                VerificationEcran1();
                Etape = 'AffichageEcran1';

            When fichierDS.TouchePresse = F6;
                AffichageFenetreServices();
                Etape = 'AffichageEcran1' ;

            When fichierDS.TouchePresse = F10;
                If (PositionCurseur = 'BAS ') ;// Si en bas On le passe en haut
                    PositionCurseur = 'HAUT' ;
                    Indicateur.HautBasEcran = *On ;
                    EcranDeplacerCurseurLigne = 01 ;
                    EcranDeplacerCurseurColonne = 03 ;
                Else ;
                    PositionCurseur = 'BAS ';//Si en haut On le passe en bas
                    Indicateur.HautBasEcran = *off ;
                    If (EcranCodeSociete = *BLANK) ;
                        EcranDeplacerCurseurLigne = 10 ;
                        EcranDeplacerCurseurColonne = 39 ;
                    Else ;
                        EcranDeplacerCurseurLigne = 12 ;
                        EcranDeplacerCurseurColonne = 39 ;
                    EndIf ;
                EndIf ;
                Etape = 'AffichageEcran1';

            When fichierDS.TouchePresse = F23;
                RechercheMultiCriteresEcran1() ;
                Etape = 'AffichageEcran1' ;

            When fichierDS.TouchePresse = ENTREE;
                VerificationEcran1();
                If (Erreur);
                    Etape = 'AffichageEcran1';
                Else;
                    SauvegardeSaisiesUtilisateur();
                    Etape = 'InitialisationEcran2';
                EndIf;
            Other ;
        EndSl;
    EndIf;
End-Proc;

//-----------------------------------------------------------------------------
///
//Ecran 1 : Recherche des valeurs possibles pour la zone où se trouve le curseur
//
// - Recherche sur code société
// - Recherche sur code représentant
// - Recherche sur code spécifique
///
//-----------------------------------------------------------------------------

Dcl-Proc RechercheEcran1;

    Select;
        // Recherche sur code société
        When (EcranZoneCurseur = 'ECOSTE');
            VoRPAR.UCoRAC = 'STE';
            VoRPAR.UNUPoS = 1;
            VoRPAR.UNUCon = 1;
            VoRPAR.UCoRTR = '0';
            VoRPAR.UCoARG = *BLANKS;
            VoRPAR.ULIPAR = *BLANKS;
            PR_VoRPAR(VoRPAR.UCoRAC
                    :VoRPAR.UNUPoS
                    :VoRPAR.UNUCon
                    :VoRPAR.UCoRTR
                    :VoRPAR.UCoARG
                    :VoRPAR.ULIPAR);
            If (VoRPAR.UCoRTR <> '1' );
                EcranCodeSociete = VoRPAR.UCoARG;
                EcranLibelleSociete = VoRPAR.ULIPAR;
            EndIf;

        // Recherche sur code client
        When (EcranZoneCurseur = 'ECOCLI');
            VVRCLI.UCoSTE = EcranCodeSociete;
            VVRCLI.UCoRTR = *BLANK;
            VVRCLI.UCoCLI = EcranCodeClient;
            PR_VVRCLI(VVRCLI.UCOSTE
                    :VVRCLI.UCORTR
                    :VVRCLI.UCOCLI
                    :VVRCLI.UMODIR);
            If (VVRCLI.UCORTR <> '1');
                EcranCodeClient = VVRCLI.UCoCLI;
                EcranLibelleClient = VVRCLI.UMoDIR;
            EndIf;

        // Recherche sur code représentant
        When (EcranZoneCurseur = 'ECOREP');
            VMRREP.UCoSTE = EcranCodeSociete;
            VMRREP.UCoREP = EcranCodeRepresentant;
            PR_VMRREP(
                    VMRREP.UCoSTE
                    :VMRREP.UCoREP
                    :VMRREP.ULIA30
                    :VMRREP.UCoRET);
            If (VMRREP.UCoRET <> '1' );
                EcranCodeRepresentant = VMRREP.UCoREP;
                EcranLibelleRepresentant = VMRREP.ULIA30;
            EndIf;

        // Recherche sur code spécifique
        When (EcranZoneCurseur = 'ECOSPE');
            VoRPAR.UCoRAC = 'XPBSPE';
            VoRPAR.UNUPoS = 1;
            VoRPAR.UNUCon = 1;
            VoRPAR.UCoARG = EcranCodeSpecifique;
            PR_VoRPAR(VoRPAR.UCoRAC
                    :VoRPAR.UNUPoS
                    :VoRPAR.UNUCon
                    :VoRPAR.UCoRTR
                    :VoRPAR.UCoARG
                    :VoRPAR.ULIPAR);
            If (VoRPAR.UCoRTR <> '1' );
                EcranCodeSpecifique = VoRPAR.UCoARG;
                EcranLibelleSpecifique = VoRPAR.ULIPAR;
            EndIf;
        Other;
    EndSl;
End-Proc;

//-----------------------------------------------------------------------------
///
//    Ecran 1 : Recherche multi-critères pour la zone Où se trouve le curseur
//
// - Recherche sur code client
///
//-----------------------------------------------------------------------------

Dcl-Proc RechercheMultiCriteresEcran1;

    Select;
        // Recherche sur code client
        When (EcranZoneCurseur = 'ECOCLI');
            VMRCLM.UCoSTE = %CHAR(EcranCodeSociete);
            VMRCLM.UCoCLI = %CHAR(EcranDateLivraison);
            PR_VMRCLM(VMRCLM.UCoSTE
               :VMRCLM.UCoRTR
               :VMRCLM.UCoCLI
               :VMRCLM.UMoDI2);
            If (VMRCLM.UCoRTR <> '1' and Erreur = *off);
                EcranCodeClient = VMRCLM.UCoCLI;
                EcranLibelleClient = VMRCLM.UMoDI2;
            EndIf;
        Other;
    EndSl;
End-Proc;

//-----------------------------------------------------------------------------
///
//         Ecran 1 :  Vérification des saisies de l'écran 1
//
// - La société doit exister
// - La date de livraison doit être renseignée
// - le code client doit exister, s'il est renseigné
// - Le code représentant doit exister, s'il est renseigné
// - le code spécifique doit exister, s'il est renseigné
// - Au moins un code doit être renseigné
///
//-----------------------------------------------------------------------------

Dcl-Proc VerificationEcran1;

    // - La société doit exister
    VMTSTE.UCoRET = '0' ;
    VMTSTE.UCoSTE = EcranCodeSociete ;
    VMTSTE.ULISTE = *BLANKS ;
    PR_VMTSTE(VMTSTE.UCoRET
          :VMTSTE.UCoSTE
          :VMTSTE.ULISTE) ;
    If (VMTSTE.UCoRET = '1') ;
        Indicateur.FM1_CodeSocieteInvalide = *On ;//Code société invalide
        Erreur = *On ;
    Else ;
        EcranLibelleSociete = VMTSTE.ULISTE ;//on écrit le libellé de la société sur le DSPF
    EndIf ;

    // - La date de livraison doit être renseignée
    // - doit être supérieure à la date du jour
    // - Ne doit pas dépasser 2 mois par rapport à la date du jour

    If (EcranDateLivraison < %Date() Or EcranDateLivraison > (%Date() + %Months(2)));
        Indicateur.FM1_DateLivraisonInvalide = *On;
        Erreur = *On;
    EndIf;

    // - le code client doit exister, s'il est renseigné
    If (EcranCodeClient <> *BLANKS And Not Erreur);
        VMRICL.UCOSTE = EcranCodeSociete;
        VMRICL.UCOCLI = EcranCodeClient;
        PR_VMRICL(VMRICL.UCoSTE
               :VMRICL.UCoCLI
               :VMRICL.ULISoC
               :VMRICL.ULIDES
               :VMRICL.ULIRUE
               :VMRICL.ULIVIL
               :VMRICL.UCoPoS
               :VMRICL.ULIBDI
               :VMRICL.UCoPAY
               :VMRICL.UCoLAN
               :VMRICL.UCoARC
               :VMRICL.UCoRE1
               :VMRICL.UCoRE2
               :VMRICL.UTXCo1
               :VMRICL.UTXCo2
               :VMRICL.URACDE
               :VMRICL.UCoLCP
               :VMRICL.UCoLIV
               :VMRICL.UCoTRA
               :VMRICL.UCoBLI
               :VMRICL.UFGECL
               :VMRICL.UCoFAC
               :VMRICL.UTXESC
               :VMRICL.UCoPAG
               :VMRICL.UCoDEV
               :VMRICL.UCoECH
               :VMRICL.UCoMRG
               :VMRICL.UCoTAX
               :VMRICL.UTYFAC
               :VMRICL.UMTMFA
               :VMRICL.UMTMFP
               :VMRICL.UCoCTX
               :VMRICL.UMTCAU
               :VMRICL.UMTCoF
               :VMRICL.UCoCEC
               :VMRICL.UMTSTA
               :VMRICL.UMTENC
               :VMRICL.UMTCHT
               :VMRICL.UCoCTR
               :VMRICL.UCoTAR
               :VMRICL.UCoCoV
               :VMRICL.UTXREM
               :VMRICL.UNUCoL
               :VMRICL.UCoRET
               :VMRICL.ULIEXP
               :VMRICL.UCoEDV);
        If (VMRICL.UCoRET = '1');
            Indicateur.FM1_CodeClientInvalide = *On; //Code client invalide
            Erreur = *On;
            EcranLibelleClient = *all'?'; //on met des '?' partout
        Else;
            EcranLibelleClient = VMRICL.ULISOC;
        EndIf;
    Else;//Sinon (Code Client = *Blanks), on réinitialise le libellé
        EcranLibelleCLient = *BLANKS;
    EndIf;

    // - Le code représentant doit exister, s'il est renseigné
    If (EcranCodeRepresentant <> *BLANKS And Not Erreur);
        Exec Sql
             Select XLIPAR
                  Into :ECRANLIBELLEREPRESENTANT
                  From VPARAM
                  Where XCORAC = 'REP' And
                        XCOARG = :ECRANCODEREPRESENTANT;
        MessageErreurSQL = 'Select VPARAM Code Representant';
        GestionErreurSQL(MessageErreurSQL) ;

        If (SQLCODE <> 0);
            Indicateur.FM1_CodeRepresentantInvalide = *On;
            Erreur = *On;
            EcranLibelleRepresentant = *ALL'?';
        EndIf;
    Else;//Sinon (Code Représentant = *Blanks), on réinitialise le libellé
        EcranLibelleRepresentant = *BLANKS;
    EndIf;

    // - le code spécifique doit exister, s'il est renseigné
    If (EcranCodeSpecifique <> *BLANKS And Not Erreur);
        Exec Sql
             Select XLIPAR
                  Into :ECRANLIBELLESPECIFIQUE
                  From VPARAM
                  Where XCORAC = 'XPBSPE' And
                        XCOARG = :ECRANCODESPECIFIQUE;
        MessageErreurSQL = 'Select VPARAM CodeSpecifique ';
        GestionErreurSQL(MessageErreurSQL) ;

        If (SQLCODE <> 0);
            Indicateur.FM1_CodeSpecifiqueInvalide = *On;
            Erreur = *On;
            EcranLibelleSpecifique = *ALL'?';
        EndIf;
    Else;//Sinon (Code Spécifique = *Blanks), on réinitialise le libellé
        EcranLibelleSpecifique = *BLANK;
    EndIf;

    // - Au moins un code doit être renseigné
    If (EcranCodeClient = *BLANKS
            And EcranCodeRepresentant = *BLANKS
            And EcranCodeSpecifique = *BLANKS
            And Not Erreur);
            Indicateur.FM1_AucunCodeRenseigne = *On;
            Erreur = *On;
    EndIf;
End-Proc ;

//-----------------------------------------------------------------------------
///
//                    Ecran 1 : Sauvegarde des saisies utilisateurs
//
// - Sauvegarde des sélections dans le fichier des critères
///
//-----------------------------------------------------------------------------

Dcl-Proc SauvegardeSaisiesUtilisateur;

    DSPFSauve.Clef(1) = 'Code société';
    DSPFSauve.Valeur(1) = EcranCodeSociete;

    DSPFSauve.Clef(2) = 'Code client';
    DSPFSauve.Valeur(2) = EcranCodeClient;

    DSPFSauve.Clef(3) = 'Code représentant';
    DSPFSauve.Valeur(3) = EcranCodeRepresentant;

    DSPFSauve.Clef(4) = 'Code spécifique';
    DSPFSauve.Valeur(4) = EcranCodeSpecifique;

    Exec Sql
         Call QSYS2.ADD_USER_INDEX_ENTRY(USER_INDEX_LIBRARY => :FIDVALSXX,
                                         USER_INDEX => :psds.PROC,
                                         Replace => 'YES',
                                         ENTRY => :DSPFSauve.TOTALITE,
                                         Key => :psds.USER) ;
    MessageErreurSQL = 'Ecriture User Index';
    GestionErreurSQL(MessageErreurSQL) ;
End-Proc;

//-----------------------------------------------------------------------------
///
//                          Appel de la fenêtre utilisateur (par 'F2')
//
// - Appel de la fenêtre utilisateur
///
//-----------------------------------------------------------------------------

Dcl-Proc AffichageFenetreUtilisateur;
    // Appel de la fenêtre utilisateur
    GoAFENCL.UCoVFU = £CodeVerbe;
    GoAFENCL.UCooFU = £CodeObjet;
    PR_GoAFENCL(GoAFENCL.UCoVFU
          :GoAFENCL.UCooFU);
End-Proc;

//-----------------------------------------------------------------------------
///
//                              Appel du menu de services (par 'F6')
//
// - Appel du menu de services
///
//-----------------------------------------------------------------------------

Dcl-Proc AffichageFenetreServices;
    PR_GoASER();
End-Proc;