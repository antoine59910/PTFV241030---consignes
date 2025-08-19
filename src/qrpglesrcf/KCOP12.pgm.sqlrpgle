**free
Ctl-opt Option(*srcstmt) AlwNull(*usrctl) UsrPrf(*owner)
        DatFmt(*eur) DatEdit(*dmy) TimFmt(*hms) dftactgrp(*no)
        text('Programme d''édition des bons de livr consignes')
        bnddir('SRVPGM/UTILS':'SRVPGM/SERVICES');

// ╔══════════════════════════════════════════════════════════════════════════════════════════════╗
// ║ PROGRAMME : KCOP12                                   TYPE : Programme d'édition (PRTF)       ║
// ╠══════════════════════════════════════════════════════════════════════════════════════════════╣
// ║ TITRE     : Edition des bons de livraison de consignes                                       ║
// ╠══════════════════════════════════════════════════════════════════════════════════════════════╣
// ║ FONCTIONS :                                                                                  ║
// ║   - Génère un bon de livraison au format PRTF pour les consignes livrées                     ║
// ║   - Récupère les paramètres d'impression depuis la TABVV XIMPRE                              ║
// ║   - Calcule les prix unitaires et totaux des articles livrés                                 ║
// ║   - Met à jour le compteur d'éditions dans KCOENT                                            ║
// ║                                                                                              ║
// ║ APPELE PAR : Programme de saisie des livraisons de consignes                                 ║
// ║ PARAMETRES :                                                                                 ║
// ║   - Code société (2 car)                                                                     ║
// ║   - Numéro BL consignes (8,0)                                                                ║
// ║   - Date de livraison                                                                        ║
// ║   - Code client (9 car)                                                                      ║
// ║   - Tableau des articles livrés (code article/Libelle/quantite).                             ║
// ║   - Nombre d'articles livrés                                                                 ║
// ╠══════════════════════════════════════════════════════════════════════════════════════════════╣
// ║ AUTEUR    : ANg(Antilles Glaces)     CREE DU : 05/08/2025    AU : 16/08/2025                 ║
// ╚══════════════════════════════════════════════════════════════════════════════════════════════╝

// ══════════════════════════════════════════════════════════════════════════════════════════════
//                                      DECLARATIONS
// ══════════════════════════════════════════════════════════════════════════════════════════════

// ── Fichiers ──────────────────────────────────────────────────────────────────────────────────
Dcl-F KCOP11PM Printer OfLind(indicateurFinPage) alias;

// ── Includes standards ────────────────────────────────────────────────────────────────────────
/INCLUDE qincsrc,rpg_PSDS

