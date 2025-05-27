**free
Ctl-opt Option(*srcstmt:*nodebugio) AlwNull(*usrctl) UsrPrf(*owner)
        DatFmt(*iso) TimFmt(*hms) dftactgrp(*no);

// Appel ligne de commande :
// CALL PGM(KCOP20) PARM((GER  (*CHAR 4)) (INVENT (*CHAR 6))
//  ('Inventaire des consignes' (*CHAR 30)))
// C010088
///
// --------------------------------------------------------------
//       NOM        : KCOP20              TYPE : Interactif
//
//  TITRE      : Suivi des articles consignés.: Inventaire des consignes
//
//  FONCTIONS  :
//              Inventaire des articles consignés chez les clients.
//              Le programme permet de :
//              - Sélectionner une société et un client
//              - Afficher les quantités théoriques actuelles (KCOCUM)
//              - Saisir les quantités réellement présentes chez le client
//              - Calculer les écarts d'inventaire
//              - Mettre à jour les écarts dans KCOCUM
//              - Génère les mouvements de stocks
//
//              Écrans :
//                      Écran 1 : Sélection société/client et date d'inventaire
//                      Écran 2 : Sous-fichier de saisie des quantités d'inventaire
//
//              Touches de fonction :
//                      F2 : Utilisateur
//                      F3 : Fin
//                      F4 : Recherche (société/client selon curseur)
//                      F6 : Services
//                      F12 : Abandon
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
//  ECRIT DU   : 26/05/2025            PAR : ANg (Antilles Glaces)
//        AU   : 26/05/2025
//
/// ---------------------------------------------------------------------

// Déclaration fichier
Dcl-F KCOP20E  WorkStn
               SFile(GESTIONSFL:fichierDS.rang_sfl)
               InfDS(fichierDS)
               IndDs(Indicateur)
               Alias;

// --- Tables -------------------------------------------------------
// Cumuls consignes par client
Dcl-Ds KCOCUM_t extname('KCOCUM') qualified template alias;
End-Ds;

// Mouvements de stock 
Dcl-Ds VRESTK_t extname('VRESTK') qualified template;
End-Ds;

// Structure pour VRESTK
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

Dcl-Ds DSPFSauve Qualified;
    Totalite                                Char(4000);
    Element                                 Char(80) Dim(50) Overlay(Totalite);
    Clef                                    Char(30) Overlay(Element);
    Valeur                                  Char(50) Overlay(Element:*Next);
End-Ds;

// TABVV XCOPAR - Paramètres consignes
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

// --- Appels de prototypes et de leurs DS-------------------------------
// Fenêtre utilisateur
/DEFINE PR_GOAFENCL
// Fenêtre service
/DEFINE PR_GOASER
// Recherche société
/DEFINE PR_VORPAR
// Recherche client
/DEFINE PR_VMRCLM
// Récupération données client
/DEFINE PR_VMRICL
// Acceptation mouvements de stock VRESTK  
/DEFINE PR_VSLMVT2
// Récupération prix unitaire pour valorisation stock
/DEFINE PR_VMRPUT

/INCLUDE qincsrc,prototypes

/UNDEFINE PR_GOAFENCL
/UNDEFINE PR_GOASER
/UNDEFINE PR_VORPAR
/UNDEFINE PR_VMRCLM
/UNDEFINE PR_VMRICL
/UNDEFINE PR_VSLMVT2
/UNDEFINE PR_VMRPUT

// Prototype pour K£PIMP (gestion impression)
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
// Variables pour K£PIMP
Dcl-Ds K£PIMP qualified;
    p_CodeEdition char(10);
    p_CodeModule Char(2);
    p_User Char(10);
    r_outq char(20);
    r_nbexj char(2);    
    r_nbexs char(2);
    r_nbexm char(2);
    r_suspe char(4);
    r_conserver char(4);
End-Ds;

// Prototype pour exécution commandes CL
Dcl-Pr QCMDEXC ExtPgm('QCMDEXC');
    cde Char(200) const;
    cdl Packed(15:5) const;
End-Pr;



// --- Variables -------------------------------------------------------
Dcl-S NombreTotalLignesSF Packed(4:0);
Dcl-S Fin ind;
Dcl-S FinFenetre ind;
Dcl-S Refresh ind;
Dcl-S EcranActuel char(10);
Dcl-S NumeroInventaire Packed(10:0);
Dcl-S CommandeCL varChar(200);
Dcl-S BibliothequeFichier Char(9);

