**free
// ------------------------------------------------------------------------------
// NOM        : Prototypes          TYPE : Prototype + Data-structures
//
// TITRE      : Data-structures et prototypes d'appel de programmes
// ECRIT DU   :17/10/2022            PAR : ANg(Antilles Glaces)
//       AU   :17/10/2022
//
// ------------------------------------------------------------------------------

// ******************************************************************************
//                         SOCIETE DU GROUPE
// ******************************************************************************
// PR_VMTSTE : Récupération du libellé de la société via son code
// ------------------------------------------------------------------------------
// PR_VMRADS : Récupération de l'adresse de la société
// ------------------------------------------------------------------------------
/IF Defined(PR_VMTSTE)
// Prototype :
Dcl-Pr PR_VMTSTE ExtPgm('VMTSTE');// récupération du libellé de la société
    UCORET Char(001);// - (O) code retour
    UCOSTE Char(002);// - (I) code société
    ULISTE Char(020);// - (O) libellé de la société
End-Pr ;

// Data Structure :
Dcl-Ds VMTSTE Qualified;
    UCORET Char(001);// - (O) code retour
    UCOSTE Char(002);// - (I) code société
    ULISTE Char(020);// - (O) libellé de la société
End-Ds;


// Exemple d'appel :
// Récupération du libellé de la société
// VMTSTE.UCORET = '0' ;
// VMTSTE.UCOSTE = ECOSTE ;
// VMTSTE.ULISTE = *BLANKS ;
// VMTSTE(VMTSTE.UCORET
//       :VMTSTE.UCOSTE
//       :VMTSTE.ULISTE) ;
// ELISTE = VMTSTE.ULISTE;

/ENDIF

/IF Defined(PR_VMRADS)
Dcl-Pr PR_VMRADS ExtPgm('VMRADS');//- Récupération de l'adresse de la société
    UCOSTE Char(2);
    UFGPIP char(1);
    ULINOM char(32);
    ULIAD1 char(32);
    ULIAD2 char(32);
    ULICOM char(32);
    ULIVI2 char(32);
    ULIPAY char(32);
    UCOTEL char(32);
    UFGDEC char(1);
    UCOARV char(1);
    UCOARA char(1);
    UCOTLC char(32);
End-Pr;

// Data Structure :
Dcl-Ds VMRADS Qualified;
    UCOSTE Char(2);
    UFGPIP char(1);
    ULINOM char(32);
    ULIAD1 char(32);
    ULIAD2 char(32);
    ULICOM char(32);
    ULIVI2 char(32);
    ULIPAY char(32);
    UCOTEL char(32);
    UFGDEC char(1);
    UCOARV char(1);
    UCOARA char(1);
    UCOTLC char(32);
End-Ds;


// Exemple d'appel :
// VMRADS.UCOSTE = ECOSTE;
// VMRADS(VMRADS.UCOSTE
//        :VMRADS.UFGPIP
//        :VMRADS.ULINOM
//        :VMRADS.ULIAD1
//        :VMRADS.ULIAD2
//        :VMRADS.ULICOM
//        :VMRADS.ULIVI2
//        :VMRADS.ULIPAY
//        :VMRADS.UCOTEL
//        :VMRADS.UFGDEC
//        :VMRADS.UCOARV
//        :VMRADS.UCOARA
//        :VMRADS.UCOTLC);
// ELINOM = VMRADS.ULINOM;
// ELIAD1 = VMRADS.ULIAD1;
// ELIAD2 = VMRADS.ULIAD2;
// ELICOM = VMRADS.ULICOM;
// ELIVIS = VMRADS.ULIVIS;
// ELIPAY = VMRADS.ULIPAY;
// ECOTEL = VMRADS.UCOTEL;
// ECOTLC = VMRADS.UCOTLC;
/ENDIF

// /If Defined(???)
//     //Prototype :

//     //Date Structure :

//     //Exemple d'appel
// /EndIf

// ******************************************************************************
//                           CLIENT / REPRESENTANT
// ******************************************************************************
// PR_VMRICL : Récupération des données client
// ------------------------------------------------------------------------------
// PR_VMRREP : Récupération du libellé représentant
// via son code.
// ------------------------------------------------------------------------------
/IF Defined(PR_VMRICL)
// Prototype :
Dcl-Pr PR_VMRICL ExtPgm('VMRICL');//Récupération données client
    // Paramètres en entrée
    UCOSTE Char(2);// - (I) code société
    UCOCLI Char(9);// - (I) Code client
    // Paramètres en sortie
    ULISOC Char(30);
    ULIDES Char(30);
    ULIRUE Char(30);
    ULIVIL Char(30);
    UCOPOS Char(5);
    ULIBDI Char(25);
    UCOPAY Char(3);
    UCOLAN Char(2);
    UCOARC Char(1);
    UCORE1 Char(3);
    UCORE2 Char(3);
    UTXCO1 Packed(4:2);
    UTXCO2 Packed(4:2);
    URACDE Char(3);
    UCOLCP Char(1);
    UCOLIV Char(3);
    UCOTRA Char(3);
    UCOBLI Char(1);
    UFGECL Char(1);
    UCOFAC Char(1);
    UTXESC Packed(4:2);
    UCOPAG Char(1);
    UCODEV Char(3);
    UCOECH Char(3);
    UCOMRG Char(2);
    UCOTAX Char(1);
    UTYFAC Char(2);
    UMTMFA Packed(13:0);
    UMTMFP Packed(13:0);
    UCOCTX Char(1);
    UMTCAU Packed(13:2);
    UMTCOF Packed(13:0);
    UCOCEC Char(1);
    UMTSTA Packed(13:0);
    UMTENC Packed(13:2);
    UMTCHT Packed(13:2);
    UCOCTR Char(6);
    UCOTAR Char(3);
    UCOCOV Char(3);
    UTXREM Packed(5:2);
    UNUCOL Packed(2:0);
    UCORET Char(1);
    ULIEXP Char(30);
    UCOEDV Char(3);
End-Pr;

// Data Structure :
Dcl-Ds VMRICL Qualified;
    // Paramètres en entrée
    UCOSTE Char(2);// - (I) code société
    UCOCLI Char(9);// - (I) Code client
    // Paramètres en sortie
    ULISOC Char(30);
    ULIDES Char(30);
    ULIRUE Char(30);
    ULIVIL Char(30);
    UCOPOS Char(5);
    ULIBDI Char(25);
    UCOPAY Char(3);
    UCOLAN Char(2);
    UCOARC Char(1);
    UCORE1 Char(3);
    UCORE2 Char(3);
    UTXCO1 Packed(4:2);
    UTXCO2 Packed(4:2);
    URACDE Char(3);
    UCOLCP Char(1);
    UCOLIV Char(3);
    UCOTRA Char(3);
    UCOBLI Char(1);
    UFGECL Char(1);
    UCOFAC Char(1);
    UTXESC Packed(4:2);
    UCOPAG Char(1);
    UCODEV Char(3);
    UCOECH Char(3);
    UCOMRG Char(2);
    UCOTAX Char(1);
    UTYFAC Char(2);
    UMTMFA Packed(13:0);
    UMTMFP Packed(13:0);
    UCOCTX Char(1);
    UMTCAU Packed(13:2);
    UMTCOF Packed(13:0);
    UCOCEC Char(1);
    UMTSTA Packed(13:0);
    UMTENC Packed(13:2);
    UMTCHT Packed(13:2);
    UCOCTR Char(6);
    UCOTAR Char(3);
    UCOCOV Char(3);
    UTXREM Packed(5:2);
    UNUCOL Packed(2:0);
    UCORET Char(1);
    ULIEXP Char(30);
    UCOEDV Char(3);
