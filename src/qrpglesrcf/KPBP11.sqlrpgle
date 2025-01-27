**free
Ctl-opt
     Option(*nodebugio:*SrcStmt:*NoUnRef)
     DftActGrp(*No)
     UsrPrf(*Owner);
///----------------------------------------------------------------------
//  NOM        : KPBP11               TYPE : Batch
//
//  TITRE      : Gestion pub.: liv. client  : saisie
//
//  FONCTIONS  : Ecriture des données dans les tables
//                - VRESTK (Insert mouvement de stocks)
//                - KPBFHT (Insert Fichier historique des mouvements pubs)
//                - VEMPQT (Update quantité Emplacement)
//                - VLOELT (Update quantité Lot/Element)
//                - VLOART (Update quantite Lot/Article)
//
//  APPELE PAR : - KPBP10CL
//
//  PARAMETRES :
//    - d'appel   :
//                  -£CodeDepot                    Char(3);
//                  -£DateLivraison                Char(10);
//                  -£CodeClient                   Char(9);
//                  -£LibelleClient                Char(30);
//                  -£CodeRepresentant             Char(3);
//                  -£LibelleRepresentant          Char(25);
//                  -£CodeSpecifique               Char(3);
//                  -£LibelleSpecifique            Char(25);
//                  -£NumeroEdition                Zoned(8:0);
//    - retournés : .
//
//
//  ECRIT DU   : 16/11/2022            PAR : ANg (Antilles Glaces)
//        AU   : 23/11/2022
// ----------------------------------------------------------------------
//
//  MODIFIE DU : 12/12/2022            PAR : Ang (Antilles Glaces)
//          AU : 15/02/2023
//
// . modifications :
//   - Remplacement de la table KPBFAT par la table KPBFHT
//     La table KPBFHT prend en compte l'emplacement, le lot et
//     L'élement de lot
//   - Ajout des Updates des tables VEMPQT, VLOELT, VLOART
///----------------------------------------------------------------------

//--- Fichiers ---------------------------------------------------------

//--- Tableaux ---------------------------------------------------------

//--- Variables --------------------------------------------------------
Dcl-S ReferenceMouvement           Char(8);
Dcl-S MessageErreurSQL             Char(52);

//--- Variables pour les programmes externes --------------------------//

//--- Procédures et programmes externes -------------------------------//

//--- Data-structures -------------------------------------------------//
Dcl-Ds KPBF01DS Qualified;
    Rang                            Zoned(3:0);
    CodeArticle                     Char(20);
    LibelleArticle                  Char(30);
    Quantite                        Zoned(6:0);
    CodeUnite                       Char(3);
    PrixUnitaire                    Zoned(9:4);
    CodeEmplacement                 Char(7);
    CodeLot                         Char(13);
    DesignationLot                  Char(30);
    CodeElementLot                  Zoned(8:0);
    PrixTotal                       Zoned(9:2);
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

Dcl-Ds KPBFHTDS Qualified;
    CodeSociete                   Char(2)      ;
    NumeroEdition                 Zoned(8:0)  ;
    CodeDepot                     Char(3)      ;
    DateDeLivraison               Date         ;
    CodeClient                    Char(9)      ;
    NomCommercial                 Char(30)     ;
    CodeRepresentant              Char(3)      ;
    LibelleRepresentant           Char(25)     ;
    CodeOperation                 Char(3)      ;
    LibelleOperation              Char(25)     ;
    ReferenceMouvement            Char(8)      ;
    CodeArticle                   Char(20)     ;
    LibelleArticle                Char(30)     ;
    Quantite                      Zoned(6:0)  ;
    CodeUnite                     Char(3)      ;
    PrixUnitaire                  Zoned(9:4)  ;
    CodeEmplacement               Char(7)      ;
    CodeLot                       Char(13)     ;
    DesignationLot                Char(30)     ;
    CodeElementLot                Zoned(8:0)  ;
    PrixTotal                     Zoned(9:2)  ;
    DateDeCreation                Date         ;
    HeuredeCreation               TIME         ;
    ProfilUtilisateur             Char(10)     ;
