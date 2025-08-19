**free
Ctl-opt Option(*srcstmt) AlwNull(*usrctl) UsrPrf(*owner)
        DatFmt(*eur) DatEdit(*dmy) TimFmt(*hms) dftactgrp(*no)
        text('Programme de saisie des livraisons de consignes')
        bnddir('UTILS':'SRVPGM');
// CALL PTFV241030/KCOP12

// ╔══════════════════════════════════════════════════════════════════════════════════════════════╗
// ║ PROGRAMME : KCOP12                                   TYPE : écriture PRTF                    ║
// ╠══════════════════════════════════════════════════════════════════════════════════════════════╣
// ║ TITRE     : consignes.: génération du PRTF                                                   ║
// ╠══════════════════════════════════════════════════════════════════════════════════════════════╣
// ║ FONCTIONS :                                                                                  ║
// ║                                    
// ║                                                                                              ║
// ║ APPELE PAR : 
// ╠══════════════════════════════════════════════════════════════════════════════════════════════╣
// ║ AUTEUR    : ANg(Antilles Glaces)     CREE DU : 05/08/2025    AU : 14/08/2025                 ║
// ╚══════════════════════════════════════════════════════════════════════════════════════════════╝

// ── Fichiers ──────
Dcl-F KCOP11PM Printer OfLind(Ind_FinDePagePRTF) alias;

// ── Includes standards ────
/INCLUDE qincsrc,rpg_PSDS
/INCLUDE qincsrc,c_statu_re

// ── Procédures ─────
// Permet de faire des commandes CL
Dcl-Pr QCMDEXC ExtPgm('QCMDEXC');
    commande Char(32702) Const Options(*VarSize);
    longueur Packed(15:5) Const;
End-Pr;

Dcl-Pr getInfoClientComptable likeds(CLIENT_t) extproc('GETINFOCLIENTCOMPTABLE');
    p_codeClient char(9) const;
End-Pr;

Dcl-Pr GestionErreurSQL ind extproc('GESTIONERREURSQL');
    p_codeSQL int(10) const;
    p_messageContexte char(50) const options(*NoPass);
End-Pr;

Dcl-Pr GetEnteteSociete char(45) extproc('GETENTETESOCIETE');
    p_Xcorac char(6);
End-Pr;

// ── Variables ─────
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
Dcl-Ds K£PIMP qualified ;
    p_CodeEdition char(10);
    p_CodeModule Char(2);
    p_User Char(10);
    r_outq char(20);
    r_nbexj char(2);    
    r_nbexs char(2);
    r_nbexm char(2);
    r_suspe char(4);  //C est le paramètre HOLD de OVRPRTF qui permet de suspendre 
    // le fichier spoule avant impression (hold=*YES/hold=*NO)
    r_conserver char(4);
End-Ds;

Dcl-Ds CLIENT_t extname('CLIENT') qualified template;
End-Ds;
Dcl-Ds clientInfoComptable likeds(CLIENT_t) ;

Dcl-S PRTF_CODE_MODULE Char(2) Inz('CO');  // Code module pour KPIMP
Dcl-S PRTF_CODE_EDITION Char(10) Inz('KCOP11PM'); // Code édition pour KPIMP

Dcl-S CommandeCL varChar(200);

Dcl-S lignePagePRTF         Packed(3:0);
Dcl-S NouveauNumeroEdition  Packed(2:0);    
Dcl-S prtf_txt_entete char(30);
Dcl-S i	Packed(4:0);
Dcl-S ZDSCXX Char(6);
    

Dcl-C TABVV_PARAMETRESCONSIGNE 'XCOPAR';
// TABVV XCOPAR
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

Dcl-Ds articleLivres_t qualified template;
    codeArticle char(20);
    libelleArticle char(30);
    quantiteLivree packed(4:0);
End-Ds;

// ╔══════════════════════════════════════════════════════════════════════════════════════════════╗
// ║                        P R O G R A M M E    P R I N C I P A L                                ║
// ╚══════════════════════════════════════════════════════════════════════════════════════════════╝

// Paramètres
Dcl-Pi *N;
    // entrées
    £CodeSociete            char(2);
    £NumeroBLConsignes      Packed(8:0);
    £DateLivraison          date;
    £CodeClient             Char(9);
    £TabArticlesLivres      likeds(articleLivres_t) dim(999) options(*varsize);
    £NbArticlesLivres       packed(3:0) const;
End-Pi ;

// ── Initialisation SQL ──────────────────────────────────────────────────────────────────────────
Exec Sql Set Option Commit = *None;