End-Ds;


// Exemple d'appel :
// - le code client doit exister, s'il est renseigné
// VMRICL.UCOSTE = ECOSTE;
// VMRICL.UCOCLI = ECOCLI;
// VMRICL(VMRICL.UCOSTE
//       :VMRICL.UCOCLI
//       :VMRICL.ULISOC
//       :VMRICL.ULIDES
//       :VMRICL.ULIRUE
//       :VMRICL.ULIVIL
//       :VMRICL.UCOPOS
//       :VMRICL.ULIBDI
//       :VMRICL.UCOPAY
//       :VMRICL.UCOLAN
//       :VMRICL.UCOARC
//       :VMRICL.UCORE1
//       :VMRICL.UCORE2
//       :VMRICL.UTXCO1
//       :VMRICL.UTXCO2
//       :VMRICL.URACDE
//       :VMRICL.UCOLCP
//       :VMRICL.UCOLIV
//       :VMRICL.UCOTRA
//       :VMRICL.UCOBLI
//       :VMRICL.UFGECL
//       :VMRICL.UCOFAC
//       :VMRICL.UTXESC
//       :VMRICL.UCOPAG
//       :VMRICL.UCODEV
//       :VMRICL.UCOECH
//       :VMRICL.UCOMRG
//       :VMRICL.UCOTAX
//       :VMRICL.UTYFAC
//       :VMRICL.UMTMFA
//       :VMRICL.UMTMFP
//       :VMRICL.UCOCTX
//       :VMRICL.UMTCAU
//       :VMRICL.UMTCOF
//       :VMRICL.UCOCEC
//       :VMRICL.UMTSTA
//       :VMRICL.UMTENC
//       :VMRICL.UMTCHT
//       :VMRICL.UCOCTR
//       :VMRICL.UCOTAR
//       :VMRICL.UCOCOV
//       :VMRICL.UTXREM
//       :VMRICL.UNUCOL
//       :VMRICL.UCORET
//       :VMRICL.ULIEXP
//       :VMRICL.UCOEDV);
// If (UCORET = '1');
//      Ind_CodeClientInvalide = *On; //Code client invalide
//      ERREUR = 'O';
//      ELISOC = *all'?'; //On met des '?' partout
// Else;
//      ELISOC = VMRICL.ULISOC;
//      ELIDES = VMRICL.ULIDES;
//      ELIRUE = VMRICL.ULIRUE;
//      ELIVIL = VMRICL.ULIVIL;
//      ECOPOS = VMRICL.UCOPOS;
//      ELIBDI = VMRICL.ULIBDI;
//      If ECOREPO = *BLANKS;
//           ECOREP = VMRICL.UCORE1;
//      Endif;
// Endif;

/ENDIF

/IF Defined(PR_VMRREP)
// Prototype :
Dcl-Pr PR_VMRREP ExtPgm('VMRREP');//Récupération du libellé représentant
    UCOSTE Char(2);// - (I) Code société
    UCOREP Char(3);// - (I) Code représentant
    ULIA30 Char(30);// - (O) Libellé représentant
    UCORET Char(1);// - (O) Code retour
End-Pr;

// Data Structure :
Dcl-Ds VMRREP Qualified;
    UCOSTE Char(2);
    UCOREP Char(3);
    ULIA30 Char(30);
    UCORET Char(1);
End-Ds;


/ENDIF

// /If Defined(???)
//     //Prototype :

//     //Date Structure :

//     //Exemple d'appel
// /EndIf

// ******************************************************************************
//                                          ARTICLE
// **************************************************************************
// PR_VMRPXR : Récupération du prix de revient unit et calcul du montant de la ligne
// ------------------------------------------------------------------------------
// PR_VMTAR1  : Vérifie si l'article existe et en
// récupérer des informations (libellé, unité de gestion, ...)
// ------------------------------------------------------------------------------
// PR_VMRPUT  : Récupère le prix le tarif d'un article en fonction des paramètres
// ------------------------------------------------------------------------------
/IF Defined(PR_VMRPXR)
// Prototype :
Dcl-Pr PR_VMRPXR ExtPgm('VMRPXR');//Récup du prix unit de l'article + calcul du montant
    UCOSTE Char(2);
    UCOART Char(20);
    UCODEP Char(3);
    UPXREV Packed(13:4);
    UCORET Char(1);
End-Pr;

// Data Structure :
Dcl-Ds VMRPXR Qualified;
    UCOSTE Char(2);
    UCOART Char(20);
    UCODEP Char(3);
    UPXREV Packed(13:4);
    UCORET Char(1);
End-Ds;


// Exemple d'appel :
// - Récupération du prix unitaire de l'article et calcul du montant de la ligne
// If (ECOART <> *BLANKS);
//      VMRPXR.UCOSTE = ECOSTE;
//      VMRPXR.UCOART = ECOART;
//      VMRPXR.UCODEP = ECODEP;
//      VMRPXR(VMRPXR.UCOSTE
//            :VMRPXR.UCOART
//            :VMRPXR.UCODEP
//            :VMRPXR.UPXREV
//            :VMRPXR.UCORET);
//      If (Ind_CallErreur = *ON And UCORET <> '1');
//           EPULIV = UPXREV;
//           EMTLIV = EQTLIV * EPULIV;
//      ENDIF;
// ENDIF;

/ENDIF

/IF Defined(PR_VMTAR1)
// Prototype :
Dcl-Pr PR_VMTAR1 ExtPgm('VMTAR1');//Vérif article existe, récup libellé +  unité de gest
    UCOSTE Char(2);
    UCOART Char(20);
    ULIAR1 Char(30);
    ULIAR2 Char(30);
    ULIAR3 Char(30);
    UCOUNC Char(3);
    UCOUNL Char(3);
    UCOUNF Char(3);
    UCOUNG Char(3);
    UCFECG Packed(11:6);
    UCFEGF Packed(11:6);
    UCFECL Packed(11:6);
    UCOTYA Char(1);
    UCOSTO Char(1);
    UCOGLO Char(1);
    UCODEP Char(3);
    UNUGAM Char(20);
    UCORET Char(1);
End-Pr;

// Data Structure :
Dcl-Ds VMTAR1 Qualified;
    UCOSTE Char(2);
    UCOART Char(20);
    ULIAR1 Char(30);
    ULIAR2 Char(30);
    ULIAR3 Char(30);
    UCOUNC Char(3);
    UCOUNL Char(3);
    UCOUNF Char(3);
    UCOUNG Char(3);
    UCFECG Packed(11:6);
    UCFEGF Packed(11:6);
    UCFECL Packed(11:6);
    UCOTYA Char(1);
    UCOSTO Char(1);
    UCOGLO Char(1);
    UCODEP Char(3);
    UNUGAM Char(20);
    UCORET Char(1);