End-Ds;

Dcl-Ds VEMPQTDS Qualified;
    CodeSociete                     Char(2)    ;
    CodeDepot                       Char(3)    ;
    Emplacement                     Char(7)    ;
    CodeArticle                     Char(20)   ;
    CodeLot                         Char(13)   ;
    CodeElementDeLot                Char(8)    ;
    TypeEmplacement                 Char(3)    ;
    QuantiteEmplacement             Zoned(11:3);
    QuantiteBloquee                 Zoned(11:3);
    JourPremiereEntree              Zoned(2:0);
    MoisPremiereEntree              Zoned(2:0);
    AnneePremiereEntree             Zoned(2:0);
    SieclePremiereEntree            Zoned(2:0);
    JourDerniereEntre               Zoned(2:0);
    MoisDerniereEntre               Zoned(2:0);
    AnneeDerniereEntre              Zoned(2:0);
    SiecleDerniereEntre             Zoned(2:0);
    JourDerniereSortie              Zoned(2:0);
    MoisDerniereSortie              Zoned(2:0);
    AnneeDerniereSortie             Zoned(2:0);
    SiecleDerniereSortie            Zoned(2:0);
    JourCreation                    Zoned(2:0);
    MoisCreation                    Zoned(2:0);
    SiecleCreation                  Zoned(2:0);
    AnneeCreation                   Zoned(2:0);
    Profil                          Char(10)  ;
    Programme                       Char(10)  ;
    JourModif                       Zoned(2:0);
    MoisModif                       Zoned(2:0);
    SiecleModif                     Zoned(2:0);
    AnneeModif                      Zoned(2:0);
    HeureModif                      Zoned(2:0);
    MinuteModif                     Zoned(2:0);
    SecondeModif                    Zoned(2:0);
    QuantiteLibre                   Zoned(11:3);
    Poids                           Zoned(7:3);
    MontantLibre1                   Zoned(15:4);
    MontantLibre2                   Zoned(15:4);
    CritereRecherche1               Char(3) ;
    CritereRecherche2               Char(3) ;
    LibelleDe25                     Char(25);
End-Ds;

Dcl-Ds VLOELTDS Qualified;
    CodeSociete             Char(2)    ;
    CodeArticle             Char(20)   ;
    CodeLot                 Char(13)   ;
    CodeElementDeLot        Char(8)    ;
    CodeDepot               Char(3)    ;
    CodeEtablissement       Char(3)    ;
    Quantite                Zoned(11:3);
    CodeUniteDeGestion      Char(3)    ;
    PrixStandard            Zoned(13:4);
    PoidsBrut               Zoned(11:3);
    NumDeLivraison          Zoned(8:0) ;
    NumPoste                Zoned(3:0) ;
    CodeDevise              Char(3)    ;
    TauxDeVente             Zoned(9:6) ;
    Emplacement             Char(7)    ;
    BlocageLotSortie        Char(1)    ;
    JourDispo               Zoned(2:0) ;
    MoisDispo               Zoned(2:0) ;
    AnneeDispo              Zoned(2:0) ;
    SiecleDispo             Zoned(2:0) ;
    JourExpiration          Zoned(2:0) ;
    MoisExpiration          Zoned(2:0) ;
    AnneeExpiration         Zoned(2:0) ;
    SiecleExpiration        Zoned(2:0) ;
    JourFIFO                Zoned(2:0) ;
    MoisFIFO                Zoned(2:0) ;
    AnneeFIFO               Zoned(2:0) ;
    SiecleFIFO              Zoned(2:0) ;
End-Ds;

Dcl-Ds VLOARTDS Qualified;
    CodeEnregistrement  Char(1) ;
    CodeSociete         Char(2) ;
    CodeArticle         Char(20) ;
    CodeLot             Char(13) ;
    DepotOrigine        Char(3) ;
    CodeTransporteur    Char(3) ;
    Jour                Zoned(2:0);
    Mois                Zoned(2:0);
    Annee               Zoned(2:0);
    DesignationLot      Char(30);
    CodeUniteDeGestion  Char(3) ;
    Quantite            Zoned(11:3);
    NumCommande         Char(8) ;
    CodeElementDeLot    Char(8) ;
    Fournisseur         Char(9) ;
    Emplacement         Char(7) ;