// --- Constantes -------------------------------------------------------
Dcl-C ECRAN_SELECTION 'SELECT';
Dcl-C ECRAN_INVENTAIRE 'INVENTAIRE';
Dcl-C TABVV_PARAMETRESCONSIGNE 'XCOPAR';
Dcl-C TABVV_FLAG_REMISE_CLIENT 'AFFREM';
Dcl-C TABLE_CHARTREUSE_MOUVEMENT_STOCK_NUM 'NUMT';
Dcl-C ENTREE_STOCK 'E';
Dcl-C SORTIE_STOCK 'S';
Dcl-C PRTF_CODE_MODULE 'CO';
Dcl-C QUOTE '''';

// --- Data-structures Indicateurs--------------------------------------
Dcl-Ds Indicateur qualified;
    // Écran sélection
    MasquerEcranSelection                   Ind Pos(90);
    
    // Sous-fichier
    SousFichierDisplay                      Ind Pos(51);
    SousFichierDisplayControl               Ind Pos(52);
    SousFichierClear                        Ind Pos(53);
    SousFichierEnd                          Ind Pos(54);
    SousFichierCouleurBleu                  Ind Pos(70);

    // Protection champs
    ProtegerQuantiteInventaire              Ind Pos(42);
    ProtegerQuantiteInventaireLigne         Ind Pos(43);

    // Indicateurs d'affichage
    MasquerMessageErreur                    Ind Pos(82);
    MasquerMessageInfo                      Ind Pos(83);
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
    £CodeVerbe                                   Char(4);
    £CodeObjet                                   Char(6);
    £LibelleAction                               Char(30);
    // sorties
End-Pi;
// ---------------------------------------------------------------------

// Initialisation SQL :
Exec Sql
     Set Option Commit = *None;

// Initialisation du programme
InitialisationProgramme();

// Boucle principale
Fin = *Off;
EcranActuel = ECRAN_SELECTION;

DoW not Fin;
    Select;
        When EcranActuel = ECRAN_SELECTION;
            GestionEcranSelection();
            
        When EcranActuel = ECRAN_INVENTAIRE;
            GestionEcranInventaire();
            
        Other;
            Fin = *On;
    EndSl;
EndDo;

*Inlr=*On;

// ----------------------------------------------------------------------------
//
//                                  PROCEDURES
//
// ----------------------------------------------------------------------------

///
// InitialisationProgramme()
// Initialise les variables et paramètres nécessaires au programme
///
Dcl-Proc InitialisationProgramme;
    Dcl-Pi *N;
    End-Pi;
    
    Dcl-Ds OBJD Qualified;
        NomObjet char(10) inz('VRESTK');//On prend le nom d'un fichier au pif.
        TypeObjet char(6) inz('*FILE');
    End-Ds;

    // Initialisation des variables
    Fin = *Off;
    Refresh = *Off;   

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

    // Récupération des dernières valeurs utilisées par l'utilisateur lors du
    // dernier lancement du PGM
    DSPFSauve.TOTALITE = GetValeursUserIndex(psds.Proc:BibliothequeFichier:psds.User);
    // Initialisation code société
    If (DSPFSauve.Valeur(1) <> *BLANKS);
        EcranCodeSociete = DSPFSauve.Valeur(1);
    EndIf;
    // Initialisation code client
    If (DSPFSauve.Valeur(2) <> *BLANKS);
        EcranCodeClient = DSPFSauve.Valeur(2);
    EndIf;

    // Récupération et affichage du libellé de la société
    If EcranCodeSociete <> *BLANKS;

        EcranLibelleSociete = GetLibelleSociete();

        If (EcranLibelleSociete = *BLANKS);
            EcranLibelleSociete = *ALL'?';
        EndIf;
    EndIf;

    // Initialisation de l'écran
    Indicateur.MasquerMessageErreur = *On;
    Indicateur.MasquerMessageInfo = *On;
    EcranLibelleAction = £LibelleAction;
    EcranVerbeObjet = £CodeVerbe + £CodeObjet;
    
    // Initialisation écran sélection
    EcranDateInventaire = %Date();
    
    // Masquer le sous-fichier initialement
    Indicateur.MasquerEcranSelection = *Off;
    Indicateur.SousFichierDisplay = *Off;
    Indicateur.SousFichierDisplayControl = *Off;
End-Proc;

///
// GestionEcranSelection()
// Gère l'écran de sélection société/client
///
Dcl-Proc GestionEcranSelection;
    Dcl-Pi *N;
    End-Pi;
    
    // Masquer le sous-fichier et afficher l'écran de sélection
    Indicateur.MasquerEcranSelection = *Off;
    Indicateur.SousFichierDisplay = *Off;
    Indicateur.SousFichierDisplayControl = *Off;
    
    Write GESTIONBAS;
    ExFmt FMSELECT;
    
    // Traitement des actions
    Select;
        When fichierDS.TouchePresse = F2;
            AffichageFenetreUtilisateur(£CodeVerbe:£CodeObjet);
            
        When fichierDS.TouchePresse = F3 Or fichierDS.TouchePresse = F12;
            Fin = *On;
            
        When fichierDS.TouchePresse = F6;
            AffichageFenetreServices();
            
        When fichierDS.TouchePresse = F4;
            GestionRecherchesSelection();

        When fichierDS.TouchePresse = F23;
            GestionRecherchesMultiSelection();
            
        When fichierDS.TouchePresse = ENTREE;
            If VerificationSelection();
                //Sauvegarde saisie utilisateur
                SauvegardeSaisiesUtilisateur();

                InitialisationEcranInventaire();
                EcranActuel = ECRAN_INVENTAIRE;
                Indicateur.MasquerEcranSelection = *On;
            EndIf;
            
        Other;
    EndSl;
End-Proc;

///
// Ecran 1 : Sauvegarde des saisies utilisateurs
// - Sauvegarde des sélections dans le fichier des critères
///

Dcl-Proc SauvegardeSaisiesUtilisateur;

    DSPFSauve.Clef(1) = 'Code société';
    DSPFSauve.Valeur(1) = %Char(EcranCodeSociete);
    DSPFSauve.Clef(2) = 'Code client';
    DSPFSauve.Valeur(2) = %Char(EcranCodeClient);

    PutValeursUserIndex(DSPFSauve.Totalite:psds.PROC:BibliothequeFichier:psds.USER);
End-Proc;


///
// Initialisation écran inventaire
//
///
Dcl-Proc InitialisationEcranInventaire;
    Dcl-Pi *n ;
    End-Pi;

    // Récupération des libellés client
    VMRICL.UCOSTE = EcranCodeSociete;
    VMRICL.UCOCLI = EcranCodeClient;
    PR_VMRICL(VMRICL.UCOSTE:VMRICL.UCOCLI:VMRICL.ULISOC:VMRICL.ULIDES
             :VMRICL.ULIRUE:VMRICL.ULIVIL:VMRICL.UCOPOS:VMRICL.ULIBDI
             :VMRICL.UCOPAY:VMRICL.UCOLAN:VMRICL.UCOARC:VMRICL.UCORE1
             :VMRICL.UCORE2:VMRICL.UTXCO1:VMRICL.UTXCO2:VMRICL.URACDE
             :VMRICL.UCOLCP:VMRICL.UCOLIV:VMRICL.UCOTRA:VMRICL.UCOBLI
             :VMRICL.UFGECL:VMRICL.UCOFAC:VMRICL.UTXESC:VMRICL.UCOPAG
             :VMRICL.UCODEV:VMRICL.UCOECH:VMRICL.UCOMRG:VMRICL.UCOTAX
             :VMRICL.UTYFAC:VMRICL.UMTMFA:VMRICL.UMTMFP:VMRICL.UCOCTX
             :VMRICL.UMTCAU:VMRICL.UMTCOF:VMRICL.UCOCEC:VMRICL.UMTSTA
             :VMRICL.UMTENC:VMRICL.UMTCHT:VMRICL.UCOCTR:VMRICL.UCOTAR
             :VMRICL.UCOCOV:VMRICL.UTXREM:VMRICL.UNUCOL:VMRICL.UCORET
             :VMRICL.ULIEXP:VMRICL.UCOEDV);
    EcranClientLibelle = VMRICL.ULISOC;

    // Récupération des paramètres consignes
    Exec SQL
    Select XLIPAR
    Into :ParametresConsigne.XLIPAR
    FROM VPARAM
    Where XCORAC = :TABVV_PARAMETRESCONSIGNE 
    and XCOARG = :EcranCodeSociete;
    GestionErreurSQL();

    //Récupération écran libellé société
    EcranLibelleSocieteSelect = GetLibelleSociete();

    // Charger les données et passer à l'écran d'inventaire
    ChargerSousFichier();

End-Proc;



///
// GestionEcranInventaire()
// Gère l'écran d'inventaire avec le sous-fichier
///
Dcl-Proc GestionEcranInventaire;
    Dcl-Pi *N;
    End-Pi;
    
    Write GESTIONBAS;
    
    If NombreTotalLignesSF > 0;
        Indicateur.SousFichierDisplay = *On;
    Else;
        Indicateur.SousFichierDisplay = *Off;
    EndIf;
    Indicateur.SousFichierDisplayControl = *On;
    
    ExFmt GESTIONCTL;
    
    // Traitement des actions
    Select;
        When fichierDS.TouchePresse = F2;
            AffichageFenetreUtilisateur(£CodeVerbe:£CodeObjet);
            
        When fichierDS.TouchePresse = F3;
            ChargementEcranValidation();
            FinFenetre = *Off;
            DoW not FinFenetre;
                EXFMT FMFIN;
                Select;
                    When fichierDS.TouchePresse = F12 Or 
                    (EcranFinChoixAction = 2 AND EcranFinChoix2 <> '*');
                        FinFenetre = *On;

                    When EcranFinChoixAction = 1 AND EcranFinChoix1 <> '*';
                        If VerificationInventaire();
                            EcritureInventaire();
                            EcranActuel = ECRAN_SELECTION;
                            Refresh = *On;
                        Else;
                            Indicateur.MasquerMessageErreur = *Off;
                            EcranMessageErreur = 'Erreur de saisie';
                        EndIf;
                        FinFenetre = *On;

                    When EcranFinChoixAction = 3 AND EcranFinChoix3 <> '*';
                        If VerificationInventaire();
                            EcritureInventaire();
                            Fin = *On;
                        Else;
                            Indicateur.MasquerMessageErreur = *Off;
                            EcranMessageErreur = 'Erreur de saisie';
                            FinFenetre = *On;
                            Refresh = *On;
                        EndIf;
                        FinFenetre = *On;

                    When EcranFinChoixAction = 4 AND EcranFinChoix4 <> '*';
                        FinFenetre = *On;
                        Fin = *On;
                            
                    When EcranFinChoixAction = 5;
                        FinFenetre = *On;
                        Refresh = *On;

                    Other;
                EndSl;
            EndDo;
            
        When fichierDS.TouchePresse = F6;
            AffichageFenetreServices();
            
        When fichierDS.TouchePresse = F12;
            EcranActuel = ECRAN_SELECTION;
            
        When fichierDS.TouchePresse = ENTREE;
            If not VerificationInventaire();
                Indicateur.MasquerMessageErreur = *Off;
                EcranMessageErreur = 'Erreur de saisie';
            EndIf;
            
        Other;
    EndSl;
    
    // Si rafraîchissement nécessaire
    If Refresh;
        If EcranActuel = ECRAN_INVENTAIRE;
            ChargerSousFichier();
        EndIf;
        Refresh = *Off;
    EndIf;
End-Proc;

///
// VerificationSelection()
// Vérifie les données saisies dans l'écran de sélection
// @return *On si OK, *Off si erreur
///
Dcl-Proc VerificationSelection;
    Dcl-Pi *N Ind;
    End-Pi;
    
    Dcl-S Compteur Packed(5:0);
    
    // Réinitialisation des messages
    Indicateur.MasquerMessageErreur = *On;
    Indicateur.MasquerMessageInfo = *On;
    
    // Vérification société
    If EcranCodeSociete = *Blanks;
        EcranMessageErreur = 'Code société obligatoire';
        Indicateur.MasquerMessageErreur = *Off;
        Return *Off;
    EndIf;
    
    // Vérification existence société
    Exec SQL
        SELECT COUNT(*)
        INTO :Compteur
        FROM VPARAM
        WHERE XCORAC = 'STE' AND XCOARG = :EcranCodeSociete;
    If SQLCode <> 0 Or Compteur = 0;
        GestionErreurSQL();
        EcranMessageErreur = 'Société inexistante';
        Indicateur.MasquerMessageErreur = *Off;
        Return *Off;
    EndIf;
    
    // Vérification client
    If EcranCodeClient = *Blanks;
        EcranMessageErreur = 'Code client obligatoire';
        Indicateur.MasquerMessageErreur = *Off;
        Return *Off;
    EndIf;
    
    // Vérification existence client
    Exec SQL
        SELECT COUNT(*)
        INTO :Compteur
        FROM CLIENT
        WHERE CCOCLI = :EcranCodeClient;
    If SQLCode <> 0 Or Compteur = 0;
        GestionErreurSQL();
        EcranMessageErreur = 'Client inexistant';
        Indicateur.MasquerMessageErreur = *Off;
        Return *Off;
    EndIf;
    
    // Vérification date
    If EcranDateInventaire = *Loval;
        EcranMessageErreur = 'Date inventaire obligatoire';
        Indicateur.MasquerMessageErreur = *Off;
        Return *Off;
    EndIf;
    
    If EcranDateInventaire > %Date();
        EcranMessageErreur = 'Date inventaire future non autorisée';
        Indicateur.MasquerMessageErreur = *Off;
        Return *Off;
    EndIf;
    
    //Si tout est OK : 
    Return *On;
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

    // Nettoyage initial du sous-fichier
    Indicateur.SousFichierClear = *On;
    Write GESTIONCTL;
    Indicateur.SousFichierClear = *Off;

    //Initialisation des messages erreur/info
    Indicateur.MasquerMessageErreur = *On;  
    ECRANMESSAGEERREUR = *BLANKS;
    Indicateur.MasquerMessageInfo = *On;
    ECRANMESSAGEINFO = *BLANKS;

    // Initialisation du rang
    fichierDS.rang_sfl = 0;

    Requete = 'SELECT DISTINCT ACOART, ALIAR1 FROM VARTIC Where ACOTYA = ' 
    + QUOTE + ParametresConsigne.TypeArticle + QUOTE + ' ORDER BY ACOART';

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
        Indicateur.MasquerMessageErreur = *Off;
        
    ElseIf SQLCode = 0;// Des enregistrements ont été trouvés
        DoW SQLCode = 0;
            // Incrémentation du rang
            fichierDS.rang_sfl += 1;
            ECRANLIGNEQUANTITETHEORIE = 0;

            //Gestion des quantités théoriques en stock
            exec SQL
                select QuantiteTheoriqueStock
                Into :ECRANLIGNEQUANTITETHEORIE
                From KCOCUM
                Where codeClient = :EcranCodeClient and CodeArticle = :EcranLigneCodeArticle;
                
            If SQLCode = 100; //Pas d enregistrement trouvé
                ECRANLIGNEQUANTITETHEORIE = 0;
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
        Indicateur.SousFichierDisplay = *On;
    Else;
        Indicateur.SousFichierDisplay = *Off;
    EndIf;
    
    Indicateur.SousFichierDisplayControl = *On;
    Indicateur.SousFichierEnd = *On;
    
    // Positionnement initial
    EcranLigneSousFichier = 1;
    EcranDeplacerCurseurLigne = 9;
    EcranDeplacerCurseurColonne = 70;
End-Proc;

///
// VerificationInventaire()
// Vérifie les quantités saisies dans l'inventaire
// On vérifie que l'article est bien géré en stock dans le bon dépot des consignes
// @return *On si OK, *Off si erreur
///
Dcl-Proc VerificationInventaire;
    Dcl-Pi *N Ind;
    End-Pi;
    
    Dcl-S i Zoned(4:0);
    Dcl-S Compteur Packed(5:0);
    
    // Réinitialisation des messages
    Indicateur.MasquerMessageErreur = *On;
    Indicateur.MasquerMessageInfo = *On;
    
    For i = 1 to NombreTotalLignesSF;
        Chain i GESTIONSFL;
        
        // Vérification que les articles sont bien géré dans le dépôt des consignes
        exec sql
            select COUNT(*)
            INTO :Compteur
            from VSTOCK
            where scoart = :EcranLigneCodeArticle 
            And scodep = :ParametresConsigne.CodeDepotConsignes;
        If SQLCode <> 0 Or Compteur = 0;
            GestionErreurSQL();               
            EcranMessageErreur = 'Article ' + EcranLigneCodeArticle + ' non géré dans le dépot';
            Indicateur.MasquerMessageErreur = *Off;
        EndIf;
            
        Update GESTIONSFL;
    EndFor;
    
    Return *On;
End-Proc;


///
// EcritureInventaire()
// Écrit les résultats de l'inventaire dans les tables
///
Dcl-Proc EcritureInventaire;
    Dcl-Pi *N;
    End-Pi;
    
    Dcl-S i Zoned(4:0);
    Dcl-Ds KCOCUM_DS likeDs(KCOCUM_t);
    Dcl-S EcartLigne Packed(4:0);
        
    Monitor;
    // Générer un numéro d'inventaire unique
        NumeroInventaire = %Dec(%Char(%Date()) + %Char(%Time()) : 10 : 0);
    
    // Initialisation des mouvements de stock
        InitialisationVRESTK();
    
        For i = 1 to NombreTotalLignesSF;
            Chain i GESTIONSFL;
        
        // Calcul de l'écart pour cette ligne
            EcartLigne = EcranLigneQuantiteInventaire - EcranLigneQuantiteTheorie;
        
        // Traitement si écart ou quantité saisie
            If EcranLigneQuantiteInventaire > 0 Or EcartLigne <> 0;
            
            // Mise à jour KCOCUM
                If EcranLigneQuantiteTheorie = 0;
                // Création d'une nouvelle ligne KCOCUM
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
                        :EcranCodeClient,
                        :EcranLigneCodeArticle,
                        0,
                        0,
                        :EcartLigne,
                        :EcranLigneQuantiteInventaire,
                        CURRENT TIMESTAMP,
                        :psds.User
                    );
                Else;
                // Mise à jour d'une ligne existante
                    Exec SQL
                    UPDATE KCOCUM
                    SET QuantiteCumulEcart = :EcartLigne,
                        QuantiteTheoriqueStock = QuantiteLivree - QuantiteRetournee + :EcartLigne,
                        HorodatageSaisie = CURRENT TIMESTAMP,
                        ProfilUser = :psds.User
                    WHERE CodeClient = :EcranCodeClient
                    AND CodeArticle = :EcranLigneCodeArticle;
                EndIf;
                If SQLCode <> 0;
                    GestionErreurSQL();
                    EcranMessageErreur = 'Erreur mise à jour KCOCUM: ' + EcranLigneCodeArticle;
                    Indicateur.MasquerMessageErreur = *Off;
                    Return;
                EndIf;
            
            // Génération du mouvement de stock si écart
                If EcartLigne <> 0;
                    EcritureVRESTK(EcranLigneCodeArticle : EcartLigne);
                EndIf;
            EndIf;
        EndFor;
    
    // Intégration des mouvements de stock
        IntegrationVRESTK();
    
    On-Error;
        EcranMessageErreur = 'Erreur lors de la sauvegarde';
        Indicateur.MasquerMessageErreur = *Off;
    EndMon;
End-Proc;

///
// GestionRecherchesSelection()
// Gère les recherches F4 dans l'écran de sélection
///
Dcl-Proc GestionRecherchesSelection;
    Dcl-Pi *N;
    End-Pi;
    
    Select;
        When EcranZoneCurseur = 'ECOSTE';
            // Recherche société
            VORPAR.UCORAC = 'STE';
            VORPAR.UNUPOS = 1;
            VORPAR.UNUCON = 1;
            VORPAR.UCORTR = '0';
            VORPAR.UCOARG = *BLANKS;
            VORPAR.ULIPAR = *BLANKS;
            PR_VORPAR(VORPAR.UCORAC:VORPAR.UNUPOS:VORPAR.UNUCON
                     :VORPAR.UCORTR:VORPAR.UCOARG:VORPAR.ULIPAR);
            If VORPAR.UCORTR <> '1';
                EcranCodeSociete = VORPAR.UCOARG;
                EcranLibelleSocieteSelect = VORPAR.ULIPAR;
            EndIf;
            
            
        Other;
    EndSl;
End-Proc;

///
// GestionRecherchesMultiSelection()
// Gère les recherches F23 dans l'écran de sélection
///
Dcl-Proc GestionRecherchesMultiSelection;
    Dcl-Pi *N;
    End-Pi;
    
    Select;
        
        When EcranZoneCurseur = 'ECOCLI';
            // Recherche client
            VMRCLM.UCOSTE = EcranCodeSociete;
            VMRCLM.UCOCLI = EcranCodeClient;
            PR_VMRCLM(VMRCLM.UCOSTE:VMRCLM.UCORTR:VMRCLM.UCOCLI:VMRCLM.UMODI2);
            If VMRCLM.UCORTR <> '1';
                EcranCodeClient = VMRCLM.UCOCLI;
                EcranClientLibelle = VMRCLM.UMODI2;
            EndIf;
            
        Other;
    EndSl;
End-Proc;

///
// ChargementEcranValidation()
// Configure les options de l'écran de fin de travail
///
Dcl-Proc ChargementEcranValidation;
    Dcl-Pi *N;
    End-Pi;
    
    EcranFinChoix1 = '1';
    EcranFinChoix2 = '2';
    EcranFinChoix3 = '3';
    EcranFinChoix4 = '4';
    EcranFinChoixAction = 3;
End-Proc;

// -----------------------------------------------------------------------------
//
//                                 SERVICES
//                  Réutilisable dans d'autres programmes
//
// -----------------------------------------------------------------------------

///
// GetLibelleSociete()
// Récupère le libellé de la société
// @return Libellé de la société
///
Dcl-Proc GetLibelleSociete;
    Dcl-Pi *N Char(20);
    End-Pi;
    
    Dcl-S LibelleSocieteReturn Char(20);
    
    Exec SQL
        SELECT SUBSTR(XLIPAR, 1, 20)
        INTO :LibelleSocieteReturn
        FROM VPARAM
        WHERE XCORAC = 'STE';
    If SQLCode <> 0;
        GestionErreurSQL();
        LibelleSocieteReturn = *ALL'?';
    EndIf;
    
    Return LibelleSocieteReturn;
End-Proc;

///
// GestionErreurSQL()
// Gère les erreurs SQL et retourne un indicateur d'erreur
// @return *On si erreur, *Off si OK
///

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

///
// AffichageFenetreUtilisateur()
// Appel de la fenêtre utilisateur
///
Dcl-Proc AffichageFenetreUtilisateur;
    Dcl-Pi *N;
        CodeVerbe Char(3);
        CodeObjet Char(5);
    End-Pi;
    
    PR_GOAFENCL(CodeVerbe:CodeObjet);
End-Proc;

///
// AffichageFenetreServices()
// Appel du menu de services
///
Dcl-Proc AffichageFenetreServices;
    PR_GOASER();
End-Proc;

///
// InitialisationVRESTK()
// Initialise les valeurs pour les mouvements de stock
///
Dcl-Proc InitialisationVRESTK;
    Dcl-Pi *N;
    End-Pi;
     
    // Initialisation VRESTK
    VRESTKDS = '';

    // Récupération du compteur de mouvements
    Exec SQL
        Select DEC(XLIPAR)
        Into :VRESTKDS.NumeroMouvement
        FROM VPARAM
        Where XCORAC = :TABLE_CHARTREUSE_MOUVEMENT_STOCK_NUM
        And XCOARG = CONCAT(:ParametresConsigne.CodeDepotConsignes, :EcranCodeSociete);
    GestionErreurSQL();

    VRESTKDS.CodeSociete = EcranCodeSociete;
    VRESTKDS.CodeDepot = ParametresConsigne.CodeDepotConsignes;
    VRESTKDS.MouvementJour = %Uns(%SUBST(%char(EcranDateInventaire):1:2));
    VRESTKDS.MouvementMois = %Uns(%SUBST(%char(EcranDateInventaire):4:2));
    VRESTKDS.MouvementSiecle = %Uns(%SUBST(%char(EcranDateInventaire):7:2));
    VRESTKDS.MouvementAnnee = %Uns(%SUBST(%char(EcranDateInventaire):9:2));
    VRESTKDS.PumpAnterieur = 0;
    VRESTKDS.QuantiteAcheteeDelaisAppro = 0;
    VRESTKDS.QuantiteModifiantEncours = 0;
    VRESTKDS.PrixAchat_Fabrication = 0;
    VRESTKDS.RefMouvementNumBLNumRecep = 'INV_CONS';
    VRESTKDS.CodeProfil = psds.User;
    VRESTKDS.CreationJour = %Uns(%SUBST(%Char(%DATE()):9:2));
    VRESTKDS.CreationMois = %Uns(%SUBST(%Char(%DATE()):6:2));
    VRESTKDS.CreationAnnee = %Uns(%SUBST(%Char(%DATE()):3:2));
    VRESTKDS.CreationSiecle = %Uns(%SUBST(%Char(%DATE()):1:2));
    VRESTKDS.NomProgramme = psds.Proc;
    VRESTKDS.ModifHeure = 0;
    VRESTKDS.ModifMinute = 0;
    VRESTKDS.ModifSeconde = 0;
    VRESTKDS.VALS = 'S';
    VRESTKDS.NumeroDePoste = 0;
    VRESTKDS.ClientOuFournisseur = EcranCodeClient;
    VRESTKDS.QuantiteLogistique = 0;
End-Proc;

///
// EcritureVRESTK()
// Écriture d'un mouvement de stock pour ajustement d'inventaire
///
Dcl-Proc EcritureVRESTK;
    Dcl-Pi *N;
        p_CodeArticle Char(20);
        p_Ecart Packed(4:0);
    End-Pi;

    // Attribution des valeurs
    VRESTKDS.CodeArticle = p_CodeArticle;
    VRESTKDS.QuantiteMouvement = %Abs(p_Ecart);
    
    // Déterminer le type de mouvement selon l'écart
    If p_Ecart > 0;
        VRESTKDS.CodeMouvement = ParametresConsigne.CodeMouvementEntree;
        VRESTKDS.LibelleMouvement = 'Inventaire - Ecart positif';
    Else;
        VRESTKDS.CodeMouvement = ParametresConsigne.CodeMouvementSortie;
        VRESTKDS.LibelleMouvement = 'Inventaire - Ecart negatif';
    EndIf;

    // Récupération du code unité de gestion
    Exec SQL 
        select ACOUNG
        into :VRESTKDS.CodeUniteDeGestion
        FROM VARTIC
        Where ACOART = :p_CodeArticle;
    GestionErreurSQL();

    // Calcul du prix
    VRESTKDS.PrixUnitaireMouvement = GetPrixUnitaireArticle(
        EcranCodeSociete
        :EcranCodeClient
        :EcranDateInventaire
        :p_CodeArticle
        :%Abs(p_Ecart)
    );

    // Écriture dans VRESTK
    Exec SQL
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
    GestionErreurSQL();

    VRESTKDS.NumeroMouvement = VRESTKDS.NumeroMouvement + 1;
End-Proc;

///
// IntegrationVRESTK()
// Intégration des mouvements de stock
///
Dcl-Proc IntegrationVRESTK;
    Dcl-Pi *N;
    End-Pi;

    // Variables pour K£PIMP 
    K£PIMP.p_CodeEdition = 'VSLMVTP';
    K£PIMP.p_CodeModule = PRTF_CODE_MODULE;
    K£PIMP.p_User = psds.User;

    // Appel de K£PIMP pour les paramètres d'impression
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

    // Appel de VSLMVT2 pour l'acceptation des mouvements
    VSLMVT2.CodeSociete = EcranCodeSociete;
    VSLMVT2.Limit = ParametresConsigne.CodeDepotConsignes + EcranCodeClient;
    VSLMVT2.CodeEcran = psds.JobName;
    VSLMVT2.CodeProfil = '**********';
    
    PR_VSLMVT2(
        VSLMVT2.CodeSociete
        :VSLMVT2.Limit  
        :VSLMVT2.CodeEcran
        :VSLMVT2.CodeProfil
    );

    // Suppression des paramètres d'impression
    monitor;
        CommandeCL = 'DLTOVR FILE(VSLMVTP)';
        ExecCL(CommandeCL);
    on-error;
        dsply 'Erreur commande DLTOVR';
    endmon;

    // Mise à jour du compteur de mouvements
    Exec SQL
        Update VPARAM
        Set XLIPAR = :VRESTKDS.NumeroMouvement
        Where XCORAC = :TABLE_CHARTREUSE_MOUVEMENT_STOCK_NUM
        And XCOARG = CONCAT(:ParametresConsigne.CodeDepotConsignes, :EcranCodeSociete);
    GestionErreurSQL();
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
        Where TCOSTE = :p_CodeSociete;
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
        Where ACOART = :p_CodeArticle and ACOSTE = :p_CodeSociete;
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
// ExecCL()
// Exécute une commande CL
///
Dcl-Proc ExecCL;
    Dcl-Pi *N;
        CommandeCL VarChar(200);
    End-Pi;

    QCMDEXC(CommandeCL : %Len(CommandeCL));
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