End-Ds;


// Exemple d'appel :
// //Vérifications des saisies
//      // - Le code article doit exister
//      //   . au passage, récupération du libellé de l'article et son unité de gest

//      If (ECOART <> *BLANKS And ECOART <> ECOARS);
//           VMTAR1.UCOSTE = ECOSTE;
//           VMTAR1.UCOART = ECOART;
//           UCORET.UCORET = ' ';
//           VMTAR1(VMTAR1.UCOSTE
//                 :VMTAR1.UCOART
//                 :VMTAR1.ULIAR1
//                 :VMTAR1.ULIAR2
//                 :VMTAR1.ULIAR3
//                 :VMTAR1.UCOUNC
//                 :VMTAR1.UCOUNL
//                 :VMTAR1.UCOUNF
//                 :VMTAR1.UCOUNG
//                 :VMTAR1.UCFECG
//                 :VMTAR1.UCFEGF
//                 :VMTAR1.UCFECL
//                 :VMTAR1.UCOTYA
//                 :VMTAR1.UCOSTO
//                 :VMTAR1.UCOGLO
//                 :VMTAR1.UCODEP
//                 :VMTAR1.UNUGAM
//                 :VMTAR1.UCORET);
//           If (Ind_CallErreur = *ON Or UCORET = '1');
//                Ind_CodeArticleInvalide = *ON;
//                ERRE01 = 'O';
//                ERREUR = 'O';
//           Else;
//                ELIART = ULIAR1;
//                ECOUNG = UCOUNG;
//                ECOARS = ECOART;
//           ENDIF;
//      ENDIF;

/ENDIF

/IF Defined(PR_VMRPUT)
// Prototype :
// Recherche tarifaire
Dcl-Pr PR_VMRPUT     ExtPgm('VMRPUT') ;
    UCOSTE   char(02) ;               // - code société
    UCOTAR   char(03) ;               // - tarif ligne
    UCOTA1   char(03) ;               // - tarif par défaut n° 1
    UCOTA2   char(03) ;               // - tarif par défaut n° 2
    UCOCLI   char(09) ;               // - code client
    UCOART   char(20) ;               // - code article
    UCOCTR   char(06) ;               // - code centrale
    UCOREG   char(06) ;               // - code regroupement
    UCOVLO   char(02) ;               // - variante logistique
    UCOVPR   char(02) ;               // - variante promo
    UDACDE   packed(06:0) ;           // - date de commande JMA
    UQTCDE   packed(11:3) ;           // - quantité commande
    UCODEV   char(03) ;               // - devise de commande
    UCOMON   char(03) ;               // - devise société
    UFGGEN   char(01) ;               // - top GENCOD
    UFGREM   char(01) ;               // - top AFFIREM
    UTXREC   packed(05:2) ;           // - remise client
    UNUCOL   packed(02:0) ;           // - n° colonne tarif client
    UPUVEN   packed(13:4) ;           // - P.U. trouvé
    UPUVAR   packed(13:4) ;           // - P.U.  article
    UTXREL   packed(05:2) ;           // - remise trouvée
End-Pr;

// Data Structure :
Dcl-Ds VMRPUT Qualified;
    UCOSTE   char(02) ;               // - code société
    UCOTAR   char(03) ;               // - tarif ligne
    UCOTA1   char(03) ;               // - tarif par défaut n° 1
    UCOTA2   char(03) ;               // - tarif par défaut n° 2
    UCOCLI   char(09) ;               // - code client
    UCOART   char(20) ;               // - code article
    UCOCTR   char(06) ;               // - code centrale
    UCOREG   char(06) ;               // - code regroupement
    UCOVLO   char(02) ;               // - variante logistique
    UCOVPR   char(02) ;               // - variante promo
    UDACDE   packed(06:0) ;           // - date de commande JMA
    UQTCDE   packed(11:3) ;           // - quantité commande
    UCODEV   char(03) ;               // - devise de commande
    UCOMON   char(03) ;               // - devise société
    UFGGEN   char(01) ;               // - top GENCOD
    UFGREM   char(01) ;               // - top AFFIREM
    UTXREC   packed(05:2) ;           // - remise client
    UNUCOL   packed(02:0) ;           // - n° colonne tarif client
    UPUVEN   packed(13:4) ;           // - P.U. trouvé
    UPUVAR   packed(13:4) ;           // - P.U.  article
    UTXREL   packed(05:2) ;           // - remise trouvée
End-Ds;

// Exemple d'appel

// Exemple d'appel dans le programme :
// Valorisation de la ligne de commande                                //

//    UCOSTE = WCOSTE ;
//    UCOTAR = WCOTAR ;
//    UCOTA1 = WCOTA1 ;
//    UCOTA2 = WCOTA2 ;
//    UCOCLI = WCOCRF ;
//    UCOART = WCOART ;
//    UCOCTR = WCOCTR ;
//    UCOREG = WCOREG ;

//    If WTARLI = 'O' ;
//         UDACDE = (DJJDLD * 10000) + (DMMDLD * 100) + DAADLD ;
//    Else ;
//         UDACDE = (DJJDCD * 10000) + (DMMDCD * 100) + DAADCD ;
//    EndIf ;

//    UQTCDE = WQTCDE ;
//    UCODEV = WCODEV ;
//    UCOMON = WCODEV ;
//    UFGGEN = '0' ;
//    UFGREM = WFGREM ;
//    UTXREC = WTXREM ;
//    UNUCOL = WNUCOL ;

//    UPUVEN = 0 ;
//    UPUVAR = 0 ;
//    UTXREL = 0 ;

//    CallP VMRPUT(UCOSTE:UCOTAR:UCOTA1:UCOTA2:UCOCLI:UCOART:UCOCTR:UCOREG:
//                 UCOVLO:UCOVPR:UDACDE:UQTCDE:UCODEV:UCOMON:UFGGEN:UFGREM:
//                 UTXREC:UNUCOL:UPUVEN:UPUVAR:UTXREL) ;

//    WPUDEV = UPUVEN ;
//    WPUFRF = UPUVEN ;
//    WPUFRC = UPUVEN ;
//    WTXRET = UTXREL ;
//    WCOTRF = UCOTAR ;

//    Calcul du prix unitaire net //

//    WNB249 = ((100 - WTXRET) / 100) * WPUFRF ;
//    WARRON = WARRPU ;
//    ExSr $ARRON ;
//    WPUNET = WNB249 ;

/ENDIF
// /If Defined(???)
//     //Prototype :

//     //Date Structure :

//     //Exemple d'appel
// /EndIf