End-Ds;

//--- Data-structures externes ----------------------------------------//
/INCLUDE qincsrc,rpg_PSDS

//--- Prototypes          --------------------------------------------//

//--- Constantes ------------------------------------------------------//
Dcl-C TABLE_CHARTREUSE_MOUVEMENT_STOCK_NUM 'NUMT';
Dcl-C TABLE_CHARTREUSE_MOUVEMENT_STOCK_CODE 'XPBPAR';
Dcl-C TABLE_CHARTREUSE_REPRENSENTANT 'REP';

//--- Paramètres ------------------------------------------------------/
Dcl-Pi *N ;
    £CodeSociete                  Char(2);
    £CodeDepot                    Char(3);
    £DateLivraison                Char(10);
    £CodeClient                   Char(9);
    £LibelleClient                Char(30);
    £CodeRepresentant             Char(3);
    £LibelleRepresentant          Char(25);
    £CodeSpecifique               Char(3);
    £LibelleSpecifique            Char(25);
    £NumeroEdition                Zoned(8:0);
End-Pi ;

//-----------------------------------------------------------------------------
//                               P R O G R A M M E    P R I N C I P A L
//-----------------------------------------------------------------------------
//Initialisation:
Exec Sql
      Set Option Commit = *None ;

//Attribution référence mouvement
Select;
    When £CodeClient <> *BLANKS;
        ReferenceMouvement = 'C-'+ £CodeClient;
    When £CodeRepresentant <> *BLANKS;
        ReferenceMouvement = 'R-'+ £CodeRepresentant;
    When £CodeSpecifique <> *BLANKS;
        ReferenceMouvement = 'S-'+ £CodeSpecifique;
    Other;
EndSl;


RecuperationNumeroEdition();
InitialisationKPBFHT();
InitialisationVRESTK();

//Préparation CURSOR_KPBF01
Exec Sql
     Declare CURSOR_KPBF01 Cursor For
          Select NUMRAN,
                 CDEART,
                 LIBART,
                 QTEART,
                 CDEUNI,
                 PRXUNI,
                 CDEEMP,
                 CDELOT,
                 DESLOT,
                 CDEELT,
                 PRXTOT
               From KPBF01;
MessageErreurSQL = 'Err : Declare CURSOR_KPBF01' ;
GestionErreurSQL() ;

//Open CURSOR_KPBF01
Exec Sql
     Open CURSOR_KPBF01 ;
MessageErreurSQL = 'Err : OPEN CURSOR_KPBF01' ;
GestionErreurSQL() ;

//Fetch CURSOR_KPBF01
Exec Sql
     Fetch CURSOR_KPBF01
          Into
               :KPBF01DS.Rang,
               :KPBF01DS.CodeArticle,
               :KPBF01DS.LibelleArticle,
               :KPBF01DS.Quantite,
               :KPBF01DS.CodeUnite,
               :KPBF01DS.PrixUnitaire,
               :KPBF01DS.CodeEmplacement,
               :KPBF01DS.CodeLot,
               :KPBF01DS.DesignationLot,
               :KPBF01DS.CodeElementLot,
               :KPBF01DS.PrixTotal;
MessageErreurSQL = 'Err : Fetch CURSOR_KPBF01' ;
GestionErreurSQL() ;

