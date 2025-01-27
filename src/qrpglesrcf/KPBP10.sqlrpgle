**free
Ctl-opt Option(*srcstmt) AlwNull(*usrctl) UsrPrf(*owner)
        DatFmt(*eur) DatEdit(*dmy) TimFmt(*hms) dftactgrp(*no);

///--------------------------------------------------------------
//       NOM        : KPBP10               TYPE : Interactif
//
//  TITRE      : Gestion pub.: liv. client  : saisie
//
//  FONCTIONS  : Saisie des lignes de livraison d'articles publici
//               taires à un client ; ces lignes serviront à géné-
//               rer des mouvements de stock dans le fichier
//               VRESTK et seront éditées
//               Gestion en 4 étapes (dont 2 écrans) :
//               . 1er écran de saisie des éléments de base (code
//                 société, date, code client, code spécifique
//                 et code représentant)
//               . alimentation du sous-fichier avec 50 lignes
//                 blanches
//               . 2e écran de saisie des articles :
//                 - haut d'écran (format de contrôle) : sert à
//                   afficher les données saisies sur l'écran 1
//                   avec les libellés correspondants
//                 - corps d'écran (sous-fichier) : affiche une
//                   page avec les données à saisir
//                 - bas d'écran : 1 ligne de touches de fonction
//               . Ecriture des mouvements de stock dans le
//                 fichier VRESTK
//               . Edition des lignes saisies
//
//  APPELE PAR : - KPBP10CL
//
//  PARAMETRES :
// - D'appel :
//      - £CodeVerbe
//      - £CodeObjet
//      - £LibelleAction
//      - £BibliothequeFichier
//
// - Retournés
//      - £CodeRetour
//      - £CodeSociete
//      - £CodeDepot
//      - £CodeClient
//      - £LibelleClient
//      - £CodeRepresentant
//      - £LibelleRepresentant
//      - £CodeSpecifique
//      - £LibelleSpecifique
//      - £DateLivraison

//
//  ECRIT DU   : 29/03/2010            PAR : GGr (Antilles Glaces)
//        AU   : 11/05/2010
//
//---------------------------------------------------------------
//
//  MODIFIE DU : 18/06/2010            PAR : GGr (Antilles Glaces)
//         AU : 18/06/2010
//
// . modification(s) :
//   - l'affectation des articles publicitaires ne se fait plus
//     uniquement pour un client ; elle se fait, au choix, pour
//     un client Ou un représentant Ou un code spécifique (opéra-
//     tion particulière, etc.) ; d'où ajout de données à saisir
//     sur l'écran de garde
//
//--------------------------------------------------------------
//
// MODIFIE DU : 03/05/2011            PAR : GGr (Antilles Glaces)
//        AU : 03/05/2011
//
//. modification(s) :
//  - correction d'erreur :
//    . la date portée sur les mouvements de stock était la date
//      du jour et non la date saisie sur l'écran de garde
//
//---------------------------------------------------------------
//
// MODIFIE DU : 31/03/2017            PAR : GGr (Antilles Glaces)
//         AU : 31/03/2017
//         DU : 10/04/2017            PAR : GGr (Antilles Glaces)
//         AU : 11/04/2017
//
// . modification(s) :
//   - conversion simple en RPG ILE par CVTRPGSRC
//   - possibilité de saisir de 1 à 3 codes (client et/ou
//     représentant et/ou Opération) sur l'écran de garde
//   - récupération du code représentant lié au client
//   - alimentation du fichier historique KPBFAT
//
//---------------------------------------------------------------
//
// MODIFIE DU : 02/06/2022            PAR : ANg (Antilles Glaces)
//         AU : 29/11/2022
//
// . modification(s) :
//   - conversion RPG Free
//   - Création Data structure sous-fichier
//   - Création Data structure programme
//   - Monitoring des erreurs
//   - Ajout des alias DSPF + PRTF
//   - Création des prototypes utilisés dans le programme
//   - Création Ecran1 et Ecran2 DSPF
//   - Réecriture des dates en RPG et DSPF
//   - Inclusion des Procédures
//
//---------------------------------------------------------------
//
// MODIFIE DU : 14/12/2022            PAR : ANg (Antilles Glaces)
//         AU : 15/02/2023
//
// . modification(s) :
//   - Ajout Lot/Element de lot/Designation Lot/Emplacement
//   - Recupération du code depot par XPBPAR
//   - Gestion dépôt sans emplacement
//   - Gestion dépôt avec emplacement
//   - Gestion dépôt avec emplacement et article avec lot/élément
//   - Ajout des descriptions de toutes les procédures
//
///---------------------------------------------------------------

// --- Fichiers --------------------------------------------------------
Dcl-F KPBP10E  WorkStn
               SFile(FM2SF:LigneFM2SF)//SFILE(Format:rang)
               InfDS(fichierDS)//Permet d'avoir des informations sur le sous-fichier en cours
               IndDs(Indicateur)
               Alias;//pour mettre les indicateurs dans une DS et les nommer

// --- Variables -------------------------------------------------------
Dcl-S PositionCurseur                             Char(4);//PoSECR
Dcl-S LigneFM2SF                                  Packed(4:0);
Dcl-S i                                           Packed(3:0);//Sert aux boucles
Dcl-S Etape                                       Char(40);
Dcl-S Erreur                                      Ind;
Dcl-S PremiereLigneEnErreur                       Packed(4:0);
Dcl-S MessageErreurSQL                            Char(52);
Dcl-S DepotGereParEmplacement                     Ind;
Dcl-S FIDVALSXX                                   Char(9);
Dcl-S SaisieUtilisateur                           Ind;
Dcl-S CoefPrixUnitaireDepot                       Packed(5:4);

// --- Data-structures Ecran    --------------------------------------
Dcl-Ds DSPFSauve Qualified;
    Totalite                                Char(800);
    Element                                 Char(80) Dim(10) Overlay(Totalite);
    Clef                                    Char(30) Overlay(Element);
    Valeur                                  Char(50) Overlay(Element:*Next);
End-Ds;