// ******************************************************************************
//                                         DEPÔT / STOCK
// ******************************************************************************
// PR_VMRNMV : permet la numérotation des mouvements de stocks ou la récupération
//              du numéro de mouvement
// ------------------------------------------------------------------------------
// PR_VMTADP : Vérifie si l'article est géré dans le dépôt
// ------------------------------------------------------------------------------
// PR_VMTDEP : Récupération du nom du dépôt
// ------------------------------------------------------------------------------
// PR_VMTSTP : Vérifie si la quantité en stock est suffisante
//             sans prendre en compte lot/élément ni emplacement
// ------------------------------------------------------------------------------
// PR_KGDP90 : Vérifie si la quantité en stock est suffisante
//             Prend en compte les lots/éléments et emplacements
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// PR_VSLMVT2 : Accepte les mouvements de stock dans VRESTK
// ------------------------------------------------------------------------------
/IF Defined(PR_VMRNMV)
// Prototype :
Dcl-Pr PR_VMRNMV ExtPgm('VMRNMV');
    UCOSTE   Char(2);// - (I) code société
    UCODEP   Char(3);// - (I) code dépôt
    UNBMVT   Char(8);// - (O) numéro mouvement
End-Pr;

// Data Structure :
Dcl-Ds VMRNMV Qualified;
    UCOSTE   Char(2);// - (I) code société
    UCODEP   Char(3);// - (
    UNBMVT   Char(8);// -
End-Ds;


// Exemple d'appel :
// //Ecriture :
//      //  - des mouvements de stock dans VRESTK
//      //  - des lignes dans le fichier historique KPBFAT
//      // - édition des lignes saisies
//      // Todo: Déclarer toutes les variables
//      For NL = 1 to WLIGN2;
//           Chain NL FM2SF;
//           If %EOF(FM2SF) and ECOART <> *BLANKS;
//                VMRNMV.UCOSTE = ECOSTE;
//                VMRNMV.UCODEP = ECODEP;
//                VMRNMV.UNBMVT = '00000001';
//                VMRNMV(VMRNMV.UCOSTE
//                      :VMRNMV.UCODEP
//                      :VMRNMV.UNBMVT);
//                RNUMVT = UNBMVT;
//                RCOSTE = ECOSTE;
//                RCODEP = ECODEP;
//                JMA = EDALIV;
//                RJJMVT = JJ1;
//                RMMMVT = MM1;
//                RAAMVT = AA1;
//                RXXMVT = 20;
//                RCOMVT = WCOMVT;
//                RCOART = ECOART;
//                RQTMVT = EQTLIV;
//                RCOUNG = ECOUNG;
//                RPUMVT = EPULIV;
//                RCOPRF = £COPRO;
//                RJJCRE = JJJOU;
//                RMMCRE = MMJOU;
//                RXXCRE = SSJOU;
//                RAACRE = AAJOU;
//                RCOPGM = £COPGM;
//                RCOTYP = 'S';
//                RCLOFO = *BLANKS;
//                RCORFC = *BLANKS;
//                SELECT;
//                     When ECOCLI <> *BLANKS;
//                          RCORFC = 'C-'+ '' + ECOCLI;
//                     When ECOREP <> *BLANKS;
//                          RCORFC = 'R-'+ '' + ECOREP;
//                          ELISOC = LIBREP+ '  ' + ECOREP;
//                          ELIDES = ELIREP;
//                     When ECOSPE <> *BLANKS;
//                          RCORFC = 'S-'+ '' + ECOSPE;
//                          ELISOC = LIBSPE+ '  ' + ECOSPE;
//                          ELIDES = ELISPE;
//                ENDSL;
//                YCORFC = RCORFC ;
//                YCOART = RCOART ;
//                YLIART = ELIART ;
//                YQTLIV = RQTMVT ;
//                YCOUNG = RCOUNG ;
//                YPULIV = RPUMVT ;
//                YMTLIV = EMTLIV ;
//                Write KPBFATF ;
//                Write VRESTKF;
//                EXSR $DETAI;
//           ENDIF;
//      ENDFOR;

//    //Récupération du compteur de mouvements :
//     VMRNMV.UCOSTE = CodeSociete;
//     VMRNMV.UCODEP = EcranCodeDepot;
//     VMRNMV.UNBMVT = '00000001';
//     PR_VMRNMV(VMRNMV.UCOSTE
//               :VMRNMV.UCODEP
//               :VMRNMV.UNBMVT);

/ENDIF

/IF Defined(PR_VMTADP)
// Prototype :
Dcl-Pr PR_VMTADP ExtPgm('VMTADP');//Permet de savoir si l'article est géré dans le dépôt
    UCOSTE Char(2);
    UCODEP Char(3);
    UCOART Char(20);
    UCORET Char(1);
    UTYAPR Char(1);
    UQTMAX Packed(9:0);
End-Pr;

// Data Structure :
Dcl-Ds VMTADP Qualified;
    UCOSTE Char(2);
    UCODEP Char(3);
    UCOART Char(20);
    UCORET Char(1);
    UTYAPR Char(1);
    UQTMAX Packed(9:0);
End-Ds;


// Exemple d'appel :
// // - L'article doit être géré dans le dépôt
// If (ECOART <> *BLANKS);
//      VMTADP.UCOSTE = ECOSTE;
//      VMTADP.UCODEP = ECODEP;
//      VMTADP.UCOART = ECOART;
//      VMTADP.UCORET = ' ';
//      VMTADP(VMTADP.UCOSTE
//            :VMTADP.UCODEP
//            :VMTADP.UCOART
//            :VMTADP.UCORET
//            :VMTADP.UTYAPR
//            :VMTADP.UQTMAX);
//      If (Ind_CallErreur = *ON Or UCORET = '1');
//           Ind_ArticleNonGere = *ON;
//           ERRE02 = 'O';
//           ERREUR = 'O';
//      ENDIF;
// ENDIF;

/ENDIF

/IF Defined(PR_VMTDEP)
// Prototype :
Dcl-Pr PR_VMTDEP ExtPgm('VMTDEP');
    UCORET Char(1);
    UCODEP Char(3);
    ULIPA1 Char(26);
    ULIPA2 Char(27);
End-Pr;


// Data Structure :
Dcl-Ds VMTDEP Qualified;
    UCORET Char(1);
    UCODEP Char(3);
    ULIPA1 Char(26);
    ULIPA2 Char(27);
End-Ds;


// Exemple d'appel :
// VMTDEP.UCORET = '0';
// VMTDEP.UCODEP = ECODEP;
// VMTDEP.ULIAP1 = *BLANKS;
// VMTDEP.ULIAP2 = *BLANKS;
// VMTDEP(VMTDEP.UCORET
//       :VMTDEP.UCODEP
//       :VMTDEP.ULIPA1
//       :VMTDEP.ULIPA2);
// ELIDEP = VMTDEP.ULIAP1;
// If (Ind_CallErreur = *ON Or UCORET = '1');
//      ELIDEP = *ALL'?';
// ENDIF;

/ENDIF

/IF Defined(PR_VMTSTP)
// Prototype :
Dcl-Pr PR_VMTSTP ExtPgm('VMTSTP');//Permet de savoir si la quantité en stock est suffisante
    UCOSTE Char(2);
    UCODEP Char(3);
    UCOART Char(20);
    UQTUNG Packed(11:3);
    UCORET Char(1);
    UQTRES Packed(11:3);
End-Pr;

// Data Structure :
Dcl-Ds VMTSTP Qualified;
    UCOSTE Char(2);
    UCODEP Char(3);
    UCOART Char(20);
    UQTUNG Packed(11:3);
    UCORET Char(1);
    UQTRES Packed(11:3);