// Paramètres consignes
Exec SQL
    Select XLIPAR
    Into :ParametresConsigne.XLIPAR
    FROM VPARAM
    Where XCORAC = :TABVV_PARAMETRESCONSIGNE 
    and XCOARG = :£CodeSociete;
GestionErreurSQL(sqlCode:'recup TABVV consignes');

clientInfoComptable = getInfoClientComptable(£CodeClient);

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

// Execution de l OVRPRTF
CommandeCL = 'OVRPRTF FILE(' + %trimr(PRTF_CODE_EDITION) + 
                    ') OUTQ(' + %trimr(K£PIMP.r_outq) + 
                    ') PRTTXT(' + QUOTE + %trimr(prtf_txt_entete) + QUOTE +
                    ') COPIES(' + %trimr(ParametresConsigne.NombreExemplairesBL) + 
                    ') HOLD(' + %trimr(K£PIMP.r_suspe) + 
                    ') SAVE(' + %trimr(K£PIMP.r_conserver) + 
                    ') USRDTA(' + %trimr(psds.User) + ')';
Monitor;
    QCMDEXC(CommandeCL);
On-Error;
    dsply 'Erreur commande OVRPRTF';
Endmon;

// Récupération du numéro d édition
Exec SQL
    select NombreEdition + 1
    Into :NouveauNumeroEdition
    From KCOENT
    Where NumeroBLConsignes = :£NumeroBLConsignes;
GestionErreurSQL(sqlCode:'recup numéro édition KCOENT');

// Gestion de l édition du document    
Ind_FinDePagePRTF = *OFF;
lignePagePRTF=20;

// Ecriture de l entête
PRTF_NumeroPage = 1;
PRTF_ProfilUtilisateur = psds.user;
PRTF_Programme = psds.Proc;
PRTF_Date = %Date();
PRTF_Heure = %Time();
PRTF_NumeroEdition = NouveauNumeroEdition;
PRTF_DateLivraison = £DateLivraison;

Write ENTETE;

Write Ligne;

// Ecriture entête société
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

// Ecriture entête client
// Initialisation des zones de l entête du PRTF
PRTF_ClientCode = £CodeClient;
PRTF_ClientCodeGroupe = £CodeClient;
    
PRTF_ClientLibelleSociete = clientInfoComptable.CLISOC;
PRTF_ClientDesignation = clientInfoComptable.CLIDES;
PRTF_ClientRue = clientInfoComptable.CLIRUE;
PRTF_ClientVille = clientInfoComptable.CLIVIL;
PRTF_ClientCodePostal = clientInfoComptable.CCOPOS;
PRTF_CLIENTBUREAUDISTRIB = clientInfoComptable.CLIBDI;

Write ENTECLI;

Write Ligne;

For i = 1 to £NbArticlesLivres;
    PRTF_ARTICLECODE = £TabArticlesLivres(i).codeArticle;
    PRTF_ARTICLELIBELLE = £TabArticlesLivres(i).libelleArticle;
    PRTF_ARTICLEQUANTITE = £TabArticlesLivres(i).quantiteLivree;
        
    PRTF_PRIXUNITAIREARTICLE = GetPrixUnitaireArticle(
        :£CodeSociete
        :EcranCodeClient
        :£DateLivraison
        :£TabArticlesLivres(i).codeArticle
        :£TabArticlesLivres(i).quantiteLivree
        );

    PRTF_PRIXTOTALLIGNE= PRTF_PRIXUNITAIREARTICLE * £TabArticlesLivres(i).quantiteLivree;
    PRTF_PRIXTOTALCLIENT = PRTF_PRIXTOTALCLIENT + PRTF_PRIXTOTALLIGNE;
    If (lignePagePRTF > 60);
        Write ENTETE;

        Write Ligne;
        Write ENTSOC;

        Write Ligne;
        Write ENTECLI;

        Write Ligne;
        lignePagePRTF = 20;
    Endif;
    
    Write LIGNEART;

    lignePagePRTF += 3;

Endfor;
Write Ligne;
    

Write TOTAL;

// Pour déclencher l impression physique :
Close KCOP11PM;
    
// Mise à jour du numéro d édition : 
Exec SQL 
        UPDATE KCOENT
    SET 
        NombreEdition = :NouveauNumeroEdition
    WHERE 
        NumeroBLConsignes = :£NumeroBLConsignes;
GestionErreurSQL(sqlCode:'MAJ num edition');

// Suppression des paramètres d impression
CommandeCL = 'DLTOVR FILE(' + %trimr(PRTF_CODE_EDITION) + ')';
Monitor;
    QCMDEXC(CommandeCL);
On-Error;
    dsply 'Erreur commande DLTOVR FILE';
Endmon;