// --- Data-structures Indicateurs--------------------------------------
Dcl-Ds Indicateur qualified;
     // Touches fonctions
     // F2_Utilisateur                               Ind Pos(2);
     // F3_Fin                                       Ind Pos(3);
     // F4_Recherche                                 Ind Pos(4);
     // F5_Actualiser                                Ind Pos(5);
     // F6_Services                                  Ind Pos(6);
     // F10_Action                                   Ind Pos(10);
     // F12_Abandon                                  Ind Pos(12);
     // F23_Criteres                                 Ind Pos(23);

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

//-----------------------------------------------------------------------------
///
//                          Ecran 2 : Initialisation pour l'écran FM2
//
// - Réinitisalisation de l'erreur
// - Affichages lot/désignation lot/élément
// - Affichage du Sous Fichier
// - Récupération code dépôt
// - Récupération nom dépôt
// - Si dépôt géré par emplacement => Affichage de l'emplacement
// - Remise à blanc du sous-fichier
// - Chargement du sous-fichier avec 50 lignes blanches
// - Positionnement sur la première ligne du sous-fichier
// - Positionnement du curseur
///
//-----------------------------------------------------------------------------

Dcl-Proc InitialisationEcran2;

    // Suite normale du programme : affichage de l'écran 2
    Etape = 'AffichageEcran2';

    // Initialisations
    Erreur = *off;
    SaisieUtilisateur = *Off;
    Indicateur.FM2_Affichage_Lot = *On;
    Indicateur.FM2_Affichage_DesignationLot = *On;
    Indicateur.FM2_Affichage_ElementDeLot = *On;
    Indicateur.SousFichierDisplay = *On;
    Indicateur.SousFichierEnd = *On;
    Indicateur.SousFichierDisplayControl = *On;
    ReinitialisationIndicateurFM2();

    // - Récupération du code dépôt ainsi que du coefficient du prix associé au dépôt
    Exec Sql
         Select Substr(XLIPAR, 1, 3), CAST(Substr(XLIPAR, 6, 6)  AS DEC)/10000
              Into :ECRANCODEDEPOT, :CoefPrixUnitaireDepot
              From VPARAM
              Where XCORAC Like :TABLE_CHARTREUSE_GESTION_PUB;
    MessageErreurSQL = 'Err : récup code dépot VPARAM';
    GestionErreurSQL(MessageErreurSQL) ;

    // - Récupération du nom du dépôtS
    VMTDEP.UCORET = '0';
    VMTDEP.UCODEP = EcranCodeDepot;
    VMTDEP.ULIPA1 = *BLANKS;
    VMTDEP.ULIPA2 = *BLANKS;
    PR_VMTDEP(VMTDEP.UCoRET
          :VMTDEP.UCODEP
          :VMTDEP.ULIPA1
          :VMTDEP.ULIPA2);
    If (VMTDEP.UCoRET = '0');
        EcranLibelleDepot = VMTDEP.ULIPA1;
    ElseIf (VMTDEP.UCoRET = '1');
        EcranLibelleDepot = *ALL'?';
    EndIf;

    // Si le dépôt est géré par emplacement,
    // => on affiche l'emplacement sur le DSPF
    Exec Sql
         Select
            Case
                When Substr(XLIPAR, 48, 1) Like ' ' Then 0
                Else 1
            End
            Into :DepotGereParEmplacement
            From  VPARAM
            Where XCORAC = :TABLE_CHARTREUSE_GESTION_DEPOT
                And XCOARG = :ECRANCODEDEPOT;
    MessageErreurSQL = 'Err : Recup emplacement VPARAM';
    GestionErreurSQL(MessageErreurSQL) ;

    If (DepotGereParEmplacement);
        Indicateur.FM2_Affichage_Emplacement = *On;
    EndIf;

    // Remise à blanc du sous-fichier
    Indicateur.SousFichierClear = *On;
    Write FM2CTL;
    Indicateur.SousFichierClear = *off;

    // Chargement du sous-fichier avec 50 lignes blanches
    LigneFM2SF = 0;
    EcranLigneCodeArticle = *BLANKS;
    EcranLigneLibelleArticle = *BLANKS;
    EcranCodeUnite = *BLANKS;
    EcranLigneQuantiteArticle = 0;
    EcranLignePrixUnitaireArticle = 0;
    EcranLignePrixTotal = 0;
    EcranLigneEmplacement = *BLANKS;
    EcranLigneElement = 0;
    EcranLigneLot = *BLANKS;
    EcranLigneDesignationLot = *BLANKS;
    For i = 1 to 50;
        LigneFM2SF = LigneFM2SF + 1;
        WRITE FM2SF;
    EndFor;

    // Positionnement sur la première ligne du sous-fichier
    EcranLigneSousFichier = 1;

    // Positionnement du curseur
    EcranDeplacerCurseurLigne = 10;
    EcranDeplacerCurseurColonne = 09;

End-Proc;

//-----------------------------------------------------------------------------
///
//                          Ecran 2 : Affichage-lecture de l'écran 2
// - Affichage/Lecture de l'écran 2
// - Re-positionnement du curseur là Où il se trouvait
// - Actions utilisateurs :
//      -- F2 => Affichage de la Fenêtre utilisateur
//      -- F3 => Verification de l'écran 2
//               puis affichage de l'écran de validation
//      -- F4 => Recherche écran 2 puis réinitialisation des indicateurs
//      -- F5 ou entrée => Vérification écran 2
//      -- F6 => Affichage de la fenêtre services
//      -- F12 => Repositionnement du curseur et affichage écran 1
//      -- F23 => Recherche multi-criteres écran2 puis
//                 réinitialisation des indicateurs
///
//-----------------------------------------------------------------------------