End-Ds;



// Exemple d'appel :
// // - la quantité en stock doit être suffisante
// If (ECOART <> *BLANKS And EQTLIVE > 0);
//      VMTSTP.UCOSTE = ECOSTE;
//      VMTSTP.UCODEP = ECODEP;
//      VMTSTP.UCOART = ECOART;
//      VMTSTP.EQTLIVE = UQTUNG;
//      VMTSTP.UCORET = ' ';
//      VMTSTP(VMTSTP.UCOSTE
//            :VMTSTP.UCODEP
//            :VMTSTP.UCOART
//            :VMTSTP.UQTUNG
//            :VMTSTP.UCORET
//            :VMTSTP.UQTRES);
//      If (Ind_CallErreur = *ON Or UCORET = '1');
//           Ind_CodeSpecifiqueInvalide = *ON;
//           ERRE04 = 'O';
//           ERREUR = 'O';
//      ENDIF;
// ENDIF;

/ENDIF

/IF Defined(PR_KGDP90)
// Prototype :
Dcl-Pr PR_KGDP90     ExtPgm('KGDP90') ;           // calcul de la quantité disponible
    UCOSTE   char(02) ;               // - (I) code société
    UCODEP   char(03) ;               // - (I) code dépôt
    UCOART   char(20) ;               // - (I) code article
    UCOEMP   char(07) ;               // - (I) code emplacement
    UCOLOT   char(13) ;               // - (I) code lot
    UCOELT   char(08) ;               // - (I) numéro d'élément de lot
    UTYELT   char(08) ;               // - (I) type de numéro d'élément
    UDABES   char(08) ;               // - (I) date du besoin (SSAAMMJJ)
    URESER   char(01) ;               // - (I) prise en compte des quantités réserv.
    USLOBL   char(01) ;               // - (I) acceptation des lots bloqués
    USLOND   char(01) ;               // - (I) acceptation des lots non disponibles
    USLODD   char(01) ;               // - (I) acceptation des lots à date dépassée
    UQTDSP   packed(11:3) ;           // - (O) quantité disponible
    UCORET   char(01) ;               // - (O) code retour
End-Pr PR_KGDP90 ;

// Data Structure :
Dcl-Ds KGDP90 Qualified;
    CodeSociete                     char(02) ;
    CodeDepot                       char(03) ;
    CodeArticle                     char(20) ;
    CodeEmplacement                 char(07) ;
    CodeLot                         char(13) ;
    CodeElement                     char(08) ;
    TypeElement                     char(08) ;
    DateBesoin                      char(08) ;
    PriseEnCompteQuantiteReserve    char(01) ;
    AcceptationLotsBloques          char(01) ;
    AcceptationLotsNonDisponibles   char(01) ;
    AcceptationLotsDateDepassee     char(01) ;
    QuantiteDisponible              packed(11:3) ;
    CodeRetour                      char(01) ;
End-Ds;

// Exemple d'appel
// CallP PR_KGDP90(
//     :KGDP90.CodeSociete
//     :KGDP90.CodeDepot
//     :KGDP90.CodeArticle
//     :KGDP90.CodeEmplacement
//     :KGDP90.CodeLot
//     :KGDP90.CodeElement
//     :KGDP90.TypeElement
//     :KGDP90.DateBesoin
//     :KGDP90.PriseEnCompteQuantiteReserve
//     :KGDP90.AcceptationLotsBloques
//     :KGDP90.AcceptationLotsNonDisponibles
//     :KGDP90.AcceptationLotsDateDepassee
//     :KGDP90._QuantiteDisponible
//     :KGDP90._CodeRetour
// )

// If KGDP90._CodeRetour = '0' ;
//     QuantiteDisponible = KGDP90._QuantiteDisponible ;
// Else ;
//     QuantiteDisponible = 0 ;
// EndIf ;
/ENDIF

/IF Defined(PR_VSLMVT2)
// Prototype :
Dcl-Pr PR_VSLMVT2 ExtPgm('VSLMVT2');
    p_CodeSociete Char(2);    // Code société
    p_Limit       Char(6);    // Code dépôt début/fin   
    p_CodeEcran   Char(10);   // Code écran 
    p_CodeProfil  Char(10);   // Code profil
End-Pr;

// Data Structure :
Dcl-Ds VSLMVT2 Qualified; 
    CodeSociete  Char(2);
    Limit        Char(6); 
    CodeEcran    Char(10);
    CodeProfil   Char(10);
End-Ds;

// Exemple d'appel :
// VSLMVT2.CodeSociete = Societe.Code;
// VSLMVT2.Limit = ParametresConsigne.CodeDepotConsignes + ParametresConsigne.CodeDepotConsignes;
// VSLMVT2.CodeEcran = psds.Job;
// VSLMVT2.CodeProfil = '**********';
// PR_VSLMVT2(
//   VSLMVT2.CodeSociete
//   :VSLMVT2.Limit
//   :VSLMVT2.CodeEcran
//   :VSLMVT2.CodeProfil
// );
/ENDIF

// /If Defined(???)
//     //Prototype :

//     //Date Structure :

//     //Exemple d'appel
// /EndIf

// ******************************************************************************
//                                               DSPF
// ******************************************************************************
// PR_GOAFENCL : Gestion de la fenêtre utilisateur (F2)
// ------------------------------------------------------------------------------
// PR_GMRCR2 : Récupération du fichier des dernières valeurs utilisées
// ------------------------------------------------------------------------------
// PR_GMMCR2 : Mise à jour du fichier des dernières valeurs utilisées
// ------------------------------------------------------------------------------
// PR_GOASER : Gestion de la fenêtre de services (F6)
// ------------------------------------------------------------------------------
// PR_RMRBACI : Constitue la barre d'action
// ------------------------------------------------------------------------------
// PR_VMIART : Interrogation des articles par F4
// ------------------------------------------------------------------------------
// PR_VMRCLM : Recherche multicritères code client Afin de savoir s'il existe et de récu
//  son libellé (Mot Directeur)
// ------------------------------------------------------------------------------
// PR_VORPAR : Recherche sur société du groupe
// ------------------------------------------------------------------------------
// PR_VVRCLI : Recherche sur Code Client
// --------------------------------------------------------------------
// PR_VSIEMP : Interrogation des emplacements par F4 /!\ nécessite LDA
// ------------------------------------------------------------------------------
// PR_VSERLO : Recherche multicritère sur emplacement/lot/élément
// ------------------------------------------------------------------------------
// PR_CrtUserIndex : Création d'un UserIndex :
// https://www.rpgpgm.com/2022/12/adding-and-updating-data-in-user-index.html
// ------------------------------------------------------------------------------
// PR_VMRARM : Recherche multicritères des articles
// ------------------------------------------------------------------------------

/IF defined(PR_GOAFENCL)
// Prototype :
Dcl-Pr PR_GOAFENCL ExtPgm('GOAFENCL');// gestion de la fenêtre utilisateur (F2)
    UCOVFU   char(003);// - (I) code verbe
    UCOOFU   char(005);// - (I) code objet
End-Pr;

