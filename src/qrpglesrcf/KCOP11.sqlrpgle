**free
Ctl-opt Option(*srcstmt:*nodebugio ) AlwNull(*usrctl) UsrPrf(*owner)
        DatFmt(*eur) DatEdit(*dmy) TimFmt(*hms) dftactgrp(*no);

// --------------------------------------------------------------
//       NOM        : KCOP11              TYPE : Interactif & Batch
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
//               - VRESTK : Table des mouvements de stocks
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
//        AU   : 13/12/2024
//
// ---------------------------------------------------------------------
Dcl-F KCOP11E  WorkStn
               SFile(GESTIONSFL:fichierDS.rang_sfl)//SFILE(Format:rang)
               InfDS(fichierDS)//Permet d'avoir des informations sur le sous-fichier en cours
               IndDs(Indicateur)
               Alias;//pour mettre les indicateurs dans une DS et les nommer

Dcl-F KCOP11PM Printer OfLind(Ind_FinDePagePRTF) alias;

// --- Tables -------------------------------------------------------
//Entête des livraisons/retour
Dcl-Ds KCOENT_t extname('KCOENT') qualified template;
End-Ds;

//Lignes des livraisons/retour
Dcl-Ds KCOLIG_t extname('KCOLIG')  qualified template alias;
End-Ds;
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

//TABVV XCOPAR
Dcl-Ds ParametresConsigne qualified;
    XLIPAR Char(100);
    TypeArticle Char(1) Overlay(XLIPAR);
    CodeMouvementEntree Char(2) Overlay(XLIPAR:*NEXT);
    TopPrealimentationRetour Char(1) Overlay(XLIPAR:*NEXT);
    NombreExemplairesBL Char(2) Overlay(XLIPAR:*NEXT);
    CodeDepotConsignes Char(3) Overlay(XLIPAR:*NEXT);
    CodeMouvementSortie Char(2) Overlay(XLIPAR:*NEXT);
    CompteurBLConsignes Char(8) Overlay(XLIPAR:*NEXT);
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




// --- Appel de PGM  --------------------------------------------------
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

/UNDEFINE PR_GOAFENCL
/UNDEFINE PR_GOASER
/UNDEFINE PR_VMRICL
/UNDEFINE PR_VMTSTP
/UNDEFINE PR_VSLMVT2 


// Permet de faire des commandes CL
Dcl-Pr QCMDEXC ExtPgm('QCMDEXC') ;
    cde Char(200) const;
    cdl Packed(15:5) const;
End-Pr ;


// Prototype pour K£PIMP 
Dcl-Pr KPIMP extpgm('K£PIMP');
    p_coedi char(8);
    p_comod char(2);
    p_coprf char(10);
    p_noutq char(10);
    p_nbexj char(2);
    p_nbexs char(2);
    p_nbexm char(2);
    p_suspe char(4);
    p_conse char(4);
End-Pr;


// --- Variables -------------------------------------------------------
Dcl-S NombreTotalLignesSF Packed(4:0);
Dcl-S Fin ind;
Dcl-S FinFenetre ind;
Dcl-S Refresh ind;
Dcl-S CommandeCL varChar(200);