Dcl-Proc AffichageEcran2;

    // Affichage/Lecture de l'écran
    Write FM2BAS;
    ExFmt FM2CTL;

    // Suites exceptionnelles du programme :
    Select;
        When fichierDS.TouchePresse = F2;
            AffichageFenetreUtilisateur();
            Etape = 'AffichageEcran2';

        When fichierDS.TouchePresse = F3;
            VerificationEcran2();
            AffichageEcranValidation();

        When fichierDS.TouchePresse = F4;
            ReinitialisationIndicateurFM2();
            RechercheEcran2();
            Etape = 'AffichageEcran2';

        When (fichierDS.TouchePresse = F5 Or fichierDS.TouchePresse = ENTREE);
            ReinitialisationIndicateurFM2();
            VerificationEcran2();
            Etape = 'AffichageEcran2';

        When fichierDS.TouchePresse = F6;
            AffichageFenetreServices();
            Etape = 'AffichageEcran2';

        When fichierDS.TouchePresse = F12;
            EcranDeplacerCurseurLigne =  14;
            EcranDeplacerCurseurColonne =  39;
            Etape = 'AffichageEcran1';

        When fichierDS.TouchePresse = F23;
            ReinitialisationIndicateurFM2();
            RechercheMultiCriteresEcran2();
            Etape = 'AffichageEcran2';

        Other;
            Etape = 'AffichageEcran2';
    EndSl;
End-Proc;

//-----------------------------------------------------------------------------
///
//                      Ecran 2 :  Vérification des saisies de l'écran 2
//
// - Intialisation des messages d'erreur, de l'erreur et de la première
// ligne en erreur
// - Boucle de vérification : Appel à la procédure VerificationLigne
// pour chaque ligne du SF
// - Positionnement sur la première ligne en erreur
///
//-----------------------------------------------------------------------------

Dcl-Proc VerificationEcran2;
    Dcl-S RangSousFichierEnErreur Zoned(2:0);
    Dcl-S LigneRangSousFichierEnErreur Zoned(2:0);

    // Initialisations
    Erreur = *off;
    PremiereLigneEnErreur = 9999;

    // Boucle de vérifications
    For i = 1 to MAX_LIGNE_ARTICLE ;
        Chain i FM2SF;//on récupère ligne par ligne le sous-fichier
        If %Found;
            If (Erreur =*Off);
                VerificationLigne();
            EndIf;
        EndIf;
    EndFor;

    // Positionnement sur la première ligne en erreur
    If Erreur;
    //Positionnement du sous fichier sur l'erreur
        EcranLigneSousFichier = PremiereLigneEnErreur;

        //Recherche du rang de l'erreur (1, 2 ou 3)
        RangSousFichierEnErreur = %REM(PremiereLigneEnErreur:NOMBRE_RANG_PAR_PAGE);

        //Si réultat du modulo = 0, c'est la dernière valeur
        If (RangSousFichierEnErreur = 0);
            RangSousFichierEnErreur = NOMBRE_RANG_PAR_PAGE;
        EndIf;

        LigneRangSousFichierEnErreur =
        LIGNEDEBUTSOUSFICHIER +
        NOMBREDELIGNEPARRANGSOUSFICHIER * (RangSousFichierEnErreur - 1);

        //Positionnement sur la zone en Erreur
        Select;
            //Erreur sur l'emplacement
            When Indicateur.FM2_MSGERR_EmplacementInconnu Or
                Indicateur.FM2_MSGERR_EmplacementManquant;
                EcranDeplacerCurseurColonne = 9;
                EcranDeplacerCurseurLigne = LigneRangSousFichierEnErreur + 2;

                //Erreur sur le lot
            When Indicateur.FM2_MSGERR_LotManquant Or
                Indicateur.FM2_MSGERR_LotInconnu;
                EcranDeplacerCurseurColonne = 18;
                EcranDeplacerCurseurLigne = LigneRangSousFichierEnErreur + 2;

            //Erreur sur l'élément
            When Indicateur.FM2_MSGERR_ElementInconnu Or
                Indicateur.FM2_MSGERR_ElementManquant;
                EcranDeplacerCurseurColonne = 64;
                EcranDeplacerCurseurLigne = LigneRangSousFichierEnErreur + 2;

            //Erreur sur l'article
            When Indicateur.FM2_MSGERR_ArticleNonGere Or
                Indicateur.FM2_MSGERR_CodeArticleInvalide;
                EcranDeplacerCurseurColonne = 9;
                EcranDeplacerCurseurLigne = LigneRangSousFichierEnErreur;

            //Erreur sur la quantite
            When Indicateur.FM2_MSGERR_QuantiteObligatoire Or
                Indicateur.FM2_IV_QuantiteSuperieureAuDispo;
                EcranDeplacerCurseurColonne = 33;
                EcranDeplacerCurseurLigne = LigneRangSousFichierEnErreur;

            other;
            // handle other conditions
        EndSl;

    Else;
        // Re-positionnement de l'affichage du curseur là où il était
        EcranDeplacerCurseurColonne = fichierDS.colonne;
        EcranDeplacerCurseurLigne = fichierDS.ligne;

        // Re-positionnement de l'affichage au rang de sous fichier où il était
        If (EcranRecupererLigneSFCurseur <> 0);
            EcranLigneSousFichier = EcranRecupererLigneSFCurseur;
        EndIf;
    EndIf;
End-Proc;

//-----------------------------------------------------------------------------
///
//                  Ecran 2 :  Vérification des saisies d'une ligne de l'écran 2
//
// - Le code article doit exister
// - Vérification si l'article est géré par lot
// - Si l'article n'est pas géré par lot, on enlève l'affichage du lot et
// de l'élément de lot
// - L'article doit être géré dans le dépôt
// - Si le dépôt est géré par emplacement, l'emplacement doit exister
// - Si l'article est géré par lot, le lot et l'élement de lot doivent exister
// - La quantité à livrer doit être saisie
// - la quantité doit être inférieure au stock disponible
//      -- Gestion sans emplacement, sans lot/élément
//      -- Gestion par lots et/ou un dépôt géré par emplacements
// - Récupération du prix unitaire de l'article et calcul du montant de la ligne
// - Si l'article est effacé, ré-initialisation de toutes les zones
// - Si le lot est effacé, ré-initialisation de la désignation et du lot
// - Positionnement sur la première ligne en erreur
// - Mise à jour du sous fichier
///
//-----------------------------------------------------------------------------