// Data Structure :
Dcl-Ds GOAFENCL Qualified;
    UCOVFU Char(3);
    UCOOFU Char(5);
End-Ds;

// Exemple d'appel :
//  //Appel de la fenêtre utilisateur
//      GOAFENCL.UCOVFU = £COVER;
//      GOAFENCL.UCOOFU = £COOBJ;
//      GOAFENCL(GOAFENCL.UCOVFU
//              :GOAFENCL.UCOOFU);
/ENDIF

/IF Defined(PR_GMMCR2)
// Prototype :
Dcl-Pr PR_GMMCR2 ExtPgm('GMMCR2');//Mise à jour de VDclUT ???
    UCOPRO   char(010) ;                     // - (I) profil utilisateur
    UCOVER   char(004) ;                     // - (I) action : code verbe
    UCOOBJ   char(006) ;                     // - (I) action : code objet
    UNUVER   packed(02:0) ;                  // - (I) numéro de version
    UZONE1   char(256) ;                     // - (O) zone de données : 1
    UZONE2   char(256) ;                     // - (O) zone de données : 2
    UZONE3   char(256) ;                     // - (O) zone de données : 3
    UZONE4   char(256) ;                     // - (O) zone de données : 4
End-Pr;

// Data Structure :
Dcl-Ds GMMCR2 Qualified;
    UCOPRO   char(010) ;                     // - (I) profil utilisateur
    UCOVER   char(004) ;                     // - (I) action : code verbe
    UCOOBJ   char(006) ;                     // - (I) action : code objet
    UNUVER   packed(02:0) ;                  // - (I) numéro de version
    UZONE1   char(256) ;                     // - (O) zone de données : 1
    UZONE2   char(256) ;                     // - (O) zone de données : 2
    UZONE3   char(256) ;                     // - (O) zone de données : 3
    UZONE4   char(256) ;                     // - (O) zone de données : 4
End-Ds;
/ENDIF

/IF Defined(PR_GMRCR2)
// Prototype :
Dcl-Pr PR_GMRCR2 ExtPgm('GMRCR2');//Mise à jour de VDclUT ???
    UCOPRO   char(010) ;                     // - (I) profil utilisateur
    UCOVER   char(004) ;                     // - (I) action : code verbe
    UCOOBJ   char(006) ;                     // - (I) action : code objet
    UNUVER   packed(02:0) ;                  // - (I) numéro de version
    UZONE1   char(256) ;                     // - (O) zone de données : 1
    UZONE2   char(256) ;                     // - (O) zone de données : 2
    UZONE3   char(256) ;                     // - (O) zone de données : 3
    UZONE4   char(256) ;                     // - (O) zone de données : 4
End-Pr;

// Data Structure :
Dcl-Ds GMRCR2 Qualified;
    UCOPRO   char(010) ;                     // - (I) profil utilisateur
    UCOVER   char(004) ;                     // - (I) action : code verbe
    UCOOBJ   char(006) ;                     // - (I) action : code objet
    UNUVER   packed(02:0) ;                  // - (I) numéro de version
    UZONE1   char(256) ;                     // - (O) zone de données : 1
    UZONE2   char(256) ;                     // - (O) zone de données : 2
    UZONE3   char(256) ;                     // - (O) zone de données : 3
    UZONE4   char(256) ;                     // - (O) zone de données : 4
End-Ds;
/ENDIF

/IF Defined(PR_GOASER)
// Prototype :


// Data Structure :

// Exemple d'appel :
// //Appel de la fenêtre utilisateur
//      PR_GOASER();
/ENDIF

/IF Defined(PR_RMRBACI)
// Prototype :

Dcl-Pr PR_RMRBACI ExtPgm('RMRBACI');// constitution de la barre d'action
    ListeVerbesSouhaites Char(32); // (anciennement TTVS)
    ListeObjetsSouhaites Char(48); // (anciennement TTOS)
    ListeVerbesAutorises Char(32); // (anciennement TTVA)
    ListeObjetsAutorises Char(48); // (anciennement TTOA)
    ListeActionsEcran Char(136); // (anciennement TTLV)
    ListeLibellesActionsAutorisees Char(240); // (anciennement TTLA)
End-Pr PR_RMRBACI;

// Data Structure :
Dcl-Ds RMRBACI Qualified;

    ListeVerbesSouhaites   Char(32);
    VerbeSouhaite    Char(4)    Dim(8) Overlay(ListeVerbesSouhaites); //Anciennement TVS

    ListeObjetsSouhaites   Char(48)   ;
    ObjetSouhaite    Char(6)    Dim(8) Overlay(ListeObjetsSouhaites);//Anciennement TOS

    ListeVerbesAutorises   Char(32)   ;
    VerbeAutorise    Char(4)    Dim(8) Overlay(ListeVerbesAutorises);//Anciennement TVA

    ListeObjetsAutorises   Char(48)   ;
    ObjetAutorise    Char(6)    Dim(8) Overlay(ListeObjetsAutorises); //Anciennement TOA

    ListeActionsEcran   Char(136);
    Action1 Char(17)   Overlay(ListeActionsEcran);//Anciennement ELIOP1
    Action2 Char(17)   Overlay(ListeActionsEcran:*NEXT);
    Action3 Char(17)   Overlay(ListeActionsEcran:*NEXT);
    Action4 Char(17)   Overlay(ListeActionsEcran:*NEXT);
    Action5 Char(17)   Overlay(ListeActionsEcran:*NEXT);
    Action6 Char(17)   Overlay(ListeActionsEcran:*NEXT);
    Action7 Char(17)   Overlay(ListeActionsEcran:*NEXT);
    Action8 Char(17)   Overlay(ListeActionsEcran:*NEXT);
    ActionEcran    Char(17)   Dim(8) Overlay(ListeActionsEcran);//Anciennement TLV

    ListeLibellesActionsAutorisees   Char(240)  ;
    LibelleActionAutorisee    Char(30)   Dim(8) //Ancienement TLA
                                Overlay(ListeLibellesActionsAutorisees);

End-Ds;


// Exemple d'appel :
// RMRBACI(RMRBACI.TTVS
//       :RMRBACI.TTOS
//       :RMRBACI.TTVA
//       :RMRBACI.TTOA
//       :RMRBACI.TTLV
//       :RMRBACI.TTLA);

/ENDIF

/IF Defined(PR_VMIART)
// Prototype :
Dcl-Pr PR_VMIART     ExtPgm('VMIART');// interrogation des articles par F4
    UCOSTE   Char(002);// - (I) code société
    UCORTR   Char(001);// - (O) code retour
    UCOART   Char(020);// - (O) code article
    ULIDIR   Char(020);// - (O) libellé article réduit
    ULIAR1   Char(030);// - (O) libellé article 1
    ULIAR2   Char(030);// - (O) libellé article 2
End-Pr PR_VMIART ;

// Data Structure :
Dcl-Ds VMIART Qualified;
    UCOSTE   char(002);// - (I) code société
    UCORTR   char(001);// - (O) code retour
    UCOART   char(020);// - (O) code article
    ULIDIR   char(020);// - (O) libellé article réduit
    ULIAR1   char(030);// - (O) libellé article 1
    ULIAR2   char(030);// - (O) libellé article 2