//Boucle traitement
DoW SQLCode = 0 ;
    EcritureKPBFHT();
    EcritureVRESTK();
    UpdateVEMPQT();

    //Si l'article est géré par lot => mise à jour de VLOART et VLOELT
    If (KPBF01DS.CodeLot <> *BLANKS);
        UpdateVLOART();
        UpdateVLOELT();
    EndIf;

     //Fetch ligne suivante
    Exec Sql
          Fetch CURSOR_KPBF01
               Into
               :KPBF01DS.Rang,
               :KPBF01DS.CodeArticle,
               :KPBF01DS.LibelleArticle,
               :KPBF01DS.Quantite,
               :KPBF01DS.CodeUnite,
               :KPBF01DS.PrixUnitaire,
               :KPBF01DS.CodeEmplacement,
               :KPBF01DS.CodeLot,
               :KPBF01DS.DesignationLot,
               :KPBF01DS.CodeElementLot,
               :KPBF01DS.PrixTotal;
    MessageErreurSQL = 'Err : Fetch CURSOR_KPBF01' ;
    GestionErreurSQL() ;
EndDo ;

//Close CURSOR_KPBF01
Exec Sql
     Close CURSOR_KPBF01 ;
MessageErreurSQL = 'Err : Close CURSOR_KPBF01' ;
GestionErreurSQL() ;

//Mise à jour de la table NUMT
UpdateNUMT();

//Fin programme
*InLr = *On;

//-----------------------------------------------------------------------------
//                                       P R O C E D U R E S
//-----------------------------------------------------------------------------

///
//                                      Initialisation KPBFHT
//
// - Initialisation des valeurs de la table KPBFHT
///

Dcl-Proc InitialisationKPBFHT;
    //Initialisation KPBFHT
    KPBFHTDS = *BLANKS;

    // Si le code représentant n'est pas renseigné
    // et que le code client est renseigné,
    // on récupère le représentant affecté au client
    If (£CodeRepresentant = *BLANKS And £CodeClient <> *BLANKS );
        //Récupération du code via le code client
        Exec SQL
            Select CCORE1
            Into :KPBFHTDS.CodeRepresentant
            FROM VCLIEC
            Where CCOCLI = :£CodeClient;

        //Récupération du libellé via le code représentant
        Exec SQL
            Select SUBSTR(XLIPAR, 1, 25)
            Into :KPBFHTDS.LibelleRepresentant
            From VPARAM
            Where XCORAC = :TABLE_CHARTREUSE_REPRENSENTANT
                and xcoarg = :KPBFHTDS.CodeRepresentant;

    Else;//Sinon on récupère les informations saisies par l'utilisateur
        KPBFHTDS.CodeRepresentant = £CodeRepresentant;
        KPBFHTDS.LibelleRepresentant = £LibelleRepresentant;
    EndIf;


    KPBFHTDS.CodeSociete = £CodeSociete;
    KPBFHTDS.NumeroEdition = £NumeroEdition;
    KPBFHTDS.CodeDepot = £CodeDepot;
    KPBFHTDS.DateDeLivraison = %Date(£DateLivraison:*EUR);
    KPBFHTDS.CodeClient = £CodeClient;
    KPBFHTDS.NomCommercial = £LibelleClient;
    KPBFHTDS.CodeOperation = £CodeSpecifique;
    KPBFHTDS.LibelleOperation = £LibelleSpecifique;
    KPBFHTDS.ReferenceMouvement = ReferenceMouvement;
     //KPBFHTDS.CodeArticle     = ;
     //KPBFHTDS.LibelleArticle  = ;
     //KPBFHTDS.Quantite        = ;
     //KPBFHTDS.CodeUnite       = ;
     //KPBFHTDS.PrixUnitaire    = ;
     //KPBFHTDS.CodeEmplacement = ;
     //KPBFHTDS.CodeLot         = ;
     //KPBFHTDS.DesignationLot  = ;
     //KPBFHTDS.CodeElementLot  = ;
     //KPBFHTDS.PrixTotal       = ;
    KPBFHTDS.DateDeCreation  = %Date();
    KPBFHTDS.HeuredeCreation = %Time();
    KPBFHTDS.ProfilUtilisateur = psds.User;

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
        And XCOARG = CONCAT(:£CodeDepot, :£CodeSociete);

    // VMRNMV.UCOSTE = £CodeSociete;
    // VMRNMV.UCODEP = £CodeDepot;
    // VMRNMV.UNBMVT = '00000001';
    // PR_VMRNMV(VMRNMV.UCOSTE
    //            :VMRNMV.UCODEP
    //            :VMRNMV.UNBMVT);


    //Récupération code mouvement de stock
    Exec SQL
        Select SUBSTR(XLIPAR, 4, 2)
        Into :VRESTKDS.CodeMouvement
        From VPARAM
        Where XCORAC = :TABLE_CHARTREUSE_MOUVEMENT_STOCK_CODE;

    VRESTKDS.CodeSociete = £CodeSociete;
    VRESTKDS.CodeDepot = £CodeDepot;
    VRESTKDS.MouvementJour = %Uns(%SUBST(£DateLivraison:1:2));
    VRESTKDS.MouvementMois = %Uns(%SUBST(£DateLivraison:4:2));
    VRESTKDS.MouvementSiecle = %Uns(%SUBST(£DateLivraison:7:2));
    VRESTKDS.MouvementAnnee = %Uns(%SUBST(£DateLivraison:9:2));
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
    VRESTKDS.RefMouvementNumBLNumRecep = ReferenceMouvement;
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
    VRESTKDS.ClientOuFournisseur = *BLANKS;
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
//                                          Update VLOART
// - Update dans la table VLOART
///