Dcl-Proc VerificationLigne;

    Dcl-S QuantiteDisponible                                    Zoned(11:3);
    Dcl-S ArticleGereParLot                                     Ind;
    Dcl-S Trouve                                                Ind;

    // Vérifications des saisies
    // GESTION DE L'ARTICLE
    // - Le code article doit exister
    //. au passage, récupération du libellé de l'article et son unité de gestion
    //. au passage, on passe à *ON le fait qu'au moins un article a été saisi
    If (EcranLigneCodeArticle <> *BLANKS);
        VMTAR1.UCOSTE = EcranCodeSociete;
        VMTAR1.UCOART = EcranLigneCodeArticle;
        VMTAR1.UCORET = *BLANK;
        PR_VMTAR1(VMTAR1.UCOSTE
               :VMTAR1.UCOART
               :VMTAR1.ULIAR1
               :VMTAR1.ULIAR2
               :VMTAR1.ULIAR3
               :VMTAR1.UCOUNC
               :VMTAR1.UCOUNL
               :VMTAR1.UCOUNF
               :VMTAR1.UCOUNG
               :VMTAR1.UCFECG
               :VMTAR1.UCFEGF
               :VMTAR1.UCFECL
               :VMTAR1.UCOTYA
               :VMTAR1.UCOSTO
               :VMTAR1.UCOGLO
               :VMTAR1.UCODEP
               :VMTAR1.UNUGAM
               :VMTAR1.UCORET);
        If (VMTAR1.UCORET = '1');
            Indicateur.FM2_IV_CodeArticleInvalide = *On;
            Indicateur.FM2_MSGERR_CodeArticleInvalide = *On;
            Erreur = *On;
        Else;
            EcranLigneLibelleArticle = VMTAR1.ULIAR1;
            EcranCodeUnite = VMTAR1.UCoUNG;
            SaisieUtilisateur = *On;
        EndIf;
    EndIf;

    // Vérification si l'article est géré par lot
    If (EcranLigneCodeArticle <> *BLANKS And Erreur = *Off);
        ArticleGereParLot = VerificationArticleGereParLot();
    EndIf;

    // - Si l'article n'est pas géré par lot, on enlève l'affichage du lot
    // et de l'élément de lot
    If (not ArticleGereParLot And Erreur = *Off And EcranLigneCodeArticle <> *BLANKS);
        Indicateur.FM2_Affichage_Lot = *Off;
        Indicateur.FM2_Affichage_DesignationLot = *Off;
        Indicateur.FM2_Affichage_ElementDeLot = *Off;
        // Si l'article n'est pas géré par lot, on supprime au cas où toutes
        // les zones
        EcranLigneLot = *BLANKS;
        EcranLigneDesignationLot = *BLANKS;
        EcranLigneElement = 0;
    Else;
        Indicateur.FM2_Affichage_Lot = *On;
        Indicateur.FM2_Affichage_DesignationLot = *On;
        Indicateur.FM2_Affichage_ElementDeLot = *On;
    EndIf;

    // - L'article doit être géré dans le dépôt
    If (EcranLigneCodeArticle <> *BLANKS And Erreur = *Off);
        VMTADP.UCoSTE = EcranCodeSociete;
        VMTADP.UCoDEP = EcranCodeDepot;
        VMTADP.UCoART = EcranLigneCodeArticle;
        VMTADP.UCoRET = *BLANK;
        PR_VMTADP(VMTADP.UCOSTE
               :VMTADP.UCODEP
               :VMTADP.UCOART
               :VMTADP.UCORET
               :VMTADP.UTYAPR
               :VMTADP.UQTMAX);
        If (VMTADP.UCORET = '1');
            Indicateur.FM2_IV_ArticleNonGere = *On;
            Indicateur.FM2_MSGERR_ArticleNonGere = *On;
            Erreur = *On;
        EndIf;
    EndIf;

    // GESTION DE L'EMPLACEMENT
    // - Si le dépôt est géré par emplacement, l'emplacement doit exister
    If ( DepotGereParEmplacement And
          EcranLigneCodeArticle <> *BLANKS And Erreur = *Off);
        // Emplacement manquant
        If (EcranLigneEmplacement = *BLANKS);
            Erreur = *On;
            Indicateur.FM2_IV_Emplacement = *On;
            Indicateur.FM2_MSGERR_EmplacementManquant = *On;
        Else;
            // Emplacement n'existe pas
            // Préparation curseur
            Trouve = *Off;
            Exec Sql
               Select
                    Case
                        When Count(PCOEMP) > 0  Then 1
                    Else 0
                    End
                        Into :Trouve
                    From VEMPLA
                    Where PCODEP = :ECRANCODEDEPOT
                        And PCOEMP = :ECRANLIGNEEMPLACEMENT;
            MessageErreurSQL = 'Err : Select code emplacement' ;
            GestionErreurSQL(MessageErreurSQL) ;

            If not Trouve;
                Erreur = *On;
                Indicateur.FM2_IV_Emplacement = *On;
                Indicateur.FM2_MSGERR_EmplacementInconnu = *On;
            EndIf;
        EndIf;
    EndIf;

    //GESTION EMPLACEMENT/LOT/ELEMENT
    // - Si l'article est géré par lot, le lot et l'élement de lot
    // doivent exister
    If ( ArticleGereParLot And
          EcranLigneCodeArticle <> *BLANKS And Erreur = *Off);
        // ManqueLot
        If (Erreur = *Off And EcranLigneLot = *BLANKS);
            Indicateur.FM2_IV_Lot = *On;
            Indicateur.FM2_MSGERR_LotManquant = *On;
            Erreur = *On;
        EndIf;

        // Code lot inconnu
        If (Erreur = *Off And EcranLigneLot <> *BLANKS And LotTrouve() = *Off);
            Indicateur.FM2_IV_Lot = *On;
            Indicateur.FM2_MSGERR_LotInconnu = *On;
            Erreur = *On;
        EndIf;

        // Manque élément
        If (Erreur = *Off And EcranLigneElement = 0);
            Indicateur.FM2_IV_Element = *On;
            Indicateur.FM2_MSGERR_ElementManquant = *On;
            Erreur = *On;
        EndIf;

        // Code élément inconnu
        If (Erreur = *Off And EcranLigneElement <> 0
        And ElementTrouve() = *Off);
            Indicateur.FM2_IV_Element = *On;
            Indicateur.FM2_MSGERR_ElementInconnu = *On;
            Erreur = *On;
        EndIf;
    EndIf;

    // GESTION DE LA QUANTITE
    //   - la quantité à livrer doit être saisie
    If (EcranLigneCodeArticle <> *BLANKS And EcranLigneQuantiteArticle = 0
    And Erreur = *Off);
        Indicateur.FM2_IV_Quantiteobligatoire = *On;
        Indicateur.FM2_MSGERR_Quantiteobligatoire = *On;
        Erreur = *On;
    EndIf;

    //   - la quantité doit être inférieure au stock disponible
    //        -- Gestion sans emplacement, sans lot/élément
    If ( not DepotGereParEmplacement And not ArticleGereParLot And
          EcranLigneQuantiteArticle > 0 And Erreur = *Off
          And EcranLigneCodeArticle <> *BLANKS);
        VMTSTP.UCOSTE = EcranCodeSociete;
        VMTSTP.UCODEP = EcranCodeDepot;
        VMTSTP.UCOART = EcranLigneCodeArticle;
        VMTSTP.UQTUNG = EcranLigneQuantiteArticle;
        VMTSTP.UCORET = *BLANK;
        PR_VMTSTP(
            VMTSTP.UCoSTE
            :VMTSTP.UCODEP
            :VMTSTP.UCOART
            :VMTSTP.UQTUNG
            :VMTSTP.UCORET
            :VMTSTP.UQTRES);
        If (VMTSTP.UCoRET = '1');
            Indicateur.FM2_IV_QuantiteSuperieureAuDispo = *On;
            Indicateur.FM2_MSGERR_QuantiteSuperieureAuDispo = *On;
            Erreur = *On;
        EndIf;
    EndIf;

    //        -- Gestion par lots et/ou un dépôt géré par emplacements
    If ( (ArticleGereParLot Or DepotGereParEmplacement) And
          EcranLigneCodeArticle <> *BLANKS And EcranLigneQuantiteArticle > 0 And Erreur = *Off);

        KGDP90.CodeSociete = EcranCodeSociete;
        KGDP90.CodeDepot = EcranCodeDepot;
        KGDP90.CodeArticle = EcranLigneCodeArticle;
        KGDP90.CodeEmplacement = EcranLigneEmplacement;

        If (ArticleGereParLot);
            KGDP90.CodeLot = EcranLigneLot;
            KGDP90.CodeElement = %EditC(EcranLigneElement:'X');
            // - 'F' : numéro fixe
            KGDP90.TypeElement = 'F';
        Else;
            KGDP90.CodeLot = *BLANK;
            KGDP90.CodeElement = *BLANK;
            KGDP90.TypeElement = *BLANK;
        EndIf;

          // Doit être sous la forme SSAAMMJJ
        KGDP90.DateBesoin = %subst(%Char(EcranDateLivraison) :7 :2) +
          %subst(%Char(EcranDateLivraison) :9 :2) +
          %subst(%Char(EcranDateLivraison) :4 :2) +
          %subst(%Char(EcranDateLivraison) :1 :2);
        KGDP90.PriseEnCompteQuantiteReserve = 'O';
        KGDP90.AcceptationLotsBloques = 'N';
        KGDP90.AcceptationLotsNonDisponibles = 'N';
        KGDP90.AcceptationLotsDateDepassee = 'N';

        PR_KGDP90(
          KGDP90.CodeSociete
          :KGDP90.CodeDepot
          :KGDP90.CodeArticle
          :KGDP90.CodeEmplacement
          :KGDP90.CodeLot
          :KGDP90.CodeElement
          :KGDP90.TypeElement
          :KGDP90.DateBesoin
          :KGDP90.PriseEnCompteQuantiteReserve
          :KGDP90.AcceptationLotsBloques
          :KGDP90.AcceptationLotsNonDisponibles
          :KGDP90.AcceptationLotsDateDepassee
          :KGDP90.QuantiteDisponible
          :KGDP90.CodeRetour);

        If KGDP90.CodeRetour = '0' ;
            QuantiteDisponible = KGDP90.QuantiteDisponible ;
            If (QuantiteDisponible < EcranLigneQuantiteArticle);
                Indicateur.FM2_IV_QuantiteSuperieureAuDispo = *On;
                Indicateur.FM2_MSGERR_QuantiteSuperieureAuDispo = *On;
                Erreur = *On;
            EndIf;
        Else ;
            Indicateur.FM2_IV_QuantiteSuperieureAuDispo = *On;
            Indicateur.FM2_MSGERR_QuantiteSuperieureAuDispo = *On;
            Erreur = *On;
        EndIf ;
    EndIf ;

    // Calculs
    // - Récupération du prix unitaire de l'article et calcul du montant de la ligne
    // Si l'article n'est pas géré par lot
    If (EcranLigneCodeArticle <> *BLANKS And Not ArticleGereParLot);
        VMRPXR.UCOSTE = EcranCodeSociete;
        VMRPXR.UCOART = EcranLigneCodeArticle;
        VMRPXR.UCODEP = EcranCodeDepot;
        PR_VMRPXR(
            VMRPXR.UCoSTE
            :VMRPXR.UCOART
            :VMRPXR.UCODEP
            :VMRPXR.UPXREV
            :VMRPXR.UCoRET);
        If (VMRPXR.UCORET <> '1');
            EcranLignePrixUnitaireArticle = VMRPXR.UPXREV * CoefPrixUnitaireDepot;
        EndIf;
    // Si l'article est géré par lot
    ElseIf (ArticleGereParLot);
        Exec SQL
        SELECT EPUSTD * :CoefPrixUnitaireDepot
        Into :EcranLignePrixUnitaireArticle
        FROM VLOELT
        WHERE ECOART = :EcranLigneCodeArticle
            And ECOLOT = :EcranLigneLot
            And ENULOT = :EcranLigneElement
            And ECODEP = :EcranCodeDepot;
    EndIf;
    //Calcul montant de la ligne
    EcranLignePrixTotal = EcranLigneQuantiteArticle * EcranLignePrixUnitaireArticle;

    // Si l'article est effacé, ré-initialisation de toutes les zones
    If (EcranLigneCodeArticle = *BLANKS);
        EcranLigneLibelleArticle = *BLANKS;
        EcranCodeUnite = *BLANKS;
        EcranLigneQuantiteArticle = 0;
        EcranLignePrixUnitaireArticle = 0;
        EcranLignePrixTotal = 0;
        EcranLigneEmplacement = *BLANKS;
        EcranLigneElement = 0;
        EcranLigneLot = *BLANKS;
        EcranLigneDesignationLot = *BLANKS;
    EndIf;

    // Si le lot est effacé, ré-initialisation de la désignation et du lot
    If (EcranLigneCodeArticle <> *BLANKS And EcranligneLot = *BLANKS);
        EcranLigneElement = 0;
        EcranLigneDesignationLot = *BLANKS;
    EndIf;

    // Positionnement sur la première ligne en erreur
    If (Erreur = *On And LigneFM2SF < PremiereLigneEnErreur);
        PremiereLigneEnErreur = LigneFM2SF;
    EndIf;

    // Mise à jour de la ligne de sous fichier
    Update FM2SF;