// --- Constantes -------------------------------------------------------
Dcl-C LIVRAISON 'LIVRAISON';
Dcl-C RETOUR 'RETOUR';
Dcl-C CREATION 'CREATION';
Dcl-C MODIFICATION 'MODIFICATION';
Dcl-C VISUALISATION 'VISUALISATION';
Dcl-C TABVV_PARAMETRESCONSIGNE 'XCOPAR';
Dcl-C TABVV_FLAG_REMISE_CLIENT 'AFFREM';
Dcl-C TABLE_CHARTREUSE_MOUVEMENT_STOCK_NUM 'NUMT';
Dcl-C QUOTE '''';
Dcl-C ESPACE ' ';
Dcl-C POURCENTAGE '%';
Dcl-S CODEVERBE Char(3) Inz('GER');
Dcl-S CODEOBJET Char(6) Inz('LIVCON');
Dcl-S PRTF_CODE_MODULE Char(2) Inz('CO');  // Code module pour KPIMP
Dcl-S PRTF_CODE_EDITION Char(10) Inz('KCOP11PM'); // Code édition pour KPIMP
Dcl-S ENTREE_STOCK char(1) Inz('E');
Dcl-S SORTIE_STOCK char(1) Inz('S');

// --- Data-structures Indicateurs--------------------------------------
Dcl-Ds Indicateur qualified;
  // Contrôles principaux
    GESTIONCTL_SousFichierDisplay           Ind Pos(51);  
    GESTIONCTL_SousFichierDisplayControl    Ind Pos(52);
    GESTIONCTL_SousFichierClear             Ind Pos(53);
    GESTIONCTL_SousFichierEnd               Ind Pos(54);

  //Messages d erreurs
    GESTIONCTL_SFLMSG_QuantiteSuperieureAuDispo Ind Pos(30); 

  // Indicateurs affichage (DSPATR)
    GESTIONBAS_MasquerMessageErreur           Ind Pos(82); 
    GESTIONBAS_MasquerMessageInfo             Ind Pos(83);

    GESTIONSFL_MasquerQuantiteRetournee       Ind Pos(40);
    GESTIONSFL_ProtegerQuantiteRetournee      Ind Pos(41);
    GESTIONSFL_ProtegerQuantiteLivree         Ind Pos(42);
    GESTIONSFL_RI_QuantiteSuperieureAuDispo   Ind Pos(43);
End-Ds;


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
    £NumeroBLConsignes                         Packed(8:0);//Numéro du bon de livraison de consignes
    £Operation                              Char(30);
    £Mode                                   Char(30);
    // Facultatif : Numéro de la livraison associée à la livraison/retour de consignes
    £NumeroLivraison                        Packed(8:0);
    £CodeClient                             Char(9) Options(*NoPass);
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

    // Affichage de l écran avec attente de saisie
    Write GESTIONBAS;
    ExFmt GESTIONCTL;

    // Traitement des actions
    Select;
        When fichierDS.TouchePresse = F2;
            AffichageFenetreUtilisateur(CODEVERBE:CODEOBJET);

            //Gestion de la fin et mise à jour
        When fichierDS.TouchePresse = F3;
            ChargementEcranValidation();
            FinFenetre = *Off;
            DoW not FinFenetre;
                
                EXFMT FMFIN;
                    // Suite du programme en fonction du choix de l utilisateur
                    // 1 : mise à jour et retour écran gar
                    // 2 : pas de mise à jour et retour écran gar
                    // 3 : mise à jour, gestion des écritures en fonction de l action et fin
                    // 4 : fin de programme sans mise à j.
                    // 5 : reprise
                Select;
                    When fichierDS.TouchePresse = F12 Or 
                    (EcranFinChoixAction = 2 AND EcranFinChoix2 <> '*');
                        FinFenetre=*On;

                    When EcranFinChoixAction = 1 AND EcranFinChoix1 <> '*';
                        If Verification();
                            EcritureTables();
                                //Gestion de l édition du PRTF
                            If £Operation = LIVRAISON And (£Mode=MODIFICATION OR £Mode=CREATION);
                                EditionPRTF();
                            EndIf;
                            Refresh=*On;
                        Else;
                            Indicateur.GESTIONBAS_MasquerMessageErreur=*off;
                            EcranMessageErreur = 'Erreur de saisie';
                        EndIf;
                        FinFenetre=*On;

                    When EcranFinChoixAction = 3 AND EcranFinChoix3 <> '*';
                        // Vérification et écriture dans tous les cas sauf visualisation
                        If £Mode <> VISUALISATION;

                            If Verification();
                                // On incrémente 
                                // le compteur du numéro de bon de livraison 
                                // en cas de création
                                If (£Operation = LIVRAISON and £Mode = CREATION)
                                OR (£Operation = RETOUR and £Mode = CREATION 
                                and £NumeroLivraison = 0 );
                                    IncrementCompteurBL();
                                EndIf;
                                
                                EcritureTables();
                                //Gestion de l édition du PRTF
                                If £Operation = LIVRAISON 
                                And (£Mode=MODIFICATION OR £Mode=CREATION);
                                    EditionPRTF();
                                EndIf;
                                Fin = *On;  // Terminer le programme
                            Else;
                                Indicateur.GESTIONBAS_MasquerMessageErreur=*off;
                                EcranMessageErreur = 'Erreur de saisie';
                                FinFenetre = *On;
                                Refresh = *On;
                                // Ne pas terminer si erreur
                            EndIf;
                        Else;
                            // En visualisation, simplement terminer
                            Fin = *On;
                        EndIf;
                        FinFenetre = *On;

                    When EcranFinChoixAction = 4 AND EcranFinChoix4 <> '*';
                        FinFenetre = *On;
                        Fin = *On;
                            
                    When EcranFinChoixAction = 5;
                        FinFenetre = *On;
                        Refresh=*On;

                    Other;
                EndSl;

           
            EndDo;

        When fichierDS.TouchePresse = F6;
            AffichageFenetreServices();

        When fichierDS.TouchePresse = F12;
            Fin=*On;

        When  fichierDS.touchePresse = ENTREE;
            If £Mode <> VISUALISATION;
                If not Verification();
                    Indicateur.GESTIONBAS_MasquerMessageErreur=*off;
                    EcranMessageErreur = 'Erreur de saisie';
                EndIf;
            EndIf;
        Other;
    EndSl;

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
//    - Messages d erreur et d information
//
// 2. Récupération des paramètres société/consignes
//    - Code et libellé société (TABVV STE)
//    - Bibliothèque de fichiers 
//    - Paramètres consignes (XCOPAR)
//
// 3. Initialisation écran
//    - Masquage messages 
//    - Préparation sous fichier
//    - Initialisation en tetes (client, livraison, facture, etc.)
//    - RAZ des filtres articles
//
// 4. Récupération des informations du client
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
    Indicateur.GESTIONBAS_MasquerMessageErreur = *On;
    Indicateur.GESTIONBAS_MasquerMessageInfo = *On;
    ECRANMESSAGEERREUR = *Blanks;
    ECRANMESSAGEINFO = *Blanks;
    ECRANNUMEROBLCONSIGNES = £NumeroBLConsignes;

   // Sous-fichier
    Indicateur.GESTIONCTL_SousFichierClear = *On;
    Write GESTIONCTL;
    Indicateur.GESTIONCTL_SousFichierClear = *Off;
    Indicateur.GESTIONCTL_SousFichierDisplay = *On;
    Indicateur.GESTIONCTL_SousFichierEnd = *On;
    Indicateur.GESTIONCTL_SousFichierDisplayControl = *On;

   // En-têtes
   //Dans le cas d une création de livraison : 
    If (£Mode = CREATION And £Operation=LIVRAISON);
        EcranNumeroEdition = 0;

        Exec SQL
            SELECT DISTINCT 
                V.ENULIV as numeroLivraisonVENTLV,
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

    //Dans le cas d'une création d'un retour sans livraison
    Elseif (£Mode = CREATION and £Operation = RETOUR and £NumeroLivraison = 0) ;
        //Initialisation des variables
        ECRANNUMEROLIVRAISON = 0;
        ECRANDATELIVRAISON = %DATE('1940-01-01');
        ECRANNUMEROFACTURE = 0;
        ECRANNUMEROTOURNEE = *BLANKS;
        ECRANNUMEROEDITION = 0;
        ECRANCODECLIENT = £CodeClient;
        

        //Récupération des informations clients
        exec SQL
            Select CLIDES, CLISOC
            Into :ECRANRAISONSOCIALECLIENT, :EcranNomCommercialClient
            From CLIENT
            Where CCOCLI = :EcranCodeClient;
        GestionErreurSQL();

    Else;
        //On récupère les informations également dans la table KCOENT
        exec SQL
            SELECT DISTINCT 
            K.NUMEROLIVRAISON as NumeroLivraisonKCOENT,
            K.NombreEdition as numeroEdition,
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
    Where K.NumeroBLConsignes = :£NumeroBLConsignes;
        GestionErreurSQL();
    EndIf;


    //Gestion des affichages/protections
    Select;
        when (£Mode = CREATION Or £Mode = MODIFICATION) And £Operation = LIVRAISON;
            Indicateur.GESTIONSFL_ProtegerQuantiteLivree=*Off;
            Indicateur.GESTIONSFL_ProtegerQuantiteRetournee=*On;
            Indicateur.GESTIONSFL_MasquerQuantiteRetournee=*On;

        when (£Mode = CREATION Or £Mode = MODIFICATION) And £Operation = RETOUR;
            Indicateur.GESTIONSFL_ProtegerQuantiteLivree=*On;
            Indicateur.GESTIONSFL_ProtegerQuantiteRetournee=*Off;
            Indicateur.GESTIONSFL_MasquerQuantiteRetournee=*Off;

        when £Mode = VISUALISATION;
            Indicateur.GESTIONSFL_ProtegerQuantiteLivree=*On;
            Indicateur.GESTIONSFL_ProtegerQuantiteRetournee=*On;
            Indicateur.GESTIONSFL_MasquerQuantiteRetournee=*Off;

        other;
        // handle other conditions
    EndSl;
    
    //Récupération & affectation des données client
    VMRICL.UCOSTE = Societe.Code;
    VMRICL.UCOCLI = ECRANCODECLIENT;
    PR_VMRICL(VMRICL.UCOSTE
                    :VMRICL.UCOCLI
                    :VMRICL.ULISOC
                    :VMRICL.ULIDES
                    :VMRICL.ULIRUE
                    :VMRICL.ULIVIL
                    :VMRICL.UCOPOS
                    :VMRICL.ULIBDI
                    :VMRICL.UCOPAY
                    :VMRICL.UCOLAN
                    :VMRICL.UCOARC
                    :VMRICL.UCORE1
                    :VMRICL.UCORE2
                    :VMRICL.UTXCO1
                    :VMRICL.UTXCO2
                    :VMRICL.URACDE
                    :VMRICL.UCOLCP
                    :VMRICL.UCOLIV
                    :VMRICL.UCOTRA
                    :VMRICL.UCOBLI
                    :VMRICL.UFGECL
                    :VMRICL.UCOFAC
                    :VMRICL.UTXESC
                    :VMRICL.UCOPAG
                    :VMRICL.UCODEV
                    :VMRICL.UCOECH
                    :VMRICL.UCOMRG
                    :VMRICL.UCOTAX
                    :VMRICL.UTYFAC
                    :VMRICL.UMTMFA
                    :VMRICL.UMTMFP
                    :VMRICL.UCOCTX
                    :VMRICL.UMTCAU
                    :VMRICL.UMTCOF
                    :VMRICL.UCOCEC
                    :VMRICL.UMTSTA
                    :VMRICL.UMTENC
                    :VMRICL.UMTCHT
                    :VMRICL.UCOCTR
                    :VMRICL.UCOTAR
                    :VMRICL.UCOCOV
                    :VMRICL.UTXREM
                    :VMRICL.UNUCOL
                    :VMRICL.UCORET
                    :VMRICL.ULIEXP
                    :VMRICL.UCOEDV);
    ECRANCLIENTADRESSE = VMRICL.ULIRUE;
    ECRANCLIENTVILLE = VMRICL.ULIVIL;
End-Proc;


///
// ChargerSousFichier()
// Charge le sous-fichier 
// Initialise les positions d affichage et le curseur
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
    Indicateur.GESTIONCTL_SousFichierClear = *On;
    Write GESTIONCTL;
    Indicateur.GESTIONCTL_SousFichierClear = *Off;

    //Initialisation des messages erreur/info
    Indicateur.GESTIONBAS_MasquerMessageErreur = *On;  
    ECRANMESSAGEERREUR = *BLANKS;
    Indicateur.GESTIONBAS_MasquerMessageInfo = *On;
    ECRANMESSAGEINFO = *BLANKS;
    Indicateur.GESTIONCTL_SFLMSG_QuantiteSuperieureAuDispo = *Off;

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

    If SQLCode = 100; //Aucun enregistrement n a été trouvé
        ECRANMESSAGEERREUR = 'Aucun article trouvé';
        Indicateur.GESTIONBAS_MasquerMessageErreur = *Off;
        
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
                Where NumeroBLConsignes = :£NumeroBLConsignes 
                AND codeArticle = :EcranLigneCodeArticle;
               
                // Si on est en création de retour, 
                // on vérifie le paramètre de consignes de pré-alimentation
                // Si il est à "O", on indique les valeurs de retour
                //  identique au valeurs de quantité livrée
            If £Mode = CREATION And £Operation = RETOUR 
                And ParametresConsigne.TopPrealimentationRetour = 'O';
                EcranLigneQuantiteRetournee = EcranLigneQuantiteLivree;
            EndIf;
                
            If SQLCode = 100; //Pas d enregistrement trouvé
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

    // Pour afficher un sous-fichier vide, 
    //on ne doit PAS activer l affichage du sous-fichier si il est vide 
    If NombreTotalLignesSF > 0;
        Indicateur.GESTIONCTL_SousFichierDisplay = *On;
    Else;
        Indicateur.GESTIONCTL_SousFichierDisplay = *Off;
    EndIf;
    
    Indicateur.GESTIONCTL_SousFichierDisplayControl = *On;
    Indicateur.GESTIONCTL_SousFichierEnd = *On;
    
    // Positionnement initial
    EcranLigneSousFichier = 1;
    EcranDeplacerCurseurLigne = 7;
    EcranDeplacerCurseurColonne = 61;  
End-Proc;

///
// Création clause Where
// Permet de construire la clause where en fonction des filtres
// Filtres disponibles :
//  - type article doit être celui de la table XCOPAR
//
// @Return : ClauseWhere char(2048)
///
Dcl-Proc CreationClauseWhere;
    Dcl-Pi *n Char(2048);
    End-Pi;

    Dcl-S ClauseWhere char(2048);

    // Filtre sur le type article
    ClauseWhere = 'WHERE ACOTYA = '+ QUOTE 
    + ParametresConsigne.TypeArticle + QUOTE;

    Return ClauseWhere;
End-Proc;

///
// ChargementEcranValidation
// Gère les différentes options possibles pour une fin de travail du programme
//
///
Dcl-Proc ChargementEcranValidation;
    Dcl-Pi *n;
    End-Pi;

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
End-Proc;

///
// Verification
//  - La quantité saisie n est pas supérieure à la quantité en stock dans le dépôt
///
Dcl-Proc Verification;

    Dcl-Pi *n Ind end-pi;

    Dcl-S Erreur	Ind Inz(*Off);
    Dcl-S i	Zoned(4:0);
    Dcl-S KCOLIG_AncienneQuantiteLivree Packed(4:0); 
    Dcl-S CurseurPositionne Ind Inz(*Off);


    //Initialisation des indicateurs d erreurs généraux
    Indicateur.GESTIONCTL_SFLMSG_QuantiteSuperieureAuDispo = *Off;
    Indicateur.GESTIONBAS_MasquerMessageErreur = *On;
    Indicateur.GESTIONBAS_MasquerMessageInfo = *On;

    // Boucle de vérification
    For i = 1 to NombreTotalLignesSF;
        Chain i GESTIONSFL;

        //Initialisation des indicateurs d erreurs par lignes
        Indicateur.GESTIONSFL_RI_QuantiteSuperieureAuDispo = *Off;

        //   - la quantité doit être inférieure au stock disponible
        If ( Erreur = *Off And EcranLigneQuantiteLivree <> 0);

            Select;
                when £Mode=CREATION And (£Operation = LIVRAISON OR £Operation = RETOUR);
                    VMTSTP.UQTUNG = EcranLigneQuantiteLivree;
        
                when £Mode=MODIFICATION And 
                (£Operation = LIVRAISON OR £Operation = RETOUR);
                //On doit récupérer l ancienne quantité saisie 
                //et si elle est supérieur à la quantité actuellement saisie, 
                //on vérifie si la différence de cette quantité est bien disponible dans le stock
                    Exec SQL
                    Select QUANTITELIVREE
                    Into :KCOLIG_AncienneQuantiteLivree
                    From KCOLIG
                    Where NumeroBLConsignes = :£NumeroBLConsignes
                    And CodeArticle = :EcranLigneCodeArticle;
                    If SQLCODE = 0;
                        If (EcranLigneQuantiteLivree > KCOLIG_AncienneQuantiteLivree);
                            VMTSTP.UQTUNG = 
                            EcranLigneQuantiteLivree - KCOLIG_AncienneQuantiteLivree;
                        Else;
                            VMTSTP.UQTUNG = 0;
                        EndIf;
                    ElseIf SQLCODE = 100;
                    //Aucune ligne trouvée
                        VMTSTP.UQTUNG = EcranLigneQuantiteLivree;
                    Else;
                        GestionErreurSQL();
                    EndIf;


                other;
            EndSl;

            VMTSTP.UCOSTE = Societe.Code;
            VMTSTP.UCODEP = ParametresConsigne.CodeDepotConsignes;
            VMTSTP.UCOART = EcranLigneCodeArticle;
            VMTSTP.UCORET = *BLANKS;
            VMTSTP.UQTRES = 0;//Quantité restante

        //Appel du programme pour savoir si la quantité est disponible en stock
            If VMTSTP.UQTUNG > 0 ;

                PR_VMTSTP(
                        VMTSTP.UCoSTE
                        :VMTSTP.UCODEP
                        :VMTSTP.UCOART
                        :VMTSTP.UQTUNG
                        :VMTSTP.UCORET
                        :VMTSTP.UQTRES);
                If (VMTSTP.UCoRET = '1');
                    Indicateur.GESTIONSFL_RI_QuantiteSuperieureAuDispo = *On;
                    Indicateur.GESTIONCTL_SFLMSG_QuantiteSuperieureAuDispo = *On;
                    Erreur = *On;

                // Positionne le curseur sur la première erreur trouvée
                    If Not CurseurPositionne;
                        //+6 car le sous-fichier commence à la ligne 7
                        EcranDeplacerCurseurLigne = i + 6;
                        // Colonne de la quantité livrée
                        EcranDeplacerCurseurColonne = 61; 
                        CurseurPositionne = *On;
                    EndIf;
                Else;
                EndIf;
            EndIf;
        EndIf;
       
        Update GESTIONSFL;
    EndFor;

    Return not Erreur;
End-Proc;


/// ------------------------------------------------------------------------------------
// EcritureTables()
//
// Ecris dans les tables suivantes :
// Fichier des entêtes des livraisons de consignes : KCOENT
// Fichier des lignes des livraisons de consignes : KCOLIG
// Fichier des cumuls de consignes par client : KCOCUM
// Fichier des mouvements de stocks en attente : VRESTK
// Appel de la procédure d intégration des mouvements de stocks dans VRESTK
/// ------------------------------------------------------------------------------------
Dcl-Proc EcritureTables;
    Dcl-S i Zoned(4:0);
    Dcl-Ds p_EcritureKCOCUM qualified;
        CodeClient                Char(9);
        CodeArticle               Char(20);
        QuantiteLivree            Packed(4:0);
        QuantiteRetournee         Packed(4:0);
        AncienneQuantiteLivree    Packed(4:0);
        AncienneQuantiteRetournee Packed(4:0);
    End-Ds;

    //VRESTK
    Dcl-S QuantiteVRESTK Packed(4:0);

    //KCOLIG
    Dcl-Ds OLD_KCOLIG likeDs(KCOLIG_t);
    Dcl-Ds NEW_KCOLIG likeDs(KCOLIG_t);
    Dcl-S KCOLIGExiste Ind;

    //Initialisation des valeurs constantes 
    //de la table des mouvements de stocks en attente de traitement
    InitialisationVRESTK();

    //Ecriture de la table des entêtes des livraisons
    EcritureKCOENT();

    //INIT KCOLIG
    NEW_KCOLIG.NumeroBLConsignes = ECRANNUMEROBLCONSIGNES; 

    For i = 1 to NombreTotalLignesSF;
        Chain i GESTIONSFL;

        Select;
            // -- CREATION LIVRAISON
            when £Mode = CREATION And £Operation = LIVRAISON ANd EcranLigneQuantiteLivree > 0;
                // --- CREATION LIVRAISON - KCOCUM
                p_EcritureKCOCUM.CodeClient = EcranCodeClient;
                p_EcritureKCOCUM.CodeArticle = EcranLigneCodeArticle;
                p_EcritureKCOCUM.QuantiteLivree = EcranLigneQuantiteLivree;
                p_EcritureKCOCUM.QuantiteRetournee = 0;
                p_EcritureKCOCUM.AncienneQuantiteLivree = 0;
                p_EcritureKCOCUM.AncienneQuantiteRetournee = 0; 

                EcritureKCOCUM(p_EcritureKCOCUM.CodeClient
                        :p_EcritureKCOCUM.CodeArticle
                        :p_EcritureKCOCUM.QuantiteLivree
                        :p_EcritureKCOCUM.QuantiteRetournee
                        :p_EcritureKCOCUM.AncienneQuantiteLivree
                        :p_EcritureKCOCUM.AncienneQuantiteRetournee);

                    // --- CREATION LIVRAISON KCOLIG
                NEW_KCOLIG.CodeArticle = EcranLigneCodeArticle;
                NEW_KCOLIG.QuantiteLivree = EcranLigneQuantiteLivree;
                NEW_KCOLIG.QuantiteRetournee = EcranLigneQuantiteRetournee;
                KCOLIGExiste = *Off;

                EcritureKCOLIG(NEW_KCOLIG:KCOLIGExiste);


                    // --- CREATION LIVRAISON  - VRESTK
                EcritureVRESTK(
                            EcranLigneCodeArticle 
                            :EcranLigneQuantiteLivree 
                            :SORTIE_STOCK);



            // -- CREATION RETOUR
            when £Mode = CREATION And £Operation = RETOUR;

                If £NumeroLivraison = 0; //Retour sans livraison
                    OLD_KCOLIG.QuantiteLivree = 0;
                    OLD_KCOLIG.QuantiteRetournee = 0;
                    KCOLIGExiste = *Off;
                Else; // Retour ayant eu une livraison
                    //Initialisation : Récupération des anciennes valeurs de livraison
                    Exec SQL
                        select quantiteLivree
                        Into 
                            :OLD_KCOLIG.QuantiteLivree
                        From KCOLIG
                        Where NumeroBLConsignes = :ECRANNUMEROBLCONSIGNES 
                        And CodeArticle = :EcranLigneCodeArticle;
                    If SQLCode = 100;//Aucune donnée trouvée
                        OLD_KCOLIG.QuantiteLivree = 0;
                        OLD_KCOLIG.QuantiteRetournee = 0;
                        KCOLIGExiste = *Off;
                    Else;
                        KCOLIGExiste = *On;
                        GestionErreurSQL();
                    EndIf;
                EndIf;

                // On ne gère que les cas où il y a eu une modification sur la livraison
                // Ou une quantité a été saisie sur un retour
                If (OLD_KCOLIG.QUANTITELIVREE <> EcranLigneQuantiteLivree
                        OR EcranLigneQuantiteRetournee > 0);

                        // -- CREATION RETOUR KCOCUM
                    p_EcritureKCOCUM.CodeClient = EcranCodeClient;
                    p_EcritureKCOCUM.CodeArticle = EcranLigneCodeArticle;
                    p_EcritureKCOCUM.QuantiteLivree = EcranLigneQuantiteLivree;
                    p_EcritureKCOCUM.QuantiteRetournee = EcranLigneQuantiteRetournee;
                    p_EcritureKCOCUM.AncienneQuantiteLivree = OLD_KCOLIG.QuantiteLivree;
                    p_EcritureKCOCUM.AncienneQuantiteRetournee = 0; 
                    EcritureKCOCUM(p_EcritureKCOCUM.CodeClient
                        :p_EcritureKCOCUM.CodeArticle
                        :p_EcritureKCOCUM.QuantiteLivree
                        :p_EcritureKCOCUM.QuantiteRetournee
                        :p_EcritureKCOCUM.AncienneQuantiteLivree
                        :p_EcritureKCOCUM.AncienneQuantiteRetournee);


                        // --- CREATION RETOUR - KCOLIG
                    NEW_KCOLIG.CodeArticle = EcranLigneCodeArticle;
                    NEW_KCOLIG.QuantiteLivree = EcranLigneQuantiteLivree;
                    NEW_KCOLIG.QuantiteRetournee = EcranLigneQuantiteRetournee;

                    EcritureKCOLIG(NEW_KCOLIG:KCOLIGExiste);
                        
                        // --- CREATION RETOUR - VRESTK
                        // ---- CREATION RETOUR - VRESTK - Quantité livrée
                    If OLD_KCOLIG.QUANTITELIVREE <> EcranLigneQuantiteLivree;
                        If OLD_KCOLIG.QuantiteLivree >0;
                            QuantiteVRESTK = OLD_KCOLIG.QuantiteLivree * -1;
                            EcritureVRESTK(EcranLigneCodeArticle 
                            : QuantiteVRESTK  
                            : SORTIE_STOCK);
                        EndIf;
                        If EcranLigneQuantiteLivree > 0;
                            EcritureVRESTK(EcranLigneCodeArticle 
                            : EcranLigneQuantiteLivree 
                            : SORTIE_STOCK);
                        EndIf;
                    EndIf;

                        // ---- CREATION RETOUR - VRESTK - Quantité Retournée
                    If EcranLigneQuantiteRetournee > 0 ;
                        EcritureVRESTK(
                                    EcranLigneCodeArticle 
                                    :EcranLigneQuantiteRetournee 
                                    :ENTREE_STOCK);
                    EndIf;
                EndIf;


            when £Mode = MODIFICATION;
                //Récupération des anciennes valeurs saisies
                Exec SQL
                    select quantiteLivree,
                        quantiteRetournee
                    Into 
                        :OLD_KCOLIG.QuantiteLivree,
                        :OLD_KCOLIG.QuantiteRetournee
                    From KCOLIG
                    Where NumeroBLConsignes = :ECRANNUMEROBLCONSIGNES 
                    And CodeArticle = :EcranLigneCodeArticle;
                If SQLCode = 100;//Aucune donnée trouvée
                    OLD_KCOLIG.QuantiteLivree = 0;
                    OLD_KCOLIG.QuantiteRetournee = 0;
                    KCOLIGExiste = *Off;
                Else;
                    KCOLIGExiste = *On;
                    GestionErreurSQL();
                EndIf;

                // -- MODIFICATION LIVRAISON
                If £Operation = LIVRAISON And OLD_KCOLIG.QuantiteLivree <> EcranLigneQuantiteLivree;
                    // --- MODIFICATION LIVRAISON - KCOCUM
                    p_EcritureKCOCUM.CodeClient = EcranCodeClient;
                    p_EcritureKCOCUM.CodeArticle = EcranLigneCodeArticle;
                    p_EcritureKCOCUM.QuantiteLivree = EcranLigneQuantiteLivree;
                    p_EcritureKCOCUM.QuantiteRetournee = 0;
                    p_EcritureKCOCUM.AncienneQuantiteLivree = OLD_KCOLIG.QuantiteLivree;
                    p_EcritureKCOCUM.AncienneQuantiteRetournee = 0;
                    EcritureKCOCUM(p_EcritureKCOCUM.CodeClient
                        :p_EcritureKCOCUM.CodeArticle
                        :p_EcritureKCOCUM.QuantiteLivree
                        :p_EcritureKCOCUM.QuantiteRetournee
                        :p_EcritureKCOCUM.AncienneQuantiteLivree
                        :p_EcritureKCOCUM.AncienneQuantiteRetournee);

                    // --- MODIFICATION LIVRAISON - KCOLIG
                    NEW_KCOLIG.NumeroBLConsignes = ECRANNUMEROBLCONSIGNES; 
                    NEW_KCOLIG.CodeArticle = EcranLigneCodeArticle;
                    NEW_KCOLIG.QuantiteLivree = EcranLigneQuantiteLivree;
                    NEW_KCOLIG.QuantiteRetournee = EcranLigneQuantiteRetournee;
                    EcritureKCOLIG(NEW_KCOLIG:KCOLIGExiste);
                
                    // --- MODIFICATION LIVRAISON - VRESTK
                    If (OLD_KCOLIG.QuantiteLivree <> EcranLigneQuantiteLivree);
                        If OLD_KCOLIG.QuantiteLivree > 0;
                            QuantiteVRESTK = OLD_KCOLIG.QuantiteLivree * -1;
                            EcritureVRESTK(EcranLigneCodeArticle 
                                        :QuantiteVRESTK  
                                        :SORTIE_STOCK);
                        EndIf;
                        If EcranLigneQuantiteLivree > 0;
                            EcritureVRESTK(EcranLigneCodeArticle 
                        : EcranLigneQuantiteLivree 
                        : SORTIE_STOCK);
                        EndIf;
                    EndIf;

                EndIf;

                // -- MODIFICATION RETOUR
                If £Operation = RETOUR And (OLD_KCOLIG.QuantiteLivree <> EcranLigneQuantiteLivree
                OR OLD_KCOLIG.QuantiteRetournee <> EcranLigneQuantiteRetournee);

                    // -- MODIFICATION RETOUR - KCOCUM
                    p_EcritureKCOCUM.CodeClient = EcranCodeClient;
                    p_EcritureKCOCUM.CodeArticle = EcranLigneCodeArticle;
                    p_EcritureKCOCUM.QuantiteLivree = EcranLigneQuantiteLivree;
                    p_EcritureKCOCUM.QuantiteRetournee = EcranLigneQuantiteRetournee;
                    p_EcritureKCOCUM.AncienneQuantiteLivree = OLD_KCOLIG.QuantiteLivree;
                    p_EcritureKCOCUM.AncienneQuantiteRetournee = OLD_KCOLIG.QuantiteRetournee; 
                    EcritureKCOCUM(p_EcritureKCOCUM.CodeClient
                        :p_EcritureKCOCUM.CodeArticle
                        :p_EcritureKCOCUM.QuantiteLivree
                        :p_EcritureKCOCUM.QuantiteRetournee
                        :p_EcritureKCOCUM.AncienneQuantiteLivree
                        :p_EcritureKCOCUM.AncienneQuantiteRetournee);

                    // --- MODIFICATION RETOUR - KCOLIG
                    NEW_KCOLIG.NumeroBLConsignes = ECRANNUMEROBLCONSIGNES; 
                    NEW_KCOLIG.CodeArticle = EcranLigneCodeArticle;
                    NEW_KCOLIG.QuantiteLivree = EcranLigneQuantiteLivree;
                    NEW_KCOLIG.QuantiteRetournee = EcranLigneQuantiteRetournee;
                    EcritureKCOLIG(NEW_KCOLIG:KCOLIGExiste);

                    // --- MODIFICATION RETOUR - VRESTK
                    // ---- Gestion des quantités livrées
                    If (OLD_KCOLIG.QuantiteLivree <> EcranLigneQuantiteLivree);
                        // On passe un mouvement négatif de l'ancienne valeur
                        If OLD_KCOLIG.QuantiteLivree >0;
                            QuantiteVRESTK = OLD_KCOLIG.QuantiteLivree * -1;
                            EcritureVRESTK(EcranLigneCodeArticle 
                                    : QuantiteVRESTK  
                                    : SORTIE_STOCK);
                        EndIf;
                        // On passe la nouvelle quantité
                        If EcranLigneQuantiteLivree > 0;
                            EcritureVRESTK(EcranLigneCodeArticle 
                        : EcranLigneQuantiteLivree 
                        : SORTIE_STOCK);
                        EndIf;
                    EndIf;
                    // ---- Gestion des quantités retournées
                    If (OLD_KCOLIG.QuantiteRetournee <> EcranLigneQuantiteRetournee);
                        // On passe un mouvement négatif de l'ancienne valeur
                        If OLD_KCOLIG.QuantiteRetournee > 0;
                            QuantiteVRESTK= OLD_KCOLIG.QuantiteRetournee * -1;
                            EcritureVRESTK(EcranLigneCodeArticle 
                            :QuantiteVRESTK  
                            :ENTREE_STOCK);
                        EndIf;
                        // On passe la nouvelle quantité
                        If EcranLigneQuantiteRetournee > 0 ;
                            EcritureVRESTK(EcranLigneCodeArticle 
                        : EcranLigneQuantiteRetournee 
                        : ENTREE_STOCK);
                        EndIf;
                    EndIf;
                    
                EndIf;
        

            
            
            OTHER;
        EndSl;
    EndFor;
    IntegrationVRESTK();
End-Proc;

/// ------------------------------------------------------------------------------------
// EditionPRTF
// Edite le PRTFKPBP11 et met à jour le nombre d éditions
/// ------------------------------------------------------------------------------------
Dcl-Proc EditionPRTF;

    Dcl-Pi EditionPRTF ;
    End-Pi;

    Dcl-S lignePagePRTF         Packed(3:0);
    Dcl-S NouveauNumeroEdition  Packed(2:0);    
    Dcl-S prtf_txt_entete char(30);
    Dcl-S i	Packed(4:0);
    Dcl-S ZDSCXX Char(6);

    K£PIMP.p_CodeEdition = PRTF_CODE_EDITION;
    K£PIMP.p_CodeModule = PRTF_CODE_MODULE;
    K£PIMP.p_User       = psds.User;

    // Appel K£PIMP pour récupérer les paramètres d impression (TABVV XIMPRE)
    KPIMP(
        K£PIMP.p_CodeEdition
        :K£PIMP.p_CodeModule 
        :K£PIMP.p_User       
        :K£PIMP.r_outq       
        :K£PIMP.r_nbexj      
        :K£PIMP.r_nbexs      
        :K£PIMP.r_nbexm      
        :K£PIMP.r_suspe      
        :K£PIMP.r_conserver);

    // Construction texte d en-tête
    prtf_txt_entete = 'BL consignes ' + %char(£NumeroBLConsignes);

    //Execution de l OVRPRTF
    CommandeCL = 'OVRPRTF FILE(' + %trimr(PRTF_CODE_EDITION) + 
                    ') OUTQ(' + %trimr(K£PIMP.r_outq) + 
                    ') PRTTXT(' + QUOTE + %trimr(prtf_txt_entete) + QUOTE +
                    ') COPIES(' + %trimr(ParametresConsigne.NombreExemplairesBL) + 
                    ') HOLD(' + %trimr(K£PIMP.r_suspe) + 
                    ') SAVE(' + %trimr(K£PIMP.r_conserver) + 
                    ') USRDTA(' + %trimr(psds.User) + ')';
    Monitor;
        ExecCL(CommandeCL);
    On-Error;
        dsply 'Erreur commande OVRPRTF';
    EndMon;

    //Récupération du numéro d édition
    Exec SQL
    select NombreEdition + 1
    Into :NouveauNumeroEdition
    From KCOENT
    Where NumeroBLConsignes = :£NumeroBLConsignes;
    GestionErreurSQL();

    //Gestion de l édition du document    
    Ind_FinDePagePRTF = *OFF;
    lignePagePRTF=20;

    //Ecriture de l entête
    PRTF_NumeroPage = 1;
    PRTF_ProfilUtilisateur = psds.user;
    PRTF_Programme = psds.Proc;
    PRTF_Date = %Date();
    PRTF_Heure = %Time();
    PRTF_NumeroEdition = NouveauNumeroEdition;
    PRTF_DateLivraison = ECRANDATELIVRAISON;

    Write ENTETE;


    Write Ligne;

    //Ecriture entête société
    ZDSCXX='ZDSC01';
    PRTF_ZDSC01 = GetEnteteSociete(ZDSCXX);
    ZDSCXX='ZDSC02';
    PRTF_ZDSC02 = GetEnteteSociete(ZDSCXX);
    ZDSCXX='ZDSC03';
    PRTF_ZDSC03 = GetEnteteSociete(ZDSCXX);
    ZDSCXX='ZDSC04';
    PRTF_ZDSC04 = GetEnteteSociete(ZDSCXX);
    ZDSCXX='ZDSC05';
    PRTF_ZDSC05 = GetEnteteSociete(ZDSCXX);
    ZDSCXX='ZDSC06';
    PRTF_ZDSC06 = GetEnteteSociete(ZDSCXX);
    ZDSCXX='ZDSC07';
    PRTF_ZDSC07 = GetEnteteSociete(ZDSCXX);
    ZDSCXX='ZDSC08';
    PRTF_ZDSC08 = GetEnteteSociete(ZDSCXX);
    ZDSCXX='ZDSC09';
    PRTF_ZDSC09 = GetEnteteSociete(ZDSCXX);
    ZDSCXX='ZDSC10';
    PRTF_ZDSC10 = GetEnteteSociete(ZDSCXX);

    Write ENTSOC;

    Write Ligne;

    //Ecriture entête client
    //Initialisation des zones de l entête du PRTF
    PRTF_ClientCode = ECRANCODECLIENT;
    PRTF_ClientCodeGroupe = ECRANCODECLIENT;
    
    PRTF_ClientLibelleSociete = VMRICL.ULISOC;
    PRTF_ClientDesignation = VMRICL.ULIDES;
    PRTF_ClientRue = VMRICL.ULIRUE;
    PRTF_ClientVille = VMRICL.ULIVIL;
    PRTF_ClientCodePostal = VMRICL.UCOPOS;
    PRTF_CLIENTBUREAUDISTRIB = VMRICL.ULIBDI;

    Write ENTECLI;


    Write Ligne;



    For i = 1 to NombreTotalLignesSF;
        Chain i GESTIONSFL;
        PRTF_ARTICLECODE = ECRANLIGNECODEARTICLE;
        PRTF_ARTICLELIBELLE = ECRANLIGNELIBELLE1ARTICLE;
        PRTF_ARTICLEQUANTITE = ECRANLIGNEQUANTITELIVREE;
        

        PRTF_PRIXUNITAIREARTICLE = GetPrixUnitaireArticle(
        Societe.Code
        :EcranCodeClient
        :ECRANDATELIVRAISON
        :ECRANLIGNECODEARTICLE
        :ECRANLIGNEQUANTITELIVREE
        );

        PRTF_PRIXTOTALLIGNE= PRTF_PRIXUNITAIREARTICLE * ECRANLIGNEQUANTITELIVREE;
        PRTF_PRIXTOTALCLIENT = PRTF_PRIXTOTALCLIENT + PRTF_PRIXTOTALLIGNE;
        If (lignePagePRTF > 60);
            Write ENTETE;

            Write Ligne;
            Write ENTSOC;

            Write Ligne;
            Write ENTECLI;

            Write Ligne;
            lignePagePRTF = 20;
        EndIf;
    
        Write LIGNEART;

        lignePagePRTF += 3;

    EndFor;
    Write Ligne;
    

    Write TOTAL;

    // Pour déclencher l impression physique :
    Close KCOP11PM;
    
    //Mise à jour du numéro d édition : 
    Exec SQL 
        UPDATE KCOENT
    SET 
        NombreEdition = :NouveauNumeroEdition
    WHERE 
        NumeroBLConsignes = :£NumeroBLConsignes;
    GestionErreurSQL();

    //Suppression des paramètres d impression
    CommandeCL = 'DLTOVR FILE(' + %trimr(PRTF_CODE_EDITION) + ')';
    Monitor;
        ExecCL(CommandeCL);
    On-Error;
        dsply 'Erreur commande DLTOVR FILE';
    EndMon;

End-Proc;

///
// EcritureKCOENT
// Ecriture dans le fichier des entêtes des livraisons de consignes
// - Si c est une création de livraison : Création d une nouvelle ligne
// - Si c est une modification de livraison : Mise à jour des logs de livraison
// - Si c est une création de retour : Mise à jour du top Retour
// - Si c est une modification d un retour : Mise à jour des logs du retour
///
Dcl-Proc EcritureKCOENT;

    Select;
        //Création de livraison : Ajout d une nouvelle ligne
        When  £Operation = LIVRAISON And £Mode = CREATION;
            Exec Sql
            INSERT INTO KCOENT (
                NumeroBLConsignes,
                NumeroLivraison,
                NumeroFacture,
                CodeTournee,
                CodeClient,
                DesignationClient,
                DateLivraison,     
                NombreEdition,       
                LIVRAISONTIMESTAMP,  
                LIVRAISONUTILISATEUR,
                TOPRETOUR
            ) VALUES (
                :£NumeroBLConsignes,
                :£NumeroLivraison,
                :ECRANNUMEROFACTURE,
                :EcranNumeroTournee,
                :EcranCodeClient,
                :EcranNomCommercialClient,
                :EcranDateLivraison,
                0,
                CURRENT TIMESTAMP,
                :psds.User,
                'N'
            );
            GestionErreurSQL();

        //Modification d une livraison : Mise à jour des logs de livraison
        When  £Operation = LIVRAISON And £Mode = MODIFICATION;
            Exec SQL
                UPDATE KCOENT
                SET 
                    LIVRAISONTIMESTAMP = CURRENT TIMESTAMP,
                    LIVRAISONUTILISATEUR = :psds.User
                WHERE 
                    NumeroBLConsignes = :£NumeroBLConsignes;
            GestionErreurSQL();


        When  £Operation = RETOUR And £Mode = CREATION And £NumeroLivraison = 0;

            Exec Sql
            INSERT INTO KCOENT (
                NumeroBLConsignes,
                NumeroLivraison,
                NumeroFacture,
                CodeTournee,
                CodeClient,
                DesignationClient,   
                DateLivraison,  
                NombreEdition,
                LivraisonTimeStamp,
                LivraisonUtilisateur,       
                TOPRETOUR,
                RETOURTIMESTAMP,  
                RETOURUTILISATEUR
            ) VALUES (
                :£NumeroBLConsignes,
                0,
                0,
                0,
                :EcranCodeClient,
                :EcranNomCommercialClient,
                CURRENT TIMESTAMP,
                :psds.User,
                CURRENT TIMESTAMP,
                :psds.User,
                'O',
                CURRENT TIMESTAMP,
                :psds.User
            );
            GestionErreurSQL();

        //Création d un retour : Mise à jour du Top Retour
        When  £Operation = RETOUR And £Mode = CREATION;
            Exec SQL
                UPDATE KCOENT
                SET 
                    TOPRETOUR = 'O',
                    RETOURTIMESTAMP = CURRENT TIMESTAMP,
                    RETOURUTILISATEUR = :psds.User
                WHERE 
                    NumeroBLConsignes = :£NumeroBLConsignes;
            GestionErreurSQL();

        //Modification d un retour : Mise à jour des logs de retour
        When  £Operation = RETOUR And £Mode = MODIFICATION;
            Exec SQL
                UPDATE KCOENT
                SET 
                    RETOURTIMESTAMP = CURRENT TIMESTAMP,
                    RETOURUTILISATEUR = :psds.User
                WHERE 
                    NumeroBLConsignes = :£NumeroBLConsignes;
            GestionErreurSQL();
        Other;
    EndSl;
End-Proc;

///
// EcritureKCOLIG
// Ecriture dans le fichier des lignes des livraisons de consignes
// 
// @param KCOLIG_New : Nouvelle valeur à écrire
// @param KCOLIGExiste : La ligne existe t-elle déjà ?
//
// Gère deux cas :
// - Si la ligne n existe pas : Insertion d une nouvelle ligne
// - Si la ligne existe : Mise à jour des quantités
///
Dcl-Proc EcritureKCOLIG;
    Dcl-Pi *n;
        KCOLIG_New LikeDS(KCOLIG_t);
        KCOLIGExiste Ind;
    End-Pi;

    If Not KCOLIGExiste;
        // Insertion d une nouvelle ligne
        Exec SQL
            INSERT INTO KCOLIG (
                NumeroBLConsignes,
                CodeArticle,
                QuantiteLivree,
                QuantiteRetournee
            ) VALUES (
                :KCOLIG_New.NumeroBLConsignes,
                :KCOLIG_New.CodeArticle,
                :KCOLIG_New.QuantiteLivree,
                :KCOLIG_New.QuantiteRetournee
            );
            
    Else;
        // Mise à jour des quantités pour une ligne existante
        Exec SQL
            UPDATE KCOLIG
            SET QuantiteLivree = :KCOLIG_New.QuantiteLivree,
                QuantiteRetournee = :KCOLIG_New.QuantiteRetournee
            WHERE NumeroBLConsignes = :KCOLIG_New.NumeroBLConsignes
            AND CodeArticle = :KCOLIG_New.CodeArticle;
    EndIf;

    GestionErreurSQL();

End-Proc;

///
//                                      Initialisation VRESTK
//
// - Initialisation des valeurs de la table VRESTK
///

Dcl-Proc InitialisationVRESTK;
     //Initialisation VRESTK
    VRESTKDS = '';

    //Récupération du compteur de mouvements :
    Exec SQL
        Select DEC(XLIPAR)
        Into :VRESTKDS.NumeroMouvement
        FROM VPARAM
        Where XCORAC = :TABLE_CHARTREUSE_MOUVEMENT_STOCK_NUM
        And XCOARG = CONCAT(:ParametresConsigne.CodeDepotConsignes, :Societe.Code);
    GestionErreurSQL();

    VRESTKDS.CodeSociete = Societe.Code;
    VRESTKDS.CodeDepot = ParametresConsigne.CodeDepotConsignes;
    VRESTKDS.MouvementJour = %Uns(%SUBST(%char(ECRANDATELIVRAISON):1:2));
    VRESTKDS.MouvementMois = %Uns(%SUBST(%char(ECRANDATELIVRAISON):4:2));
    VRESTKDS.MouvementSiecle = %Uns(%SUBST(%char(ECRANDATELIVRAISON):7:2));
    VRESTKDS.MouvementAnnee = %Uns(%SUBST(%char(ECRANDATELIVRAISON):9:2));
     //     VRESTKDS.CodeArticle = ;
     //     VRESTKDS.QuantiteMouvement = ;
     //     VRESTKDS.CodeSection = ;
     //     VRESTKDS.CodeProjet  = ;
     //     VRESTKDS.CodeUniteDeGestion  = ;
     //     VRESTKDS.PrixUnitaireMouvement = ;
     //     VRESTKDS.CodeEdition = ;
    VRESTKDS.PumpAnterieur = 0;
    VRESTKDS.QuantiteAcheteeDelaisAppro = 0;
    VRESTKDS.QuantiteModifiantEncours = 0;
    VRESTKDS.PrixAchat_Fabrication = 0;
     //     VRESTKDS.CodeGenerationCompta = ;
     //     VRESTKDS.LibelleMouvement = ;
    VRESTKDS.RefMouvementNumBLNumRecep =  %EDITC(ECRANNUMEROBLCONSIGNES : 'X');
    //     VRESTKDS.Emplacement = ;
    //     VRESTKDS.Lot = ;
    //     VRESTKDS.ElementDeLot  = ;
    VRESTKDS.CodeProfil = psds.User;
    VRESTKDS.CreationJour = %Uns(%SUBST(%Char(%DATE()):9:2));
    VRESTKDS.CreationMois = %Uns(%SUBST(%Char(%DATE()):6:2));
    VRESTKDS.CreationAnnee = %Uns(%SUBST(%Char(%DATE()):3:2));
    VRESTKDS.CreationSiecle = %Uns(%SUBST(%Char(%DATE()):1:2));
    VRESTKDS.NomProgramme = psds.Proc;
    VRESTKDS.ModifHeure = %Uns(%SUBST(%Char(%TIME()):1:2));
    VRESTKDS.ModifMinute = %Uns(%SUBST(%Char(%TIME()):4:2));
    VRESTKDS.ModifSeconde = %Uns(%SUBST(%Char(%TIME()):7:2));
    VRESTKDS.VALS = 'S';
    //     VRESTKDS.CodeEtablissement = ;
    VRESTKDS.NumeroDePoste = 0;
    //     VRESTKDS.TopReaj = ;
    VRESTKDS.ClientOuFournisseur = ECRANCODECLIENT;
    //     VRESTKDS.DesignationMouvement = ;
    //     VRESTKDS.DepotTransf  = ;
    VRESTKDS.QuantiteLogistique = 0;
    //     VRESTKDS.VariableLogistique  = ;
    //     VRESTKDS.VariablePromo = ;
    //     VRESTKDS.FlagTop1 = ;
    //     VRESTKDS.FlagTop2 = ;
    //     VRESTKDS.SpecifAlpha25 = ;
End-Proc;

///
// EcritureVRESTK
// Ecriture dans le fichier des lignes des livraisons de consignes
// et appel du programme VSLMVT2 pour acceptation des mouvements de stocks en attente
///
Dcl-Proc EcritureVRESTK;
    Dcl-Pi *n;
        p_CodeArticle Char(20);
        p_Quantite packed(4:0);
        p_TypeMouvement Char(1);  // E: Entrée, S: Sortie
    End-Pi;

     //Attribution des valeurs
    VRESTKDS.CodeArticle = p_CodeArticle;
    VRESTKDS.QuantiteMouvement = p_Quantite;
    If p_TypeMouvement = ENTREE_STOCK;
        VRESTKDS.CodeMouvement = ParametresConsigne.CodeMouvementEntree;
    elseIf p_TypeMouvement = SORTIE_STOCK;
        VRESTKDS.CodeMouvement = ParametresConsigne.CodeMouvementSortie;
    EndIf;


    //Récupération du code unité de gestion
    exec sql 
        select ACOUNG
        into :VRESTKDS.CODEUNITEDEGESTION
        FROM VARTIC
        Where ACOART = :ECRANLIGNECODEARTICLE;
    GestionErreurSQL();

    //Calcul du prix
    VRESTKDS.PrixUnitaireMouvement = GetPrixUnitaireArticle(
        Societe.Code
        :EcranCodeClient
        :ECRANDATELIVRAISON
        :p_CodeArticle
        :p_Quantite
    ) * p_Quantite;

     //Ecriture dans VRESTK
    Exec Sql
         Insert Into VRESTK
              Values (:VRESTKDS.CODESOCIETE,
                      :VRESTKDS.CODEDEPOT,
                      :VRESTKDS.NUMEROMOUVEMENT,
                      :VRESTKDS.MOUVEMENTJOUR,
                      :VRESTKDS.MOUVEMENTMOIS,
                      :VRESTKDS.MOUVEMENTSIECLE,
                      :VRESTKDS.MOUVEMENTANNEE,
                      :VRESTKDS.CODEMOUVEMENT,
                      :VRESTKDS.CODEARTICLE,
                      :VRESTKDS.QUANTITEMOUVEMENT,
                      :VRESTKDS.CODESECTION,
                      :VRESTKDS.CODEPROJET,
                      :VRESTKDS.CODEUNITEDEGESTION,
                      :VRESTKDS.PRIXUNITAIREMOUVEMENT,
                      :VRESTKDS.CODEEDITION,
                      :VRESTKDS.PUMPANTERIEUR,
                      :VRESTKDS.QUANTITEACHETEEDELAISAPPRO,
                      :VRESTKDS.QUANTITEMODIFIANTENCOURS,
                      :VRESTKDS.PRIXACHAT_FABRICATION,
                      :VRESTKDS.CODEGENERATIONCOMPTA,
                      :VRESTKDS.LIBELLEMOUVEMENT,
                      :VRESTKDS.REFMOUVEMENTNUMBLNUMRECEP,
                      :VRESTKDS.EMPLACEMENT,
                      :VRESTKDS.LOT,
                      :VRESTKDS.ELEMENTDELOT,
                      :VRESTKDS.CODEPROFIL,
                      :VRESTKDS.CREATIONJOUR,
                      :VRESTKDS.CREATIONMOIS,
                      :VRESTKDS.CREATIONANNEE,
                      :VRESTKDS.CREATIONSIECLE,
                      :VRESTKDS.NOMPROGRAMME,
                      :VRESTKDS.MODIFHEURE,
                      :VRESTKDS.MODIFMINUTE,
                      :VRESTKDS.MODIFSECONDE,
                      :VRESTKDS.VALS,
                      :VRESTKDS.CODEETABLISSEMENT,
                      :VRESTKDS.NUMERODEPOSTE,
                      :VRESTKDS.TOPREAJ,
                      :VRESTKDS.CLIENTOUFOURNISSEUR,
                      :VRESTKDS.DESIGNATIONMOUVEMENT,
                      :VRESTKDS.DEPOTTRANSF,
                      :VRESTKDS.QUANTITELOGISTIQUE,
                      :VRESTKDS.VARIABLELOGISTIQUE,
                      :VRESTKDS.VARIABLEPROMO,
                      :VRESTKDS.FLAGTOP1,
                      :VRESTKDS.FLAGTOP2,
                      :VRESTKDS.SPECIFALPHA25);
    GestionErreurSQL() ;

    VRESTKDS.NumeroMouvement = VRESTKDS.NumeroMouvement + 1;

End-Proc;

///
// EcritureKCOCUM
// Ecriture dans le fichier des cumuls de consignes par client
// Vérification si la ligne existe déjà (Code Client/Code article)
// Et écriture avec gestion des valeurs précédemment saisie en cas de modification de quantité
// par l'utilisateur
///
Dcl-Proc EcritureKCOCUM;
    Dcl-Pi *n ;
        p_CodeClient Char(9);
        p_CodeArticle Char(20);
        p_QuantiteLivree Packed(4:0);
        p_QuantiteRetournee Packed(4:0);
        p_AncienneQuantiteLivree Packed(4:0);
        p_AncienneQuantiteRetournee Packed(4:0);
    End-Pi;

    Dcl-Ds OLD_KCOCUM likeDs(KCOCUM_t);
    Dcl-Ds NEW_KCOCUM likeDs(KCOCUM_t);
    Dcl-S KCOCUMExiste Ind;

    //Init KCOCUM
    NEW_KCOCUM.HorodatageSaisie = %timestamp();
    NEW_KCOCUM.ProfilUser = psds.User;
    NEW_KCOCUM.CodeClient = p_CodeClient;
    NEW_KCOCUM.CodeArticle = p_CodeArticle;

    // Récupération des anciennes valeurs de KCOCUM
    // et vérification si le couple client/Code article existe déjà dans KCOCUM
    Exec SQL
        Select 
            QuantiteLivree, 
            QuantiteRetournee, 
            QuantiteCumulEcart, 
            QuantiteTheoriqueStock
        Into
            :OLD_KCOCUM.QuantiteLivree, 
            :OLD_KCOCUM.QuantiteRetournee, 
            :OLD_KCOCUM.QuantiteCumulEcart, 
            :OLD_KCOCUM.QuantiteTheoriqueStock
        From KCOCUM
        Where CodeClient = :p_CodeClient
        And CodeArticle = :p_CodeArticle;
    If SQLCode = 0;
        KCOCUMExiste = *On;
    ElseIf SQLCode = 100;
        KCOCUMExiste = *Off;
    Else;
        GestionErreurSQL();
    EndIf; 


    //La ligne n existe pas 
    If KCOCUMExiste = *Off;
        NEW_KCOCUM.QuantiteLivree = p_QuantiteLivree; 
        NEW_KCOCUM.QuantiteRetournee = p_QuantiteRetournee; 
        NEW_KCOCUM.QuantiteCumulEcart = 0;
        NEW_KCOCUM.QuantiteTheoriqueStock = 
                            NEW_KCOCUM.QuantiteLivree - NEW_KCOCUM.QuantiteRetournee;

    //Le couple existe 
    Else;

        NEW_KCOCUM.QuantiteLivree = 
                                OLD_KCOCUM.QuantiteLivree 
                                - p_AncienneQuantiteLivree 
                                + p_QuantiteLivree;
        NEW_KCOCUM.QuantiteRetournee = 
                                OLD_KCOCUM.QuantiteRetournee 
                                - p_AncienneQuantiteRetournee 
                                + p_QuantiteRetournee;
        NEW_KCOCUM.QuantiteCumulEcart = OLD_KCOCUM.QuantiteCumulEcart;
        NEW_KCOCUM.QuantiteTheoriqueStock = 
                                NEW_KCOCUM.QuantiteLivree 
                                - NEW_KCOCUM.QuantiteRetournee 
                                + NEW_KCOCUM.QuantiteCumulEcart;
    EndIf;

//INSERTION/MISE A JOUR DE LA TABLE
// Insertion d une nouvelle ligne        
    If Not KCOCUMExiste;
        Exec SQL
            INSERT INTO KCOCUM (
                CodeClient,
                CodeArticle,
                QuantiteLivree,
                QuantiteRetournee,
                QuantiteCumulEcart,
                QuantiteTheoriqueStock,
                HorodatageSaisie,
                ProfilUser
            ) VALUES (
                :NEW_KCOCUM.CodeClient,
                :NEW_KCOCUM.CodeArticle,
                :NEW_KCOCUM.QuantiteLivree,
                :NEW_KCOCUM.QuantiteRetournee,
                :NEW_KCOCUM.QuantiteCumulEcart,
                :NEW_KCOCUM.QuantiteTheoriqueStock,
                CURRENT TIMESTAMP,
                :NEW_KCOCUM.ProfilUser
            );
        GestionErreurSQL();
    // Mise à jour des quantités pour une ligne existante 
    Else;
        Exec SQL
            UPDATE KCOCUM
            SET QuantiteLivree = :NEW_KCOCUM.QuantiteLivree,
                QuantiteRetournee = :NEW_KCOCUM.QuantiteRetournee,
                QuantiteTheoriqueStock = :NEW_KCOCUM.QuantiteTheoriqueStock,
                HorodatageSaisie = CURRENT TIMESTAMP,
                ProfilUser = :NEW_KCOCUM.ProfilUser
            WHERE CodeClient = :NEW_KCOCUM.CodeClient
            AND CodeArticle = :NEW_KCOCUM.CodeArticle;
        GestionErreurSQL();
    EndIf;

End-Proc;


// ----------------------------------------------------------------------------
//
//                                 SERVICES
//                  Réutilisable dans d autres programmes
//
// -----------------------------------------------------------------------------

///
// GET libellé société
// La procédure renvoie le libellé de la société en fonction de son code
// TABVV : STE
//
// @return Libellé de la société si erreur renvoi *ALL ? 
///

Dcl-Proc GetLibelleSociete ;
    Dcl-Pi *n Char(20);

    End-Pi;

    Dcl-S LibelleSocieteReturn Char(20);
    Dcl-C TABLE_CHARTREUSE_SOCIETE 'STE';


    Exec SQL
            Select SUBSTR(XLIPAR, 1, 20)
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
// @return Code de la société si erreur renvoi *ALL ?
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
// @return Bilbiotheque de fichier de la société si erreur renvoi *ALL ?
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
// Affiche à l écran s il y a une erreur SQL
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
// - Appel de la fenêtre utilisateur (par  F2 )
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
// - Appel du menu de services (par F6 )
///

Dcl-Proc AffichageFenetreServices ;
    PR_GOASER();
End-Proc;


///
// GetEnteteSociete()

// Récupération des entêtes de sociétés
// TABVV ZDSXX
// pi : Code racine
// Return Char(45) Libellé entête société
///
Dcl-Proc GetEnteteSociete;

    Dcl-Pi GetEnteteSociete Char(45) ;
        p_Xcorac Char(6);
    End-Pi;

    Dcl-S LibelleEnteteReturn Char(45);

    Exec SQL
        SELECT SUBSTR(Xlipar, 1, 45)
        INTO :LibelleEnteteReturn
        FROM VPARAM
        WHERE Xcorac = :p_Xcorac ;
    If SQLCODE <> 0;
        GestionErreurSQL();
        LibelleEnteteReturn = *BLANKS;
    EndIf;

    Return LibelleEnteteReturn;
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


// ------------------------------------------------------------------------------------
// GetPrixUnitaireArticle
// Permet d effectuer une recherche du prix unitaire en appelant le programme VMRPUT
// ------------------------------------------------------------------------------------
Dcl-Proc GetPrixUnitaireArticle;
    Dcl-Pi GetPrixUnitaireArticle packed(13:4);  // Retourne le prix unitaire
        p_CodeSociete Char(2) const;
        p_CodeClient Char(9) const;
        p_DatePrix Date const;
        p_CodeArticle Char(20) const;
        p_Quantite Packed(11:3) const;
    End-Pi;

    // Initialisation de la data structure avec les valeurs par défaut
    VMRPUT = *ALLx'00';

    //Récupération des tarifs par défaut
    exec SQL
        select TCOTA1, TCOTA2
        Into :VMRPUT.UCOTA1, :VMRPUT.UCOTA2
        FROM VTARDF
        Where TCOSTE = :Societe.Code;
    GestionErreurSQL();

  // Récupération des informations client depuis VCLIEC
    Exec SQL
       SELECT CCOCTR,    -- Code centrale
              CCODEV,    -- Devise de commande
              CCOTAR,    -- Code tarif
              CNUCOL,    -- N° colonne tarif
              CTXREM    -- Taux de remise
       INTO :VMRPUT.UCOCTR,
            :VMRPUT.UCODEV,
            :VMRPUT.UCOTAR,
            :VMRPUT.UNUCOL,
            :VMRPUT.UTXREC
       FROM VCLIEC
       WHERE CCOSTE = :p_CodeSociete
       AND CCOCLI = :p_CodeClient;
    GestionErreurSQL();

    If VMRPUT.UCOTAR = *BLANKS;
        VMRPUT.UCOTAR=VMRPUT.UCOTA1;
    EndIf;

    // Conversion de la date au format JJMMAA
    VMRPUT.UDACDE =  %dec(p_DatePrix : *DMY);

   // Paramètres obligatoires
    VMRPUT.UCOSTE = p_CodeSociete;      // Code société
    VMRPUT.UCOCLI = p_CodeClient;       // Code client
    VMRPUT.UCOART = p_CodeArticle;      // Code article
    VMRPUT.UQTCDE = p_Quantite;         // Quantité 
    
    

    //Récupération du code regroupement de l article
    exec SQL
        select ACOREG
        Into :VMRPUT.UCOREG
        From VARTIC
        Where ACOART = :p_CodeArticle and ACOSTE = :Societe.Code;
    GestionErreurSQL(); 

    VMRPUT.UCOMON = VMRPUT.UCODEV;      // Devise société = devise commande
    VMRPUT.UFGGEN = '0';                // Top GENCOD

    Exec SQL
        select substr(XLIPAR, 2, 1)
        Into :VMRPUT.UFGREM
        FROM FIDVALSAM.VPARAM
        Where xcorac= :TABVV_FLAG_REMISE_CLIENT;
    If SQLCode = 100;
        VMRPUT.UFGREM = '0';
    ElseIf SQLCode <> 0;
        GestionErreurSQL();
    EndIf;

    // Paramètres complémentaires initialisés à vide
    VMRPUT.UCOVLO = *BLANKS;            // Variante logistique
    VMRPUT.UCOVPR = *BLANKS;            // Variante promo

    VMRPUT.UPUVEN = 0;                  // P.U. trouvé (sortie)
    VMRPUT.UPUVAR = 0;                  // P.U. article (sortie)
    VMRPUT.UTXREL = 0;                  // Remise trouvée (sortie)
    
    // Appel du programme de recherche de prix
    PR_VMRPUT(VMRPUT.UCOSTE
             :VMRPUT.UCOTAR
             :VMRPUT.UCOTA1
             :VMRPUT.UCOTA2
             :VMRPUT.UCOCLI
             :VMRPUT.UCOART
             :VMRPUT.UCOCTR
             :VMRPUT.UCOREG
             :VMRPUT.UCOVLO
             :VMRPUT.UCOVPR
             :VMRPUT.UDACDE
             :VMRPUT.UQTCDE
             :VMRPUT.UCODEV
             :VMRPUT.UCOMON
             :VMRPUT.UFGGEN
             :VMRPUT.UFGREM
             :VMRPUT.UTXREC
             :VMRPUT.UNUCOL
             :VMRPUT.UPUVEN
             :VMRPUT.UPUVAR
             :VMRPUT.UTXREL);

    Return VMRPUT.UPUVEN;
End-Proc;


///
// IntegrationVRESTK
// Integration des mouvements de stock en attente dans la table VRESTK
// - Gestion des paramètres d impression
// - Acceptation des mouvements de stock en attente présents dans VRESTK
// - Mise à jour du compteur de mouvements
///
Dcl-Proc IntegrationVRESTK;
    Dcl-Pi *n ;

    End-Pi;

    // Variables pour K£PIMP 
    K£PIMP.p_CodeEdition = 'VSLMVTP';
    K£PIMP.p_CodeModule = 'CO';
    K£PIMP.p_User = psds.User;

 // Appel de K£PIMP pour les paramètres d impression
    KPIMP(K£PIMP.p_CodeEdition 
          :K£PIMP.p_CodeModule
          :K£PIMP.p_User       
          :K£PIMP.r_outq       
          :K£PIMP.r_nbexj      
          :K£PIMP.r_nbexs      
          :K£PIMP.r_nbexm      
          :K£PIMP.r_suspe      
          :K£PIMP.r_conserver);

    // Paramétrage du PRTF
    monitor;
        CommandeCL = 'OVRPRTF FILE(VSLMVTP) ' +
               'OUTQ(' + %trim(K£PIMP.r_outq) + ') ' +
               'COPIES(' + %trim(K£PIMP.r_nbexj) + ') ' +
               'HOLD(' + %trim(K£PIMP.r_suspe) + ') ' + 
               'SAVE(' + %trim(K£PIMP.r_conserver) + ')';
        ExecCL(CommandeCL);
    on-error;
        dsply 'Erreur commande OVRPRTF';
    endmon;

 // Appel de VSLMVT2 pour l acceptation des mouvements
    VSLMVT2.CodeSociete = Societe.Code;
    VSLMVT2.Limit = ParametresConsigne.CodeDepotConsignes + EcranCodeClient;
    VSLMVT2.CodeEcran = psds.JobName;
    VSLMVT2.CodeProfil = '**********';
    
    PR_VSLMVT2(
        VSLMVT2.CodeSociete
        :VSLMVT2.Limit  
        :VSLMVT2.CodeEcran
        :VSLMVT2.CodeProfil
    );

    // Suppression des paramètres d impression
    monitor;
        CommandeCL = 'DLTOVR FILE(VSLMVTP)';
        ExecCL(CommandeCL);
    on-error;
        dsply 'Erreur commande DLTOVR';
    endmon;

    //Mise à jour du compteur de mouvements :
    Exec SQL
        Update VPARAM
        Set XLIPAR = :VRESTKDS.NumeroMouvement
        Where XCORAC = :TABLE_CHARTREUSE_MOUVEMENT_STOCK_NUM
        And XCOARG = CONCAT(:ParametresConsigne.CodeDepotConsignes, :Societe.Code);
    GestionErreurSQL();

End-Proc;


// Incrémentation du compteur BL consignes dans VPARAM
Dcl-Proc IncrementCompteurBL;
    Dcl-Pi *n End-Pi;
    
    Dcl-S NouveauCompteur Packed(8:0);
    Dcl-S CompteurFormate Char(8);
    
    // Récupérer la valeur complète de XLIPAR
    Exec SQL
        SELECT XLIPAR
        INTO :ParametresConsigne.XLIPAR
        FROM VPARAM
        WHERE XCORAC = :TABVV_PARAMETRESCONSIGNE
        AND XCOARG = :Societe.Code;
    GestionErreurSQL();

    // Lire le compteur actuel depuis la structure overlay
    // et l'incrémenter pour obtenir le prochain numéro
    NouveauCompteur = %Dec(ParametresConsigne.CompteurBLConsignes : 8 : 0) + 1;
    
    // Reformater le compteur avec des zéros de tête (8 positions)
    CompteurFormate = %EditC(NouveauCompteur : 'X');
    CompteurFormate = %SubSt('00000000' + %TrimL(CompteurFormate) : 
                             %Len('00000000' + %TrimL(CompteurFormate)) - 7 : 8);
    
    // Mettre à jour le compteur dans la structure
    ParametresConsigne.CompteurBLConsignes = CompteurFormate;
    
    // Mise à jour dans la base de données
    Exec SQL
        UPDATE VPARAM
        SET XLIPAR = :ParametresConsigne.XLIPAR
        WHERE XCORAC = :TABVV_PARAMETRESCONSIGNE
        AND XCOARG = :Societe.Code;
    GestionErreurSQL();

End-Proc;