Dcl-Proc UpdateVLOART;
    Dcl-S QuantiteDisponible Zoned(11:3);

    VLOARTDS.CodeArticle = KPBF01DS.CodeArticle;
    VLOARTDS.CodeLot = KPBF01DS.CodeLot;

    Exec SQL
        Select
            TQTSTK
        Into
            :QuantiteDisponible
        From
            VLOART
        Where
            TCOART = :VLOARTDS.CodeArticle
            And TCOLOT = :VLOARTDS.CodeLot;
    MessageErreurSQL = 'Err : Select VLOART';
    GestionErreurSQL(MessageErreurSQL);

    VLOARTDS.Quantite = QuantiteDisponible - KPBF01DS.Quantite;

    Exec SQL
            Update VLOART
                Set
                    TQTSTK = :VLOARTDS.Quantite
                Where
                    TCOART = :VLOARTDS.CodeArticle
                    And TCOLOT = :VLOARTDS.CodeLot;
    MessageErreurSQL = 'Err : Update VLOART';
    GestionErreurSQL(MessageErreurSQL);
End-Proc;

///
//                                          Update VLOELT
// - Update dans la table VLOELT
///

Dcl-Proc UpdateVLOELT;
    Dcl-S QuantiteDisponible Zoned(11:3);

    VLOELTDS.CodeArticle = KPBF01DS.CodeArticle;
    VLOELTDS.CodeLot = KPBF01DS.CodeLot;
    VLOELTDS.CodeElementDeLot = %EDITC(KPBF01DS.CodeElementLot:'X');

    Exec SQL
        Select
            EQTSTK
        Into
            :QuantiteDisponible
        From
            VLOELT
        Where
            ECOART = :VLOELTDS.CodeArticle
            And ECOLOT = :VLOELTDS.CodeLot
            And ENULOT = :VLOELTDS.CodeElementDeLot;
    MessageErreurSQL = 'Err : Select VLOELT';
    GestionErreurSQL(MessageErreurSQL);

    VLOELTDS.Quantite = QuantiteDisponible - KPBF01DS.Quantite;

    Exec SQL
            Update VLOELT
                Set
                    EQTSTK = :VLOELTDS.Quantite
                Where
                    ECOART = :VLOELTDS.CodeArticle
                    And ECOLOT = :VLOELTDS.CodeLot
                    And ENULOT = :VLOELTDS.CodeElementDeLot;
    MessageErreurSQL = 'Err : Update VLOELT';
    GestionErreurSQL(MessageErreurSQL);
End-Proc;

///
//                                          Update VEMPQT
// - Update dans la table VEMPQT Si la ligne est à 0, on la supprime
///