End-Proc;

//-----------------------------------------------------------------------------
///
//         Ecran 2 :  Recherche des valeurs possibles pour la zone où
// se trouve le curseur
//
// - Récupération des informations de la ligne du SF
// - Recherches :
//      -- Code article
///
//-----------------------------------------------------------------------------

Dcl-Proc RechercheEcran2;

    Chain EcranRecupererLigneSFCurseur FM2SF;

    Select;
        // Recherche sur code article
        When EcranZoneCurseur = 'ECOART';
            VMIART.UCOART = EcranLigneCodeArticle;
            VMIART.UCOSTE = EcranCodeSociete;
            VMIART.UCORTR = *BLANK;
            VMIART.ULIDIR = *BLANKS;
            VMIART.ULIAR1 = *BLANKS;
            VMIART.ULIAR2 = *BLANKS;
            PR_VMIART(VMIART.UCOSTE
                    :VMIART.UCORTR
                    :VMIART.UCOART
                    :VMIART.ULIDIR
                    :VMIART.ULIAR1
                    :VMIART.ULIAR2);
            If (VMIART.UCORTR <> '1');
                EcranLigneCodeArticle = VMIART.UCOART;
                EcranLigneLibelleArticle = VMIART.ULIAR1;
                Update FM2SF;
            EndIf;

        // Recherche sur Code Emplacement
        When EcranZoneCurseur = 'ECOEMP' ;
            LDA.ZONETOTALE = *BLANK ;
            Out LDA ;
            VSIEMP.UCOVE1 = 'INT' ;
            VSIEMP.UCOOB1 = 'EMPLA' ;
            VSIEMP.ULIAC1 = *BLANK ;
            VSIEMP.UCOPG1 = *BLANK ;
            VSIEMP.UCORE1 = *BLANK ;
            VSIEMP.UCOSTE = EcranCodeSociete ;
            VSIEMP.UCODEP = EcranCodeDepot ;
            VSIEMP.UCORET = *BLANK ;
            PR_VSIEMP(VSIEMP.UCOVE1
                    :VSIEMP.UCOOB1
                    :VSIEMP.ULIAC1
                    :VSIEMP.UCOPG1
                    :VSIEMP.UCORE1
                    :VSIEMP.UCOSTE
                    :VSIEMP.UCODEP
                    :VSIEMP.UCORET) ;
            In LDA ;
            If (LDA.CodeEmplacement <> *BLANKS);
                EcranLigneEmplacement = LDA.CodeEmplacement ;
                Update FM2SF;
            EndIf;
        Other;
    EndSl;

    // Re-positionnement du curseur là Où il se trouvait
    EcranDeplacerCurseurLigne = fichierDS.ligne;
    EcranDeplacerCurseurColonne = fichierDS.colonne;

    // Re-positionnement de l'affichage au rang de sous fichier où il était
    If (EcranRecupererLigneSFCurseur <> 0);
        EcranLigneSousFichier = EcranRecupererLigneSFCurseur;
    EndIf;