// ── Constantes ────────────────────────────────────────────────────────────────────────────────
Dcl-C MODULE_CONSIGNES 'CO';
Dcl-C EDITION_BL_CONSIGNES 'KCOP11PM';
Dcl-C TABVV_PARAMETRES_CONSIGNE 'XCOPAR';
Dcl-C QUOTE '''';
Dcl-C LIGNES_MAX_PAR_PAGE 60;
Dcl-C LIGNE_DEBUT_PAGE 20;

// ── Templates de structures ───────────────────────────────────────────────────────────────────
Dcl-Ds CLIENT_t extname('CLIENT') qualified template;
End-Ds;

Dcl-Ds articleLivre_t qualified template;
    codeArticle char(20);
    libelleArticle char(30);
    quantiteLivree packed(4:0);
End-Ds;

Dcl-Ds parametresImpression_t qualified template;
    codeEdition char(10);
    codeModule Char(2);
    utilisateur Char(10);
    fileAttente char(10);
    nbExemplairesJour char(2);    
    nbExemplairesSemaine char(2);
    nbExemplairesMois char(2);
    suspendre char(4);
    conserver char(4);
End-Ds;

Dcl-Ds parametresConsigne_t qualified template;
    ligneParametre Char(100);
    typeArticle Char(1) Overlay(ligneParametre);
    codeMouvementEntree Char(2) Overlay(ligneParametre:*NEXT);
    topPrealimentationRetour Char(1) Overlay(ligneParametre:*NEXT);
    nombreExemplairesBL Char(2) Overlay(ligneParametre:*NEXT);
    codeDepotConsignes Char(3) Overlay(ligneParametre:*NEXT);
    codeMouvementSortie Char(2) Overlay(ligneParametre:*NEXT);
    compteurBLConsignes Char(8) Overlay(ligneParametre:*NEXT);
End-Ds;

// ── Procédures externes ───────────────────────────────────────────────────────────────────────
Dcl-Pr QCMDEXC ExtPgm('QCMDEXC');
    commande Char(32702) Const Options(*VarSize);
    longueur Packed(15:5) Const;
End-Pr;

Dcl-Pr getInfoClientComptable likeds(CLIENT_t) extproc('GETINFOCLIENTCOMPTABLE');
    codeClient char(9) const;
End-Pr;

Dcl-Pr GestionErreurSQL ind extproc('GESTIONERREURSQL');
    codeSQL int(10) const;
    messageContexte char(50) const options(*NoPass);
End-Pr;

Dcl-Pr GetEnteteSociete char(45) extproc('GETENTETESOCIETE');
    codeEntete char(6);
End-Pr;

Dcl-Pr KPIMP extpgm('K£PIMP');
    codeEdition char(10);
    codeModule char(2);
    utilisateur char(10);
    fileAttente char(10);
    nbExemplairesJour char(2);
    nbExemplairesSemaine char(2);
    nbExemplairesMois char(2);
    suspendre char(4);
    conserver char(4);
End-Pr;

Dcl-Pr GetPrixUnitaireArticle packed(9:2) extproc('GETPRIXUNITAIREARTICLE');
    codeSociete char(2) const;
    codeClient char(9) const;
    dateLivraison date const;
    codeArticle char(20) const;
    quantite packed(4:0) const;
End-Pr;

// ── Variables globales ────────────────────────────────────────────────────────────────────────
Dcl-S indicateurFinPage ind;
Dcl-S ligneCourrante packed(3:0);
Dcl-S numeroEditionCourant packed(2:0);
Dcl-S montantTotalClient packed(11:2);
Dcl-S commandeOverride varchar(500);
Dcl-S texteEntetePRTF char(30);
Dcl-S indexArticle packed(4:0);

Dcl-Ds parametresImpression likeds(parametresImpression_t);
Dcl-Ds parametresConsigne likeds(parametresConsigne_t);
Dcl-Ds informationsClient likeds(CLIENT_t);

// ══════════════════════════════════════════════════════════════════════════════════════════════
//                              INTERFACE DU PROGRAMME
// ══════════════════════════════════════════════════════════════════════════════════════════════

Dcl-Pi *N;
    codeSociete char(2);
    numeroBLConsignes packed(8:0);
    dateLivraison date;
    codeClient char(9);
    tableauArticlesLivres likeds(articleLivre_t) dim(999) options(*varsize);
    nombreArticlesLivres packed(3:0) const;
End-Pi;

// ══════════════════════════════════════════════════════════════════════════════════════════════
//                              PROGRAMME PRINCIPAL
// ══════════════════════════════════════════════════════════════════════════════════════════════

// Configuration SQL
Exec Sql Set Option Commit = *None;

// Validation des paramètres d'entrée
If nombreArticlesLivres = 0;
    dsply 'Erreur: Aucun article à imprimer';
    Return;
Endif;

// Récupération des paramètres
RecupererParametres();

// Configuration de l'impression
ConfigurerImpression();

// Récupération et incrémentation du numéro d'édition
RecupererNumeroEdition();

// Génération du document
GenererBonLivraison();

// Finalisation de l'impression
FinaliserImpression();

// Mise à jour du compteur d'éditions
MettreAJourNumeroEdition();

// Nettoyage
NettoyerParametresImpression();

Return;

// ══════════════════════════════════════════════════════════════════════════════════════════════
//                              PROCEDURES INTERNES
// ══════════════════════════════════════════════════════════════════════════════════════════════

// ──────────────────────────────────────────────────────────────────────────────────────────────
// Récupère les paramètres nécessaires (consignes, client, impression)
// ──────────────────────────────────────────────────────────────────────────────────────────────
Dcl-Proc RecupererParametres;
    // Paramètres consignes depuis VPARAM
    Exec SQL
        Select XLIPAR
        Into :parametresConsigne.ligneParametre
        FROM VPARAM
        Where XCORAC = :TABVV_PARAMETRES_CONSIGNE 
        and XCOARG = :codeSociete;
    
    GestionErreurSQL(sqlCode:'Récup paramètres consignes');

    // Informations client comptables
    informationsClient = getInfoClientComptable(codeClient);

    // Paramètres d'impression depuis TABVV XIMPRE
    parametresImpression.codeEdition = EDITION_BL_CONSIGNES;
    parametresImpression.codeModule = MODULE_CONSIGNES;
    parametresImpression.utilisateur = psds.User;

    KPIMP(parametresImpression.codeEdition
         :parametresImpression.codeModule 
         :parametresImpression.utilisateur       
         :parametresImpression.fileAttente       
         :parametresImpression.nbExemplairesJour      
         :parametresImpression.nbExemplairesSemaine      
         :parametresImpression.nbExemplairesMois      
         :parametresImpression.suspendre      
         :parametresImpression.conserver);
End-Proc;

// ──────────────────────────────────────────────────────────────────────────────────────────────
// Configure les paramètres d'impression via OVRPRTF
// ──────────────────────────────────────────────────────────────────────────────────────────────
Dcl-Proc ConfigurerImpression;
    // Construction du texte d'en-tête
    texteEntetePRTF = 'BL consignes ' + %char(numeroBLConsignes);

    // Construction de la commande OVRPRTF
    commandeOverride = 'OVRPRTF FILE(' + %trimr(EDITION_BL_CONSIGNES) + 
                      ') OUTQ(' + %trimr(parametresImpression.fileAttente) + 
                      ') PRTTXT(' + QUOTE + %trimr(texteEntetePRTF) + QUOTE +
                      ') COPIES(' + %trimr(parametresConsigne.nombreExemplairesBL) + 
                      ') HOLD(' + %trimr(parametresImpression.suspendre) + 
                      ') SAVE(' + %trimr(parametresImpression.conserver) + 
                      ') USRDTA(' + %trimr(psds.User) + ')';
    Monitor;
        QCMDEXC(commandeOverride: %len(commandeOverride));
    On-Error;
        dsply 'Erreur commande OVRPRTF';
    Endmon;
End-Proc;

// ──────────────────────────────────────────────────────────────────────────────────────────────
// Récupère et incrémente le numéro d'édition
// ──────────────────────────────────────────────────────────────────────────────────────────────
Dcl-Proc RecupererNumeroEdition;
    Exec SQL
        Select NombreEdition + 1
        Into :numeroEditionCourant
        From KCOENT
        Where NumeroBLConsignes = :numeroBLConsignes;
    
    If Not GestionErreurSQL(sqlCode:'Récup numéro édition');
        numeroEditionCourant = 1; // Valeur par défaut si erreur
    Endif;
End-Proc;

// ──────────────────────────────────────────────────────────────────────────────────────────────
// Génère le bon de livraison complet
// ──────────────────────────────────────────────────────────────────────────────────────────────
Dcl-Proc GenererBonLivraison;
    // Initialisation
    indicateurFinPage = *OFF;
    ligneCourrante = LIGNE_DEBUT_PAGE;
    montantTotalClient = 0;

    // Écriture de l'en-tête principal
    EcrireEntetePrincipale();

    // Écriture de l'en-tête société
    EcrireEnteteSociete();

    // Écriture de l'en-tête client
    EcrireEnteteClient();

    // Écriture des lignes d'articles
    EcrireLignesArticles();

    // Écriture du total
    Write TOTAL;
End-Proc;

// ──────────────────────────────────────────────────────────────────────────────────────────────
// Écrit l'en-tête principale du document
// ──────────────────────────────────────────────────────────────────────────────────────────────
Dcl-Proc EcrireEntetePrincipale;
    PRTF_NumeroPage = 1;
    PRTF_ProfilUtilisateur = psds.user;
    PRTF_Programme = psds.Proc;
    PRTF_Date = %Date();
    PRTF_Heure = %Time();
    PRTF_NumeroEdition = numeroEditionCourant;
    PRTF_DateLivraison = dateLivraison;

    Write ENTETE;
    Write Ligne;
End-Proc;

// ──────────────────────────────────────────────────────────────────────────────────────────────
// Écrit l'en-tête société avec toutes les lignes ZDSC
// ──────────────────────────────────────────────────────────────────────────────────────────────
Dcl-Proc EcrireEnteteSociete;
    Dcl-S codeEntete char(6);
    
    // Ecriture entête société
    codeEntete='ZDSC01';
    PRTF_ZDSC01 = GetEnteteSociete(codeEntete);
    codeEntete='ZDSC02';
    PRTF_ZDSC02 = GetEnteteSociete(codeEntete);
    codeEntete='ZDSC03';
    PRTF_ZDSC03 = GetEnteteSociete(codeEntete);
    codeEntete='ZDSC04';
    PRTF_ZDSC04 = GetEnteteSociete(codeEntete);
    codeEntete='ZDSC05';
    PRTF_ZDSC05 = GetEnteteSociete(codeEntete);
    codeEntete='ZDSC06';
    PRTF_ZDSC06 = GetEnteteSociete(codeEntete);
    codeEntete='ZDSC07';
    PRTF_ZDSC07 = GetEnteteSociete(codeEntete);
    codeEntete='ZDSC08';
    PRTF_ZDSC08 = GetEnteteSociete(codeEntete);
    codeEntete='ZDSC09';
    PRTF_ZDSC09 = GetEnteteSociete(codeEntete);
    codeEntete='ZDSC10';
    PRTF_ZDSC10 = GetEnteteSociete(codeEntete);


    Write ENTSOC;
    Write Ligne;
End-Proc;

// ──────────────────────────────────────────────────────────────────────────────────────────────
// Écrit l'en-tête client avec toutes ses informations
// ──────────────────────────────────────────────────────────────────────────────────────────────
Dcl-Proc EcrireEnteteClient;
    PRTF_ClientCode = codeClient;
    PRTF_ClientCodeGroupe = codeClient;
    PRTF_ClientLibelleSociete = informationsClient.CLISOC;
    PRTF_ClientDesignation = informationsClient.CLIDES;
    PRTF_ClientRue = informationsClient.CLIRUE;
    PRTF_ClientVille = informationsClient.CLIVIL;
    PRTF_ClientCodePostal = informationsClient.CCOPOS;
    PRTF_ClientBureauDistrib = informationsClient.CLIBDI;

    Write ENTECLI;
    Write Ligne;
End-Proc;

// ──────────────────────────────────────────────────────────────────────────────────────────────
// Écrit les lignes d'articles avec gestion du saut de page
// ──────────────────────────────────────────────────────────────────────────────────────────────
Dcl-Proc EcrireLignesArticles;
    Dcl-S prixUnitaire packed(9:2);
    Dcl-S prixTotalLigne packed(11:2);
    
    For indexArticle = 1 to nombreArticlesLivres;
        // Gestion du saut de page si nécessaire
        If ligneCourrante > LIGNES_MAX_PAR_PAGE;
            GererSautDePage();
        Endif;

        // Récupération du prix unitaire
        prixUnitaire = GetPrixUnitaireArticle(
            codeSociete
            :codeClient
            :dateLivraison
            :tableauArticlesLivres(indexArticle).codeArticle
            :tableauArticlesLivres(indexArticle).quantiteLivree
        );

        // Calcul du prix total de la ligne
        prixTotalLigne = prixUnitaire * tableauArticlesLivres(indexArticle).quantiteLivree;
        montantTotalClient += prixTotalLigne;

        // Remplissage des zones du PRTF
        PRTF_ArticleCode = tableauArticlesLivres(indexArticle).codeArticle;
        PRTF_ArticleLibelle = tableauArticlesLivres(indexArticle).libelleArticle;
        PRTF_ArticleQuantite = tableauArticlesLivres(indexArticle).quantiteLivree;
        PRTF_PrixUnitaireArticle = prixUnitaire;
        PRTF_PrixTotalLigne = prixTotalLigne;
        PRTF_PrixTotalClient = montantTotalClient;

        // Écriture de la ligne
        Write LIGNEART;
        ligneCourrante += 3;
    Endfor;

    Write Ligne;
End-Proc;

// ──────────────────────────────────────────────────────────────────────────────────────────────
// Gère le saut de page et réécrit les en-têtes
// ──────────────────────────────────────────────────────────────────────────────────────────────
Dcl-Proc GererSautDePage;
    PRTF_NumeroPage += 1;
    
    Write ENTETE;
    Write Ligne;
    Write ENTSOC;
    Write Ligne;
    Write ENTECLI;
    Write Ligne;
    
    ligneCourrante = LIGNE_DEBUT_PAGE;
End-Proc;

// ──────────────────────────────────────────────────────────────────────────────────────────────
// Finalise l'impression en fermant le fichier
// ──────────────────────────────────────────────────────────────────────────────────────────────
Dcl-Proc FinaliserImpression;
    Close KCOP11PM;
End-Proc;

// ──────────────────────────────────────────────────────────────────────────────────────────────
// Met à jour le numéro d'édition dans la base
// ──────────────────────────────────────────────────────────────────────────────────────────────
Dcl-Proc MettreAJourNumeroEdition;
    Exec SQL 
        UPDATE KCOENT
        SET NombreEdition = :numeroEditionCourant
        WHERE NumeroBLConsignes = :numeroBLConsignes;
    
    GestionErreurSQL(sqlCode:'MAJ numéro édition');
End-Proc;

// ──────────────────────────────────────────────────────────────────────────────────────────────
// Nettoie les paramètres d'impression
// ──────────────────────────────────────────────────────────────────────────────────────────────
Dcl-Proc NettoyerParametresImpression;
    Dcl-S commandeDelete varchar(100);
    
    commandeDelete = 'DLTOVR FILE(' + %trimr(EDITION_BL_CONSIGNES) + ')';
    
    Monitor;
        QCMDEXC(commandeDelete: %len(commandeDelete));
    On-Error;
        // Pas critique si la suppression échoue
    Endmon;
End-Proc;