Dcl-Proc UpdateVEMPQT;
    Dcl-S QuantiteDisponible Zoned(11:3);

    VEMPQTDS.CodeArticle = KPBF01DS.CodeArticle;
    VEMPQTDS.Emplacement = KPBF01DS.CodeEmplacement;
    VEMPQTDS.CodeLot = KPBF01DS.CodeLot;
    If (KPBF01DS.CodeElementLot <> 0);
        VEMPQTDS.CodeElementDeLot = %EDITC(KPBF01DS.CodeElementLot:'X');
    Else;
        VEMPQTDS.CodeElementDeLot = *BLANKS;
    EndIf;


    Exec SQL
        Select
            QTEEMP
        Into
            :QuantiteDisponible
        From
            VEMPQT
        Where
            QCOART = :VEMPQTDS.CodeArticle
            And QCOLOT = :VEMPQTDS.CodeLot
            And QCOELT = :VEMPQTDS.CodeElementDeLot
            And QCOEMP = :VEMPQTDS.Emplacement;
    MessageErreurSQL = 'Err : Select VEMPQT';
    GestionErreurSQL(MessageErreurSQL);

    VEMPQTDS.QuantiteEmplacement = QuantiteDisponible - KPBF01DS.Quantite;

    If VEMPQTDS.QuantiteEmplacement = 0;
        Exec SQL
            Delete VEMPQT
                Where
                    QCOART = :VEMPQTDS.CodeArticle
                    And QCOLOT = :VEMPQTDS.CodeLot
                    And QCOELT = :VEMPQTDS.CodeElementDeLot
                    And QCOEMP = :VEMPQTDS.Emplacement;
        MessageErreurSQL = 'Err : Delete VEMPQT';
        GestionErreurSQL(MessageErreurSQL);
    Else;
        Exec SQL
            Update VEMPQT
                Set
                    QTEEMP = :VEMPQTDS.QuantiteEmplacement
                Where
                    QCOART = :VEMPQTDS.CodeArticle
                    And QCOLOT = :VEMPQTDS.CodeLot
                    And QCOELT = :VEMPQTDS.CodeElementDeLot
                    And QCOEMP = :VEMPQTDS.Emplacement;
        MessageErreurSQL = 'Err : Update VEMPQT';
        GestionErreurSQL(MessageErreurSQL);
    EndIf;

End-Proc;

///
//                                          EcritureKPBFHT
// - Ecriture dans la table KPBFHT
///

Dcl-Proc EcritureKPBFHT;
    KPBFHTDS.CodeArticle      = KPBF01DS.CodeArticle;
    KPBFHTDS.LibelleArticle   = KPBF01DS.LibelleArticle;
    KPBFHTDS.Quantite         = KPBF01DS.Quantite;
    KPBFHTDS.CodeUnite        = KPBF01DS.CodeUnite;
    KPBFHTDS.PrixUnitaire     = KPBF01DS.PrixUnitaire;
    KPBFHTDS.CodeEmplacement  = KPBF01DS.CodeEmplacement;
    KPBFHTDS.CodeLot          = KPBF01DS.CodeLot;
    KPBFHTDS.DesignationLot   = KPBF01DS.DesignationLot;
    KPBFHTDS.CodeElementLot   = KPBF01DS.CodeElementLot;
    KPBFHTDS.PrixTotal        = KPBF01DS.PrixTotal;

     //Ecriture dans KPBFHT
    Exec Sql
         Insert Into KPBFHT
              Values (:KPBFHTDS.CODESOCIETE,
                      :KPBFHTDS.NUMEROEDITION,
                      :KPBFHTDS.CODEDEPOT,
                      :KPBFHTDS.DATEDELIVRAISON,
                      :KPBFHTDS.CODECLIENT,
                      :KPBFHTDS.NOMCOMMERCIAL,
                      :KPBFHTDS.CODEREPRESENTANT,
                      :KPBFHTDS.LIBELLEREPRESENTANT,
                      :KPBFHTDS.CODEOPERATION,
                      :KPBFHTDS.LIBELLEOPERATION,
                      :KPBFHTDS.REFERENCEMOUVEMENT,
                      :KPBFHTDS.CODEARTICLE,
                      :KPBFHTDS.LIBELLEARTICLE,
                      :KPBFHTDS.QUANTITE,
                      :KPBFHTDS.CODEUNITE,
                      :KPBFHTDS.PRIXUNITAIRE,
                      :KPBFHTDS.CODEEMPLACEMENT,
                      :KPBFHTDS.CODELOT,
                      :KPBFHTDS.DESIGNATIONLOT,
                      :KPBFHTDS.CODEELEMENTLOT,
                      :KPBFHTDS.PRIXTOTAL,
                      :KPBFHTDS.DATEDECREATION,
                      :KPBFHTDS.HEUREDECREATION,
                      :KPBFHTDS.PROFILUTILISATEUR);
    MessageErreurSQL = 'Err : Insert KPBFHT' ;
    GestionErreurSQL(MessageErreurSQL) ;