End-Proc;

//-----------------------------------------------------------------------------
///
//         Ecran 2 :  Recherche multi-critères pour la zone Où se trouve
// le curseur
//
// - Récupération des informations de la ligne du SF
// - Recherches :
//      -- Code article
//      -- Code emplacement/Code Lot/Code élément
///
//-----------------------------------------------------------------------------

Dcl-Proc RechercheMultiCriteresEcran2;
    // Suite normale du programme : ré-affichage de l'écran FM2
    Etape = 'AffichageEcran2';

    Chain EcranRecupererLigneSFCurseur FM2SF;

    Select;
        // Recherche sur code article
        When (EcranZoneCurseur = 'ECOART');
            VMRARM.CodeSociete = EcranCodeSociete;
            VMRARM.CodeRetour = *BLANKS;
            VMRARM.CodeArticle = EcranLigneCodeArticle;
            VMRARM.LibelleDIR = *BLANKS;
            VMRARM.Libelle1 = *BLANKS;
            VMRARM.Libelle2 = *BLANKS;
            PR_VMRARM(
                    VMRARM.CodeSociete
                    :VMRARM.CodeRetour
                    :VMRARM.CodeArticle
                    :VMRARM.LibelleDIR
                    :VMRARM.Libelle1
                    :VMRARM.Libelle2 );
            If (VMRARM.CodeRetour <> '1');
                EcranLigneCodeArticle = VMRARM.CodeArticle;
                EcranLigneLibelleArticle = VMRARM.Libelle1;
            EndIf;

        // Recherche sur emplacement / lot / élément
        When (EcranZoneCurseur = 'ECOLOT'
          or EcranZoneCurseur = 'ECOELT');
            If (not VerificationArticleGereParLot());
                Indicateur.FM2_Affichage_Lot = *Off;
                Indicateur.FM2_Affichage_DesignationLot = *Off;
                Indicateur.FM2_Affichage_ElementDeLot = *Off;
                EcranLigneLot = *BLANKS;
                EcranLigneDesignationLot = *BLANKS;
                EcranLigneElement = 0;
                If EcranZoneCurseur = 'ECOLOT' Or EcranZoneCurseur = 'ECOELT';
                    Indicateur.FM2_MSGERR_ArticleNonGereParLot = *On;
                EndIf;
            Else;
                LDA.ZONETOTALE = *BLANKS ;
                out LDA ;
                VSRELO.UCOVE1 = 'REC';
                VSRELO.UCOOB1 = 'EMPLO' ;
                VSRELO.ULIAC1 = *BLANKS ;
                VSRELO.UCOPG1 = *BLANKS ;
                VSRELO.UCORE1 = *BLANKS ;
                VSRELO.UCOSTE = EcranCodeSociete ;
                VSRELO.UCODEP = EcranCodeDepot ;
                VSRELO.UCOART = EcranLigneCodeArticle ;
                VSRELO.UCORET = *BLANKS ;
                PR_VSRELO(
                    VSRELO.UCOVE1:
                    VSRELO.UCOOB1:
                    VSRELO.ULIAC1:
                    VSRELO.UCOPG1:
                    VSRELO.UCORE1:
                    VSRELO.UCOSTE:
                    VSRELO.UCODEP:
                    VSRELO.UCOART:
                    VSRELO.UCORET) ;
                If VSRELO.UCORET <> '1' ;
                    in LDA ;
                    EcranLigneEmplacement = LDA.CodeEmplacement ;
                    EcranLigneLot = LDA.CodeLot ;
                    EcranLigneElement = %uns(LDA.CodeElement) ;
                // Récupération désignation du lot
                    Exec Sql
                         Select TLIMVT
                              Into :ECRANLIGNEDESIGNATIONLOT
                              From VLOART
                              Where TCOART = :ECRANLIGNECODEARTICLE And
                                    TCOLOT = :ECRANLIGNELOT;
                    MessageErreurSQL = 'Select VLOART';
                    GestionErreurSQL(MessageErreurSQL) ;
                EndIf ;
            EndIf;

        When EcranZoneCurseur = 'ECOEMP';
            LDA.ZONETOTALE = *BLANKS ;
            out LDA ;
            VSRELO.UCOVE1 = 'REC';
            VSRELO.UCOOB1 = 'EMPLO' ;
            VSRELO.ULIAC1 = *BLANKS ;
            VSRELO.UCOPG1 = *BLANKS ;
            VSRELO.UCORE1 = *BLANKS ;
            VSRELO.UCOSTE = EcranCodeSociete ;
            VSRELO.UCODEP = EcranCodeDepot ;
            VSRELO.UCOART = EcranLigneCodeArticle ;
            VSRELO.UCORET = *BLANKS ;
            PR_VSRELO(
                    VSRELO.UCOVE1:
                    VSRELO.UCOOB1:
                    VSRELO.ULIAC1:
                    VSRELO.UCOPG1:
                    VSRELO.UCORE1:
                    VSRELO.UCOSTE:
                    VSRELO.UCODEP:
                    VSRELO.UCOART:
                    VSRELO.UCORET) ;
            If VSRELO.UCORET <> '1' ;
                in LDA ;
                EcranLigneEmplacement = LDA.CodeEmplacement ;
                If (VerificationArticleGereParLot());
                    EcranLigneLot = LDA.CodeLot ;
                    EcranLigneElement = %uns(LDA.CodeElement) ;
                    // Récupération désignation du lot
                    Exec Sql
                         Select TLIMVT
                              Into :ECRANLIGNEDESIGNATIONLOT
                              From VLOART
                              Where TCOART = :ECRANLIGNECODEARTICLE And
                                    TCOLOT = :ECRANLIGNELOT;
                    MessageErreurSQL = 'Select VLOART';
                    GestionErreurSQL(MessageErreurSQL) ;
                EndIf;
            EndIf;
        Other;
    EndSl;

    // Re-positionnement du curseur là Où il se trouvait
    EcranDeplacerCurseurLigne = fichierDS.ligne;
    EcranDeplacerCurseurColonne = fichierDS.colonne;

    // Re-positionnement de l'affichage au rang de sous fichier où il était
    If (EcranRecupererLigneSFCurseur <> 0);
        EcranLigneSousFichier = EcranRecupererLigneSFCurseur;
    EndIf;

    Update FM2SF;