End-Ds;


// Exemple d'appel :
// //Recherhe sur code article
//      If EZONCU = 'ECOART';
//           Chain (ELICSR) FM2SF;
//           If %EOF(FM2SF);
//                VMIART.UCOART = ECOART;
//           ENDIF;
//           VMIART.UCOSTE = ECOSTE;
//           VMIART.UCORTR = ' ';
//           VMIART.ULIDIR = *BLANKS;
//           VMIART.ULIAR1 = *BLANKS;
//           VMIART.ULIAR2 = *BLANKS;
//           VMIART(VMIART.UCOSTE
//                 :VMIART.UCORTR
//                 :VMIART.UCOART
//                 :VMIART.ULIDIR
//                 :VMIART.ULIAR1
//                 :VMIART.ULIAR2);
//      ENDIF;
//      If (Ind_CallErreur = *OFF And UCORTR <> '1');
//           Chain (ELICSR) FM2SF;
//           If %EOF(FM2SF);
//                ECOART = UCOART;
//                ELIART = ULIAR1;
//                Update FM2SF;
//           ENDIF;
//      ENDIF;

/ENDIF

/IF Defined(PR_VMRCLM)
// Prototype :
Dcl-Pr PR_VMRCLM ExtPgm('VMRCLM');//Recherche sur code client
    UCOSTE Char(2);// - (I) Code société
    UCORTR Char(1);// - (O) Code retour
    UCOCLI Char(9);// - (I) Code client
    UMODI2 Char(20);// - (O) Mot directeur Client
End-Pr;

// Data Structure :
Dcl-Ds VMRCLM Qualified;
    UCOSTE Char(2);
    UCORTR Char(1);
    UCOCLI Char(9);
    UMODI2 Char(20);
End-Ds;


// Exemple d'appel :
// //Recherche sur code client
// If (EZONCU = 'ECOCLI');
//      VMRCLM.UCOSTE = ECOSTE;
//      VMRCLM.UCOCLI = ECOCLI;
//      VMRCLM(VMRCLM.UCOSTE
//            :VMRCLM.UCORTR
//            :VMRCLM.UCOCLI
//            :VMRCLM.UMODI2);
//      If (Ind_CallErreur = *OFF And VMRCLM.UCORTR <> '1');
//           ECOCLI = VMRCLM.UCOCLI;
//           ELISOC = VMRCLM.UMODI2;
//      EndIf;
// EndIf;

/ENDIF

/IF Defined(PR_VORPAR)
// Prototype :
Dcl-Pr PR_VORPAR ExtPgm('VORPAR');// récupération des données d'un paramètre
    UCORAC Char(006);// - (I) code racine
    UNUPOS Packed(02:0);// - (I) position
    UNUCON Packed(02:0);// - (I) numéro de contenu
    UCORTR Char(001);// - (O) code retour
    UCOARG Char(012);// - (O) argument
    ULIPAR Char(090);// - (O) libellé
End-Pr  ;


// Data Structure :
Dcl-Ds VORPAR Qualified;
    UCORAC Char(006);
    UNUPOS Packed(02:0);
    UNUCON Packed(02:0);
    UCORTR Char(001);
    UCOARG Char(012);
    ULIPAR Char(090);
End-Ds;


// Exemple d'appel dans le programme :
// Recherche sur code société
// If (EZONCU = 'ECOSTE');
//      VORPAR.UCORAC = 'STE';
//      VORPAR.UNUPOS = 1;
//      VORPAR.UNUCON = 1;
//      VORPAR.UCORTR = '0';
//      VORPAR.UCOARG = *BLANKS;
//      VORPAR.ULIPAR = *BLANKS;
//      VORPAR(VORPAR.UCORAC
//            :VORPAR.UNUPOS
//            :VORPAR.UNUCON
//            :VORPAR.UCORTR
//            :VORPAR.UCOARG
//            :VORPAR.ULIPAR);
//      If (Ind_CallErreur = *OFF And VORPAR.UCORTR <> '1');
//           ECOSTE = VORPAR.UCOARG;
//           ELISTE = VORPAR.ULIPAR;
//      EndIf;
// EndIf;
/ENDIF

/IF Defined(PR_VVRCLI)
// Prototype :
Dcl-Pr PR_VVRCLI ExtPgm('VVRCLI');//Récupération du libellé client
    UCOSTE Char(2);// - (I) code société
    UCORTR Char(1);// - (O) code retour
    UCOCLI Char(9);// - (I) code client
    UMODIR Char(15);// - (O) Mot directeur Client
End-Pr PR_VVRCLI;

// Data Structure :
Dcl-Ds VVRCLI Qualified;
    UCOSTE  Char(2);
    UCORTR  Char(1);
    UCOCLI  Char(9);
    UMODIR  Char(15);
End-Ds;


// Exemple d'appel dans le programme :
// Recherche sur code client
// If (EZONCU = 'ECOCLI');
//      VVRCLI.UCOSTE = ECOSTE;
//      VVRCLI.UCORTR = ' ';
//      VVRCLI.UCOCLI = ECOCLI;
//      VVRCLI(VVRCLI.UCOSTE
//            :VVRCLI.UCORTR
//            :VVRCLI.UCOCLI
//            :VVRCLI.UMODIR);
//      If (Ind_CallErreur = *OFF And VVRCLI.UCORTR <> '1');
//           ECOCLI = VVRCLI.UCOCLI;
//           ELISOC = VVRCLI.UMODIR;
//      EndIf;
// EndIf;
/ENDIF

// !!!!!!   /!\ NECESSITE D INCLUDE LDA  /!\ !!!!!!!
/IF defined(PR_VSIEMP) 

// Prototype :
Dcl-Pr PR_VSIEMP     ExtPgm('VSIEMP');           // interrogation des emplacements par F
    UCOVE1   char(003);              // - (I) action : code verbe
    UCOOB1   char(005);              // - (I) action : code objet
    ULIAC1   char(030);              // - (I) action : libellé
    UCOPG1   char(008);              // - (O) code programme
    UCORE1   char(008);              // - (O) code retour
    UCOSTE   char(002);              // - (I) code société
    UCODEP   char(003);              // - (I) code dépôt
    UCORET   char(001);              // - (O) code retour
End-Pr PR_VSIEMP ;

// Data Structure :
Dcl-Ds VSIEMP Qualified;
    UCOVE1   char(003);
    UCOOB1   char(005);
    ULIAC1   char(030);
    UCOPG1   char(008);
    UCORE1   char(008);
    UCOSTE   char(002);
    UCODEP   char(003);
    UCORET   char(001);
End-Ds;

// Exemple d'appel dans le programme :
//     If EZONCU = 'ECOEMO' ;
//            LDA.ZONETOTALE = ' ' ;
//            Out LDA ;
//            UCOVE1 = 'INT' ;
//            UCOOB1 = 'EMPLA' ;
//            ULIAC1 = ' ' ;
//            UCOPG1 = ' ' ;
//            UCORE1 = ' ' ;
//            UCOSTE = ECOSTE ;
//            UCODEP = ECODEO ;
//            UCORET = ' ' ;
//            CallP VSIEMP(VSIEMP.UCOVE1:VSIEMP.UCOOB1:VSIEMP.ULIAC1:VSIEMP.UCOPG1
//            :VSIEMP.UCORE1:VSIEMP.UCOSTE:VSIEMP.UCODEP:VSIEMP.UCORET) ;
//
//            If VSIEMP.UCORET <> '1' ;
//                 In LDA ;
//                 EcranCodeEmplacement = LDA.CodeEmplacement ;
//            EndIf ;
//       EndIf ;