End-Proc;

///
//                                          EcritureVRESTK
//
// - Ecriture dans la table VRESTK
///

Dcl-Proc EcritureVRESTK;
     //Attribution des valeurs
    VRESTKDS.CodeArticle = KPBF01DS.CodeArticle;
    VRESTKDS.QuantiteMouvement = KPBF01DS.Quantite;
    VRESTKDS.CodeUniteDeGestion  = KPBF01DS.CodeUnite;
    VRESTKDS.PrixUnitaireMouvement = KPBF01DS.PrixUnitaire;
    VRESTKDS.Emplacement = KPBF01DS.CodeEmplacement;
    VRESTKDS.Lot = KPBF01DS.CodeLot;
    VRESTKDS.ElementDeLot = %Char(KPBF01DS.CodeElementLot);


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
    MessageErreurSQL = 'Err : INSERT VRESTK' ;
    GestionErreurSQL(MessageErreurSQL) ;

    VRESTKDS.NumeroMouvement = VRESTKDS.NumeroMouvement + 1;
End-Proc;

///
//                                      RecuperationNumeroEdition
//
// - Récupère le dernier numéro d'édition dans la table VPARAM ayant pour
// racine XPBChar
///

Dcl-Proc RecuperationNumeroEdition;
    Dcl-S NumeroEdition               Zoned(8:0);
    Dcl-S NewXLIPAR                      Char(8);

     //Récupération du dernier numéro de l'édition et incrémentation
    Exec Sql
         Select Cast(XLIPAR As Integer)
              Into :NumeroEdition
              From VPARAM
              Where XCORAC Like 'XPBCHR';

    If (NumeroEdition = 0);
        NumeroEdition = 1;
    else;
        NumeroEdition += 1;
    EndIf;

    NewXLIPAR = %EDITC(NumeroEdition:'X');

    Exec Sql
         Update VPARAM Set XLIPAR = :NewXLIPAR Where XCORAC Like 'XPBCHR';

    £NumeroEdition = NumeroEdition;
End-Proc;


///
//                                          UpdateNUMT
//
// - Update de la table de numéro du mouvement de stock
///

Dcl-Proc UpdateNUMT;
    Dcl-S NumeroMouvementStock Char(8);

    NumeroMouvementStock = %EDITC(VRESTKDS.NumeroMouvement :'X');

    Exec SQL
    Update VPARAM
        Set
            XLIPAR = :NumeroMouvementStock
        Where XCORAC = :TABLE_CHARTREUSE_MOUVEMENT_STOCK_NUM
        And XCOARG = CONCAT(:£CodeDepot, :£CodeSociete);

End-Proc;

///
//                                          GestionErreurSQL
//
// - Fait un DSPLY s'il y a une erreur SQL
//
// @param Message d'erreur
///

Dcl-Proc GestionErreurSQL ;
    Dcl-Pi *N;
        MessageErreurSQL     Char(52);
    End-Pi;

    If (SQLCode <> 0 And SQLCode <> 100) ;
        DSPLY MessageErreurSQL;
        DSPLY ('SQLCode : ' + %Char(SQLCode));
        DSPLY ('SQLState : ' + %Char(SQLState));
    EndIf ;
End-Proc;
 