End-Proc;

//-----------------------------------------------------------------------------
///
//        Ecran FIN Validation : Affichage de l'écran de validation
// avec ses 5 Options
//
// - Si au moins une erreur a été détectée, interdiction des options
// '1' et '3' idem pour la visu
// - Suite du programme en fonction du choix de l'utilisateur
//      -- '0' : F12
//      -- '1' : mise à jour et retour écran garde
//      -- '2' : pas de mise à jour et retour écran de garde
//      -- '3' : mise à jour et fin de programme
//      -- '4' : fin de programme sans mise à jour
//      -- '5' : reprise
///
//-----------------------------------------------------------------------------

Dcl-Proc AffichageEcranValidation;
    // Suite normale du programme : Fin
    Etape = 'Fin';

    // Si au moins une erreur a été détectée ou qu'aucun article a été saisi
    // Interdiction des options '1' et '3' idem pour la visu
    Select;
        When (Erreur = *On Or SaisieUtilisateur = *Off);
            EcranFinChoix1 = '*';
            EcranFinChoix2 = '2';
            EcranFinChoix3 = '*';
            EcranFinChoix4 = '4';
            EcranFinChoixAction =  5;
        When £CodeVerbe = 'VIS';
            EcranFinChoix1 = '*';
            EcranFinChoix2 = '2';
            EcranFinChoix3 = '*';
            EcranFinChoix4 = '4';
            EcranFinChoixAction = 2;
        Other;
            EcranFinChoix1 = '1';
            EcranFinChoix2 = '2';
            EcranFinChoix3 = '3';
            EcranFinChoix4 = '4';
            EcranFinChoixAction =  1;
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
            Etape = 'AffichageEcran2';
        When EcranFinChoixAction = 1 AND EcranFinChoix1 <> '*';
            £CodeRetour = '1';
            EcritureDonnees();
        When EcranFinChoixAction = 2 AND EcranFinChoix2 <> '*';
            £CodeRetour = '2';
        When EcranFinChoixAction = 3 AND EcranFinChoix3 <> '*';
            £CodeRetour = '3';
            EcritureDonnees();
        When EcranFinChoixAction = 4 AND EcranFinChoix4 <> '*';
            £CodeRetour = '4';
        Other;
            Etape = 'AffichageEcranValidation';
    EndSl;