/ENDIF


/IF defined(PR_VSRELO)
// Prototype :
Dcl-Pr PR_VSRELO     ExtPgm('VSRELO') ;  // interrogation des emplacements-lots
    UCOVE1   char(003) ;              // - (I) action : code verbe
    UCOOB1   char(005) ;              // - (I) action : code objet
    ULIAC1   char(030) ;              // - (I) action : libellé
    UCOPG1   char(008) ;              // - (O) code programme
    UCORE1   char(008) ;              // - (O) code retour
    UCOSTE   char(002) ;              // - (I) code société
    UCODEP   char(003) ;              // - (I) code dépôt
    UCOART   char(020) ;              // - (I) code article
    UCORET   char(001) ;              // - (O) code retour
End-Pr ;

// DataStructure :
Dcl-Ds VSRELO Qualified ;           // interrogation des emplacements-lots par F23
    UCOVE1   char(003) ;              // - (I) action : code verbe
    UCOOB1   char(005) ;              // - (I) action : code objet
    ULIAC1   char(030) ;              // - (I) action : libellé
    UCOPG1   char(008) ;              // - (O) code programme
    UCORE1   char(008) ;              // - (O) code retour
    UCOSTE   char(002) ;              // - (I) code société
    UCODEP   char(003) ;              // - (I) code dépôt
    UCOART   char(020) ;              // - (I) code article
    UCORET   char(001) ;              // - (O) code retour
End-Ds ;

// Exemple d'appel dans le programme :
// If (EZONCU = 'ECOEMO' or EZONCU = 'ECOLOT' or EZONCU = 'ECOELO')
//       and TROUVE = 'O' ;
//         UZONE0 = ' ' ;
//         out LDA ;
//         UCOVE1 = 'REC' ;
//         UCOOB1 = 'EMPLO' ;
//         ULIAC1 = ' ' ;
//         UCOPG1 = ' ' ;
//         UCORE1 = ' ' ;
//         UCOSTE = ECOSTE ;
//         UCODEP = ECODEO ;
//         UCOART = ECOART ;
//         UCORET = ' ' ;
//         CallP VSRELO(UCOVE1:UCOOB1:ULIAC1:UCOPG1:UCORE1:UCOSTE:UCODEP:
//                      UCOART:UCORET) ;
//         If UCORET <> '1' ;
//              in LDA ;
//              ECOEMO = UCOEMP ;
//              ECOLOT = UCOLOT ;
//              ECOELO = %uns(UCOELT) ;
//         EndIF ;
//    EndIF ;
/ENDIF

/IF Defined(PR_VMRARM)
Dcl-Pr PR_VMRARM    ExtPgm('VMRARM');
    UCOSTE   char(002) ;              // - (I) code société
    UCORTR   char(001) ;              // - (I) code retour
    UCOART   char(020) ;              // - (I) code article
    ULIDIR   char(020) ;              // - (O)
    ULIAR1   char(030) ;              // - (O) Libellé 1 article
    ULIAR2   char(030) ;              // - (O) Libellé 2 article
End-Pr;

Dcl-Ds VMRARM Qualified;
    CodeSociete   char(002) ;          // - (I) code société
    CodeRetour    char(001) ;          // - (O) code retour
    CodeArticle   char(020) ;          // - (I) code article
    LibelleDIR    char(020) ;          // - (O)
    Libelle1      char(030) ;          // - (O) Libellé 1 article
    Libelle2      char(030) ;          // - (O) Libellé 2 article
End-Ds;

// Exemple d'appel du programme :
// VMRARM.CodeSociete = EcranCodeSociete;
// VMRARM.CodeRetour = *BLANKS;
// VMRARM.CodeArticle = EcranLigneCodeArticle;
// VMRARM.LibelleDIR = *BLANKS;
// VMRARM.Libelle1 = *BLANKS;
// VMRARM.Libelle2 = *BLANKS;

// PR_VMRARM(
// VMRARM.CodeSociete
// :VMRARM.CodeRetour
// :VMRARM.CodeArticle
// :VMRARM.LibelleDIR
// :VMRARM.Libelle1
// :VMRARM.Libelle2
// );

/ENDIF
// !!!!!!   /!\ NECESSITE D INCLUDE LDA  /!\ !!!!!!!
/IF defined(PR_VAIOAF) 
// interrogation OA par recherche multi critères
// Prototype :
Dcl-Pr PR_VAIOAF     ExtPgm('VAIOAF');
    UCOVER   char(3);              // - (I) action : code verbe
    UCOOBJ   char(5);              // - (I) action : code objet
    ULIACT   char(30);              // - (I) action : libellé
    UCOPGP   char(8);              // - (O) code programme
    UCOREP   char(8);              // - (O) code retour
    UCOSTE   char(2);              // - (I) code société
    UCOETC   char(3);              //
    UCOETL   char(3);              //
    UCOFRC   char(9);              // - (I) action : code verbe
    UCORET   char(1);              // - (O) code retour
End-Pr;

// Data Structure :
Dcl-Ds VAIOAF Qualified;
    UCOVER   char(3);
    UCOOBJ   char(5);
    ULIACT   char(30);
    UCOPGP   char(8);
    UCOREP   char(8);
    UCOSTE   char(2);
    UCOETC   char(3);
    UCOETL   char(3);
    UCOFRC   char(9);
    UCORET   char(1);
End-Ds;

// Exemple d'appel dans le programme :
// If EZONCU = 'ENUMOA' ;
// LDA.ZONETOTALE = ' ' ;
// Out LDA ;
// VAIOAF.UCOVER = £CodeVerbe;
// VAIOAF.UCOOBJ = £CodeObjet;
// VAIOAF.ULIACT = £LibelleAction;
// VAIOAF.UCOPGP = *BLANKS;
// VAIOAF.UCOREP = *BLANKS;
// VAIOAF.UCOSTE = CodeSociete;
// VAIOAF.UCOETC = *BLANKS;
// VAIOAF.UCOETL = *BLANKS;
// VAIOAF.UCOFRC = *BLANKS;
// VAIOAF.UCORET = *BLANKS;
// PR_VAIOAF(
// VAIOAF.UCOVER
// :VAIOAF.UCOOBJ
// :VAIOAF.ULIACT
// :VAIOAF.UCOPGP
// :VAIOAF.UCOREP
// :VAIOAF.UCOSTE
// :VAIOAF.UCOETC
// :VAIOAF.UCOETL
// :VAIOAF.UCOFRC
// :VAIOAF.UCORET
// );
// If VAIOAF.UCORET <> '1';
// In LDA;
// EcranNumeroOA = %Subst(LDA.ZoneTotale: 1: 8);
// EndIf;
// EndIf;
/ENDIF