End-Proc;

//-----------------------------------------------------------------------------
///
//                            EcritureDonnees : Ecriture des données saisies
//
// - Sauvegarde des données dans la table KPBF01
///
//-----------------------------------------------------------------------------

Dcl-Proc EcritureDonnees;
    Etape = 'Fin';

    For i = 1 to 50 ;
        Chain i FM2SF;

        If (%Found And EcranLigneCodeArticle <> *BLANK);
            // Attribution des valeurs
            Exec Sql
                 Insert Into KPBF01
                      Values (:i,
                              :ECRANLIGNECODEARTICLE,
                              :ECRANLIGNELIBELLEARTICLE,
                              :ECRANLIGNEQUANTITEARTICLE,
                              :ECRANCODEUNITE,
                              :ECRANLIGNEPRIXUNITAIREARTICLE,
                              :ECRANLIGNEEMPLACEMENT,
                              :ECRANLIGNELOT,
                              :ECRANLIGNEDESIGNATIONLOT,
                              :ECRANLIGNEELEMENT,
                              :ECRANLIGNEPRIXTOTAL);
            MessageErreurSQL = 'INSERT KPBF01';
            GestionErreurSQL(MessageErreurSQL) ;
        EndIf;
    EndFor;
End-Proc;

//-----------------------------------------------------------------------------
///
//         LotTrouve : Vérification que le lot existe
//
// - Permet de vérifier que le lot existe
//
// @return *On si existe
///
//-----------------------------------------------------------------------------

Dcl-Proc LotTrouve;
    Dcl-Pi *N Ind End-Pi;

    Dcl-S Trouve Ind;

    Exec SQL
        Select Case
                When Count(ECOLOT) > 0 Then 1
            Else 0
            End
        Into :Trouve
        From VLOELT
        Where ECOART = :ECRANLIGNECODEARTICLE And
            ECOLOT = :ECRANLIGNELOT;

    Return Trouve;
End-Proc;

//-----------------------------------------------------------------------------
///
//         ElementTrouve : Vérification si l'élément existe
//
// - Permet de vérifier si l'élément existe
//
// @return *On si existe
///
//-----------------------------------------------------------------------------

Dcl-Proc ElementTrouve;
    Dcl-Pi *N Ind End-Pi;

    Dcl-S Trouve Ind;

    Exec SQL
        Select Case
                When Count(ENULOT) > 0 Then 1
            Else 0
            End
        Into :Trouve
        From VLOELT
        Where ECOART = :EcranLigneCodeArticle
               And ECOLOT = :EcranLigneLot
               And ENULOT = :EcranLigneElement;
    MessageErreurSQL = 'Err : ElementTrouve' ;
    GestionErreurSQL(MessageErreurSQL) ;

    Return Trouve;
End-Proc;

//-----------------------------------------------------------------------------
///
// VerificationArticleGereParLot : Vérification si l'article est géré par lot
//
// - Permet de vérifier si l'article est géré par lot
//
// @return *On si l'article est géré par lot
///
//-----------------------------------------------------------------------------

Dcl-Proc VerificationArticleGereParLot;
    Dcl-Pi *N Ind End-Pi;

    Dcl-S Trouve Ind;

    Exec SQL
          Select
               Case
                    When ACOGLO Like 'X' Then 1
               Else 0
          End
          Into :Trouve
          From VARTIC
          Where ACOART = :ECRANLIGNECODEARTICLE;
    MessageErreurSQL = 'Err : Verification Article Gere Par Lot' ;
    GestionErreurSQL(MessageErreurSQL) ;
    Return Trouve;
End-Proc;

//-----------------------------------------------------------------------------
///
//
//                                      ReinitialisationIndicateurFM2
//
// - Réinitialise tous les indicateurs d'erreurs à Off
///
//-----------------------------------------------------------------------------

Dcl-Proc ReinitialisationIndicateurFM2;
    //Réinitialisation des indicateurs d'erreurs
    Indicateur.FM2_IV_CodeArticleInvalide = *Off;
    Indicateur.FM2_IV_ArticleNonGere = *Off;
    Indicateur.FM2_IV_Quantiteobligatoire = *Off;
    Indicateur.FM2_IV_QuantiteSuperieureAuDispo = *Off;
    Indicateur.FM2_IV_Lot = *Off;
    Indicateur.FM2_IV_Element = *Off;
    Indicateur.FM2_IV_Emplacement = *Off;

    Indicateur.FM2_MSGERR_CodeArticleInvalide = *Off;
    Indicateur.FM2_MSGERR_ArticleNonGere = *Off;
    Indicateur.FM2_MSGERR_QuantiteObligatoire = *Off;
    Indicateur.FM2_MSGERR_QuantiteSuperieureAuDispo = *Off;
    Indicateur.FM2_MSGERR_LotManquant = *Off;
    Indicateur.FM2_MSGERR_LotInconnu = *Off;
    Indicateur.FM2_MSGERR_ElementInconnu = *Off;
    Indicateur.FM2_MSGERR_ElementManquant = *Off;
    Indicateur.FM2_MSGERR_EmplacementManquant = *Off;
    Indicateur.FM2_MSGERR_EmplacementInconnu = *Off;
    Indicateur.FM2_MSGERR_ArticleNonGereParLot = *Off;

    SaisieUtilisateur = *Off;
End-Proc;

//-----------------------------------------------------------------------------
///
//                                          GestionErreurSQL
//
// - Affiche à l'écran s'il y a une erreur SQL
//
// @param Message d'erreur
///
//-----------------------------------------------------------------------------

Dcl-Proc GestionErreurSQL ;
    Dcl-Pi *N;
        MessageErreurSQL     Char(52);
    End-Pi;

    If (SQLCode <> 0 And SQLCode <> 100) ;
        DSPLY MessageErreurSQL;
        DSPLY ('SQLCode : ' + %CHAR(SQLCode));
        DSPLY ('SQLState : ' + %CHAR(SQLState));
    EndIf ;
End-Proc;

 