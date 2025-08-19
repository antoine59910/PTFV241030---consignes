**free
Ctl-opt Option(*srcstmt:*nodebugio) AlwNull(*usrctl) UsrPrf(*owner)
        DatFmt(*iso) TimFmt(*hms) dftactgrp(*no)
        text('Programme de suivi des livraisons de consignes')
        bnddir('SRVPGM/UTILS':'SRVPGM/SERVICES');

// %Text('Programme de suivi des livraisons de consignes')
// Appel ligne de commande :
// CALL PGM(PTFV241030/KCOP10) PARM('GER' 'LIVCON' 'Gestion livraison consignes')

//
// --------------------------------------------------------------
//       NOM        : KCOP10              TYPE : Interactif
//
//  TITRE      : Suivi des articles consignés.: Gestion livraisons des consignes
//
//  FONCTIONS  :
//              Gestion des livraisons et retours des consignes chez les clients.
//              Appel du programme KCOP11 pour saisie de la livraison/retour des consignes
//              Le sous-fichier est chargé en fonction de la table KCOENT pour les entêtes des liv-
//              raisons
//
//              Touches de fonction :
//                      F2 : Utilisateur
//                      F3 : Fin
//                      F6 : Services
//                      F9 : Nouvelle livraison
//
//              Filtres disponibles :
//                      - Numéro de livraison
//                      - Numéro de facture
//                      - Tournée
//                      - Code client
//                      - Désignation client (Filtre type "Contient")
//                      - Date de livraison confirmée
//              Option "Masquer les retours traités" (activée par défaut)
//              pour n'afficher que les livraisons sans retour
//
//              Actions possibles sur les livraisons :
//                      1 : Modifier une livraison
//                      2 : Visualiser une livraison
//                      3 : Créer un nouveau retour
//                      4 : Modifier un retour
//                      5 : Visualiser un retour
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
//  ECRIT DU   : 11/11/2024            PAR : ANg (Antilles Glaces)
//        AU   : 29/11/2024
//
// ---------------------------------------------------------------------

// Déclaration fichier

// --- Fichiers --------------------------------------------------------
Dcl-F KCOP10E  WorkStn
               SFile(GESTIONSFL:fichierDS.rang_sfl)//SFILE(Format:rang)
               InfDS(fichierDS)//Permet d'avoir des informations sur le sous-fichier en cours
               IndDs(Indicateur)
               Alias;//pour mettre les indicateurs dans une DS et les nommer
// Variables :
// Variables du format GESTIONBAS
// ECRAN2MESSAGEERREUR char(30);           // Message d'erreur affiché à l'écran 2
// ECRAN2MESSAGEINFO char(40);             // Message d'information affiché à l'écran 2
// ECRANVERBEOBJET char(10);               // Verbe et objet de l'écran

// Variables du format GESTIONCTL
// ECRANLIGNESOUSFICHIER packed(4:0);      // Numéro de la ligne du sous-fichier
// ECRANLIBELLESOCIETE char(20);           // Libellé de la société
// ECRANLIBELLEACTION char(30);            // Libellé de l'action en cours
// ECRANNUMEROLIVRAISONFILTRE char(8); // Filtre sur le numéro de livraison
// ECRANNUMEROFACTUREFILTRE char(8);   // Filtre sur le numéro de facture
// ECRANNUMEROTOURNEEFILTRE char(2);       // Filtre sur le numéro de tournée
// ECRANCODECLIENTFILTRE packed(9:0);      // Filtre sur le code client
// ECRANDESIGNATIONCLIENTFILTRE char(20);  // Filtre sur la désignation du client
// ECRANDATELIVRAISONFILTRE date;          // Filtre sur la date de livraison
// ECRANLIVRAISSANSRETOURFILTRE char(1);   // Filtre pour masquer les livraisons sans retour

// Variables du format GESTIONSFL
// ECRANLIGNEACTION char(1);                // Option utilisateur sur la ligne
// ECRANLIGNENUMEROLIVRAISON packed(8:0);  // Numéro de livraison de la ligne
// ECRANLIGNEDESIGNATIONCLIENT char(30);   // Désignation du client de la ligne
// ECRANLIGNENUMEROFACTURE packed(8:0);    // Numéro de facture de la ligne
// ECRANLIGNECODETOURNEE packed(2:0);      // Code tournée de la ligne
// ECRANLIGNECODECLIENT packed(9:0);       // Code client de la ligne
// ECRANLIGNEDATELIVRAISON date;           // Date de livraison de la ligne

Dcl-Pr KCOP11 ExtPgm('KCOP11');
    £NumBLConsignes    Packed(8:0) Const; // Numéro du bon livraison de consignes
    £Operation          Char(30) Const;    // Type d'opération
    £Mode              Char(30) Const;     // Mode de fonctionnement
    // Numéro de la livraison (0 si création de retour sans livraison)
    £NumeroLivraison   Packed(8:0) Const; 
    // Code Client (pour création de retour sans livraison)
    £CodeClient   Char(9) Options(*NoPass) Const; 
End-Pr;
Dcl-Ds KCOP11_p qualified;
    NumBLConsignes   Packed(8:0); // Numéro du bon livraison de consignes
    Operation          Char(30);    // Type d'opération
    Mode              Char(30);     // Mode de fonctionnement
    NumeroLivraison    Packed(8:0); // Numéro de la livraison
    CodeClient         Char(9);
End-Ds;

Dcl-Pr GestionErreurSQL ind extproc('GESTIONERREURSQL');
    p_codeSQL int(10) const;
    p_messageContexte char(50) const options(*NoPass);
End-Pr;

Dcl-Pr RechercheMulticriteresClient char(9) extproc('RECHERCHEMULTICRITERESCLIENT');
    p_CodeSociete char(2);
    p_CodeClient char(9) options(*nopass);
End-Pr;

Dcl-Pr AffichageFenetreUtilisateur extproc('AFFICHAGEFENETREUTILISATEUR');
    p_codeVerbe char(3);
    p_codeObjet char(5);
End-Pr;

Dcl-Pr AffichageFenetreServices extproc('AFFICHAGEFENETRESERVICES');
End-Pr;

Dcl-Pr GetCodeSociete char(20) extproc('GETCODESOCIETE');
End-Pr;

Dcl-Pr GetLibelleSociete char(26) extproc('GETLIBELLESOCIETE');
End-Pr;

// --- Variables -------------------------------------------------------
Dcl-S NombreTotalLignesSF Packed(4:0);
Dcl-S Fin ind;
Dcl-S Refresh ind;
Dcl-S utilisateurBloquant char(10);
Dcl-S CodeActionVerrouillage char(1);
Dcl-S CodeSociete char(2);

// --- Constantes -------------------------------------------------------
Dcl-C LIVRAISON 'LIVRAISON';
Dcl-C RETOUR 'RETOUR';
Dcl-C CREATION 'CREATION';
Dcl-C MODIFICATION 'MODIFICATION';
Dcl-C VISUALISATION 'VISUALISATION';
Dcl-C CODE_ACTION_CREATION_LIVRAISON 'C';
Dcl-C CODE_ACTION_MODIFIER_LIVRAISON 'L';
Dcl-C CODE_ACTION_RETOUR 'R';
Dcl-C CODE_ACTION_VISUALISER 'V';
Dcl-C TABVV_PARAMETRESCONSIGNE 'XCOPAR';

// --- Tables -------------------------------------------------------
// Tables des entêtes de livraisons
Dcl-Ds KCOENT_t extname('KCOENT') qualified template alias;
End-Ds;
// Tables des blocages des accès utilisateurs des livraisons
Dcl-Ds KCOF10_t extname('KCOF10') qualified template alias;
End-Ds;

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

// --- Data-structures Indicateurs--------------------------------------
Dcl-Ds Indicateur qualified;
    SousFichierDisplay                          Ind Pos(51);
    SousFichierDisplayControl                   Ind Pos(52);
    SousFichierClear                            Ind Pos(53);
    SousFichierEnd                              Ind Pos(54);
    SousFichierCouleurBleu                      Ind Pos(70);

    // Indicateurs d affichage
    MasquerMessageErreur                        Ind Pos(82);
    MasquerMessageInfo                          Ind Pos(83);
    MasquerMessageErreurWindow                  Ind Pos(84);  

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
Dcl-Pi *N;
    // entrées
    £CodeVerbe                                   Char(4);
    £CodeObjet                                   Char(6);
    £LibelleAction                               Char(30);
End-Pi ;

// Initialisation SQL :
Exec Sql
     Set Option Commit = *None;

// Initialisation du programme
InitialisationProgramme();

// Chargement initial du sous-fichier
ChargerSousFichier();

Fin = *Off;
Dow not Fin;

    // Affichage de l écran avec attente de saisie
    Write GESTIONBAS;
    ExFmt GESTIONCTL;

    // Traitement des actions
    Select;
        When fichierDS.TouchePresse = F2;
            AffichageFenetreUtilisateur(£CodeVerbe:£CodeObjet);

        When fichierDS.TouchePresse = F3;
            Fin=*On;

        When fichierDS.TouchePresse = F6;
            AffichageFenetreServices();

            // Nouvelle création de livraison
        When fichierDS.touchePresse = F9;
            CreationLivraison();
            Refresh = *On;
        
            // Nouvelle création de retour
        When fichierDS.touchePresse = F10;
            CreationRetour();
            Refresh = *On;

        When fichierDS.TouchePresse = F12;
            Fin=*On;

        When  fichierDS.touchePresse = ENTREE;
            // Réinitialisation des message d'erreur et info
            Indicateur.MasquerMessageErreur = *On;
            Indicateur.MasquerMessageInfo = *On;
            Indicateur.MasquerMessageErreurWindow = *On;

            If Verification();
                If KCOP11_p.NumBLConsignes <> 0;
                    VerrouillageLivraison(KCOP11_p.NumBLConsignes:CodeActionVerrouillage);
                    Monitor;
                        KCOP11(KCOP11_p.NumBLConsignes
                            :KCOP11_p.Operation
                            :KCOP11_p.Mode
                            :KCOP11_p.NumeroLivraison);
                        DeverrouillageLivraison(KCOP11_p.NumBLConsignes);
                    On-Error;
                        dsply 'Erreur pendant execution de KCOP11';
                        DeverrouillageLivraison(KCOP11_p.NumBLConsignes);
                    Endmon;

                Endif;
            Endif;
            Refresh = *On;

        Other;
    Endsl;

    // Si rafraîchissement nécessaire, rechargement du sous-fichier
    If Refresh;
        ChargerSousFichier();
        Refresh = *Off;
    Endif;
    
Enddo;

*inlr=*on;

// ----------------------------------------------------------------------------
//
//                                  PROCEDURES
//
// ----------------------------------------------------------------------------

///
// InitialisationProgramme()
// - Purge du fichier des blocages pour les blocages antérieurs à la veille
// - Initialisation des variables de l'écran
///
Dcl-Proc InitialisationProgramme;
    Dcl-Pi *N;
    End-Pi;
    
    // 1. Purge du fichier des blocages
    // On supprime toutes les restrictions qui sont antiérieurs à la veille
    Exec SQL
                DELETE FROM KCOF10 WHERE StartTimestamp < CURRENT_DATE - 1 DAY;
    GestionErreurSQL(sqlcode:'Purge fichier blocages');

    // 2. Initialisation de l écran 
    // Masquage des messages
    Indicateur.MasquerMessageErreur = *On;
    Indicateur.MasquerMessageInfo = *On;
    Indicateur.MasquerMessageErreurWindow = *On;
    EcranLibelleSociete = GetLibelleSociete();
    EcranLibelleAction = £LibelleAction;
    EcranVerbeObjet = £CodeVerbe + £CodeObjet;
    EcranLivraisSansRetourFiltre = 'X';
    // Indicateur de fin du sous fichier (gestionSFL)
    Indicateur.SousFichierEnd = *On;
    // Indicateur d'affichage du displayControl du sous fichier (gestionCTL)
    Indicateur.SousFichierDisplayControl = *On; 

    ECRANNUMEROLIVRAISONFILTRE = 0;
    ECRANNUMEROFACTUREFILTRE = 0;
    ECRANNUMEROTOURNEEFILTRE = *BLANKS;
    ECRANCODECLIENTFILTRE = *BLANKS;
    ECRANDATELIVRAISONFILTRE = %DATE('1940-01-01');// Attention surtout pas mettre *LOVAL 
    // Sinon bug dans la requete SQL car il compare avec la date '0001-01-01' qui n'existe pas en SQL
    ECRANNUMEROBLCONSIGNES = 0;
    ECRANDESIGNATIONCLIENTFILTRE = *BLANKS;

    // 3 . Récupération du code société
    CodeSociete = GetCodeSociete();
End-Proc;

///
// ChargerSousFichier()
// Charge le sous-fichier avec les données de KCOENT, VENTLV et CLIENT
// Recherche num VENTLV
// Initialise les positions d affichage et le curseur
///
Dcl-Proc ChargerSousFichier;
    Dcl-Pi *n ;
    End-Pi;

    // Variable pour stocker le statut de retour
    Dcl-S RetourEffectue Char(1);

    // Nettoyage du sous-fichier
    Indicateur.SousFichierClear = *On;
    Write GESTIONCTL;
    Indicateur.SousFichierClear = *Off;

    // Initialisation du rang
    fichierDS.rang_sfl = 0;

    // Initialisation indicateur de fin
    Indicateur.SousFichierEnd = *Off;

    // Préparation du curseur
    Exec SQL
        DECLARE C1 CURSOR FOR
        SELECT 
            NumeroBLConsignes,
            NumeroLivraison,
            TopRetour,
            NumeroFacture,
            CodeTournee,
            CodeClient,
            DesignationClient,
            DateLivraison
        FROM KCOENT
        WHERE DesignationClient LIKE '%' || TRIM(:ECRANDESIGNATIONCLIENTFILTRE) || '%'
        AND (:ECRANNUMEROBLCONSIGNES = 0 OR NumeroBLConsignes = :ECRANNUMEROBLCONSIGNES)
        AND (:ECRANNUMEROLIVRAISONFILTRE = 0 OR NumeroLivraison = :ECRANNUMEROLIVRAISONFILTRE)
        AND (:ECRANNUMEROFACTUREFILTRE = 0 OR NumeroFacture = :ECRANNUMEROFACTUREFILTRE)
        AND (:ECRANNUMEROTOURNEEFILTRE = '' OR CodeTournee LIKE :ECRANNUMEROTOURNEEFILTRE)
        AND (:ECRANCODECLIENTFILTRE = '' OR CodeClient LIKE :ECRANCODECLIENTFILTRE)
        AND (:ECRANLIVRAISSANSRETOURFILTRE <> 'X' OR TopRetour <> 'O')
        And (:ECRANDATELIVRAISONFILTRE = Date('1940-01-01') 
        OR :EcranDateLivraisonFiltre = DateLivraison)
       ORDER BY NumeroBLConsignes desc, DateLivraison DESC, CodeTournee, CodeClient;
    GestionErreurSQL(sqlcode);

    // Ouverture du curseur
    exec sql OPEN C1;
    GestionErreurSQL(sqlcode);

    // Premier FETCH
    Exec SQL FETCH FROM C1 INTO 
            :ECRANLIGNENUMEROBLCONSIGNE,
            :ECRANLIGNENUMEROLIVRAISON,
            :RetourEffectue,
            :ECRANLIGNENUMEROFACTURE,
            :ECRANLIGNECODETOURNEE,
            :ECRANLIGNECODECLIENT,
            :ECRANLIGNEDESIGNATIONCLIENT,
            :ECRANLIGNEDATELIVRAISON;
    GestionErreurSQL(sqlcode);

    If SQLCode = 100; //Aucun enregistrement n a été trouvé
        ECRANMESSAGEERREUR = 'Aucune livraison trouvée';
        Indicateur.MasquerMessageErreur = *Off;
        
    Elseif SQLCode = 0;// Des enregistrements ont été trouvés
        Dow SQLCode = 0;
            // Incrémentation du rang
            fichierDS.rang_sfl += 1;

            // Initialisation ligne action
            ECRANLIGNEACTION = ' ';

            // Activation de l'indicateur pour changer la couleur si retour effectué
            If RetourEffectue = 'O';
                Indicateur.SousFichierCouleurBleu = *On; 
            Else;
                Indicateur.SousFichierCouleurBleu = *Off; 
            Endif;

            // Écriture dans le sous-fichier  
            Write GESTIONSFL;

            // Lecture suivante
            Exec SQL FETCH FROM C1 INTO 
                    :ECRANLIGNENUMEROBLCONSIGNE,
                    :ECRANLIGNENUMEROLIVRAISON,
                    :RetourEffectue,
                    :ECRANLIGNENUMEROFACTURE,
                    :ECRANLIGNECODETOURNEE,
                    :ECRANLIGNECODECLIENT,
                    :ECRANLIGNEDESIGNATIONCLIENT,
                    :ECRANLIGNEDATELIVRAISON;
            GestionErreurSQL(sqlcode);
        Enddo;

    Else;//Erreur requete
        GestionErreurSQL(sqlcode);
    Endif;
    // Fermeture du curseur
    exec sql CLOSE C1;
    GestionErreurSQL(sqlcode);

    // Mémorisation du nombre total de lignes
    NombreTotalLignesSF = fichierDS.rang_sfl;
    
    // GESTION DE L'AFFICHAGE ET DE "FIN"
    If NombreTotalLignesSF > 0;
        // Il y a des données à afficher
        Indicateur.SousFichierDisplay = *On;
        Indicateur.SousFichierDisplayControl = *On;
        
        // SFLEND : Détermine si on affiche "FIN" ou "MORE"
        // Si toutes les données tiennent sur l'écran, on affiche "FIN"
        If NombreTotalLignesSF <= 13;
            Indicateur.SousFichierEnd = *On;  // Affiche "FIN"
        Else;
            Indicateur.SousFichierEnd = *Off; // Affiche "MORE"
        Endif;
        
    Else;
        // Pas de données : pas d'affichage du sous-fichier
        // on ne doit PAS activer l affichage du sous-fichier s il est vide 
        Indicateur.SousFichierDisplay = *Off;
        Indicateur.SousFichierDisplayControl = *On;
        Indicateur.SousFichierEnd = *Off;
    Endif;

    // Positionnement initial
    EcranLigneSousFichier = 1;
    EcranDeplacerCurseurLigne = 8;
    EcranDeplacerCurseurColonne = 2;  
End-Proc;

///
// Vérification des saisies et sauvegarde de l action de l utilisateur
// Vérifications :
//  - On vérifie qu il n y a pas plusieurs actions choisies en même temps
//  - On vérifie qu'un autre utilisateur n'utilise pas déjà une livraison
//  - On sauvegarde l action choisie pour l envoyer au programme KCOP11
//
// @return *On si OK, *Off si KO
///

Dcl-Proc Verification;
    Dcl-Pi *n Ind;
    End-Pi;

    Dcl-S i Zoned(4:0);
    Dcl-S Rang Zoned(2:0);
    Dcl-S SauvegardeAction Char(1);
    Dcl-S VerificationReturn Ind Inz(*On);
    Dcl-S retourDejaEffectue Char(1);

    // Initialisations
    Indicateur.MasquerMessageErreur = *On;
    Indicateur.MasquerMessageInfo = *On;
    Indicateur.MasquerMessageErreurWindow = *On;
    SauvegardeAction = *BLANKS;
    KCOP11_p.Operation = *BLANKS;
    KCOP11_p.Mode = *BLANKS;
    KCOP11_p.NumBLConsignes = 0;
    KCOP11_p.NumeroLivraison = 0;

    Rang = 1;
    For i = 1 to NombreTotalLignesSF;
        Chain i GESTIONSFL;
    
        // Vérifications
        If ECRANLIGNEACTION <> *BLANKS;
            // Vérification qu il n y ait pas plusieurs actions
            If VerificationReturn = *On And SauvegardeAction <> *BLANKS;
                EcranMessageErreur = 'Une seule action à la fois';
                Indicateur.MasquerMessageErreur = *Off;
                VerificationReturn = *Off;
            Endif;

            // Vérification du blocage des livraisons
            If VerificationReturn = *On 
            and ECRANLIGNEACTION <> CODE_ACTION_VISUALISER;
                utilisateurBloquant = VerificationBlocage(ECRANLIGNENUMEROLIVRAISON);
                If (utilisateurBloquant <> *BLANKS);
                    VerificationReturn = *Off;
                    ECRANMESSAGEERREUR='LIV:' 
                    + %EDITC(ECRANLIGNENUMEROLIVRAISON:'Z') 
                    + ' bloq par ' + utilisateurBloquant;
                    Indicateur.MasquerMessageErreur = *Off;
                Else;

                Endif;
            Endif;

            // Gestion de l'action
            If VerificationReturn = *On;
                KCOP11_p.NumBLConsignes = ECRANLIGNENUMEROBLCONSIGNE;
                
                Select;
                    When ECRANLIGNEACTION = CODE_ACTION_MODIFIER_LIVRAISON;
                        // On vérifie qu'un retour n'a pas déjà été saisi
                        Exec SQL
                            SELECT TopRetour, NumeroLivraison
                            INTO :retourDejaEffectue, :KCOP11_p.NumeroLivraison
                            FROM KCOENT
                            WHERE NumeroBLConsignes = :ECRANLIGNENUMEROBLCONSIGNE;
                        If SQLCode = 0 and retourDejaEffectue= 'N';
                            KCOP11_p.Operation = LIVRAISON;
                            KCOP11_p.Mode = MODIFICATION;
                            CodeActionVerrouillage = CODE_ACTION_MODIFIER_LIVRAISON;
                        Elseif SQLCode = 0 and retourDejaEffectue= 'O';
                            EcranMessageErreur = 'ERREUR: Retour déjà saisi'; 
                            EcranMessageInfo = ' Modification livraison impossible'; 
                            Indicateur.MasquerMessageErreur = *Off;
                            Indicateur.MasquerMessageInfo = *Off;
                            VerificationReturn = *Off;
                        Else;
                            GestionErreurSQL(sqlcode);
                            EcranMessageErreur = 'Erreur SQL vérif Retour'; 
                            Indicateur.MasquerMessageErreur = *Off;
                            VerificationReturn = *Off;
                        Endif;


                    When ECRANLIGNEACTION = CODE_ACTION_RETOUR;
                        KCOP11_p.Operation = RETOUR;
                        // On vérifie si un retour existe déjà
                        // S'il n'existe pas, 
                        // Mode = création, S'il existe Mode = modification
                        Exec SQL
                            SELECT TopRetour, NumeroLivraison 
                            INTO :retourDejaEffectue, :KCOP11_p.NumeroLivraison
                            FROM KCOENT
                            WHERE NumeroBLConsignes = :ECRANLIGNENUMEROBLCONSIGNE;
                        If SQLCode = 0 and retourDejaEffectue= 'N';
                            KCOP11_p.Mode = CREATION;
                            CodeActionVerrouillage = CODE_ACTION_RETOUR;
                        Elseif SQLCode = 0 and retourDejaEffectue= 'O';
                            KCOP11_p.Mode = MODIFICATION;
                            CodeActionVerrouillage = CODE_ACTION_RETOUR;
                        Else;
                            GestionErreurSQL(sqlcode);
                            EcranMessageErreur = 'Erreur SQL vérif Retour'; 
                            Indicateur.MasquerMessageErreur = *Off;
                            VerificationReturn = *Off;
                        Endif;

                    When ECRANLIGNEACTION = CODE_ACTION_VISUALISER;
                        KCOP11_p.Operation = RETOUR;
                        KCOP11_p.Mode = VISUALISATION;
                        CodeActionVerrouillage = CODE_ACTION_VISUALISER;

                    Other;
                        EcranMessageErreur = 'Choix action inconnu';
                        Indicateur.MasquerMessageErreur = *Off;
                        VerificationReturn = *Off;

                Endsl;

            Endif;
            Rang = Rang + 1;
            SauvegardeAction = ECRANLIGNEACTION;

        Endif;
    Endfor;

    Return VerificationReturn;

End-Proc;

///
// VerificationBlocage
// Permet de vérifier si un utilisateur utilise déjà la livraison en création/modification
// @param numero de Livraison 
// @return Utilisateur qui bloque la livraison (BLANKS si rien)
///
Dcl-Proc VerificationBlocage;
    Dcl-Pi *n char(10);
        p_numeroBLConsignes packed(8:0);
    End-Pi;

    Dcl-S r_userBlocage char(10) Inz(*Blanks);

    // Vérification si la livraison n est pas déjà en cours d utilisation
    Exec SQL
        Select Utilisateur
        Into :r_userBlocage
        From KCOF10
        Where NumeroBLConsignes = :p_numeroBLConsignes 
                And LockFlag = '1';
    If (SqlCode = 100); // Pas de résultat trouvé
        r_userBlocage = *BLANKS; // La livraison nest pas verrouillée
    Elseif (SqlCode = 0); // Résultat trouvé

    Else;//Erreur SQL
        GestionErreurSQL(sqlcode);
    Endif;

    Return r_userBlocage;
  
End-Proc;

///
// VerrouillageLivraison
// Ecrit dans la table KCOF10 pour le verrouillage de la livraison
// On vérifie si le couple NumeroLivraisonConsignes/Utilisateur existe déjà, 
// s il existe c est un update
// Sinon c est un insert INTO
// @Param NumeroLivraison
// @Param CodeAction
///
Dcl-Proc VerrouillageLivraison;
    Dcl-Pi *n ;
        p_numeroBLConsignes packed(8:0);
        PARAM_CodeAction Char(1);
    End-Pi;

    Dcl-Ds KCOF10Ds likeDs(KCOF10_t);

    Dcl-S EnregistrementExistant Packed(1:0);

    KCOF10Ds.NumeroBLConsignes = p_numeroBLConsignes;
    KCOF10Ds.Utilisateur = psds.user;
    KCOF10Ds.StartTimestamp = %Timestamp();
    KCOF10Ds.CodeAction = PARAM_CodeAction;
    KCOF10Ds.LockFlag = '1';

    Exec SQL
        SELECT COUNT(*)
        INTO :EnregistrementExistant
        FROM KCOF10
        WHERE NumeroBLConsignes = :KCOF10Ds.NumeroBLConsignes 
        AND Utilisateur = :KCOF10Ds.Utilisateur;

    If (EnregistrementExistant = 0);
        // Insertion dans la table
        Exec SQL
            INSERT INTO KCOF10
            (
                NumeroBLConsignes,
                Utilisateur,
                StartTimeStamp,
                CodeAction,
                LockFlag
            )
            VALUES
            (
                :KCOF10Ds.NumeroBLConsignes,
                :KCOF10Ds.Utilisateur,
                :KCOF10Ds.StartTimestamp,
                :KCOF10Ds.CodeAction,
                :KCOF10Ds.LockFlag
            );
        GestionErreurSQL(sqlcode);
    Else;
        Exec SQL
            UPDATE KCOF10
            SET StartTimeStamp = :KCOF10Ds.StartTimestamp,
                EndTimeStamp = null,
                LockFlag = :KCOF10Ds.LockFlag
            WHERE NumeroBLConsignes = :KCOF10Ds.NumeroBLConsignes 
            AND Utilisateur = :KCOF10Ds.Utilisateur;
        GestionErreurSQL(sqlcode);
    Endif;
End-Proc;

///
// DeverrouillageLivraison
// Met à jour le EndTimeStamp dans la table KCOF10 pour déverrouiller la livraison
// @Param NumeroLivraison
///
Dcl-Proc DeverrouillageLivraison;
    Dcl-Pi *n ;
        p_numeroBLConsignes packed(8:0);
    End-Pi;

    Exec SQL
        UPDATE KCOF10
        SET EndTimeStamp = CURRENT TIMESTAMP,
            LockFlag = '0'
        WHERE NumeroBLConsignes = :p_numeroBLConsignes
        AND Utilisateur = :psds.user
        AND EndTimeStamp IS NULL;
    
    GestionErreurSQL(sqlcode);
End-Proc;


///
// CreationLivraison
//
///
Dcl-Proc CreationLivraison ;
    Dcl-Pi *n ;
    End-Pi;

    Dcl-S finSaisieCreation Ind Inz(*Off);

    // Initialisation du numéro de livraison
    EcranCreationLivraisonNumero = 0;

    // Affichage fenetre création d une nouvelle livraison
    finSaisieCreation = *Off;
    Dow not finSaisieCreation;
        EXFMT ECREAT;
        Select;
            When fichierDS.touchePresse = F12;
                finSaisieCreation = *On;

            When fichierDS.touchePresse = ENTREE;
                If VerificationCreation(EcranCreationLivraisonNumero);
                            
                    // Si vérification OK : Appel du programme de saisie KCOP11
                    KCOP11_p.NumBLConsignes = 
                                %dec(%trim(ParametresConsigne.CompteurBLConsignes):8:0) + 1;
                    CodeActionVerrouillage = CODE_ACTION_CREATION_LIVRAISON;
                    VerrouillageLivraison(KCOP11_p.NumBLConsignes
                                                :CodeActionVerrouillage);
                    Monitor;
                        KCOP11(KCOP11_p.NumBLConsignes
                                :LIVRAISON
                                :CREATION
                                :EcranCreationLivraisonNumero);

                    On-Error ;
                        dsply 'Erreur pendant execution de KCOP11';
                        DeverrouillageLivraison(KCOP11_p.NumBLConsignes);
                    Endmon;

                    DeverrouillageLivraison(KCOP11_p.NumBLConsignes);
                    finSaisieCreation = *On;
                Endif;

            Other;
        Endsl;
    Enddo;
End-Proc;

///
// VerificationCreation
// Vérifie les conditions nécessaires pour la création d une nouvelle livraison 
//  1 - On vérifie que la livraison existe dans VENTLV
//  2 - On vérifie que la livraison n existe pas déjà dans KCOENT
//  3 - On vérifie que quelqu'un n'est pas entrain de créer en même temps
// @param p_NumeroLivraisonCreation - Numéro de la livraison à vérifier
// @return *On si la création est possible, *Off si elle ne peut pas être effectuée
///
Dcl-Proc VerificationCreation;
    Dcl-Pi *n Ind;
        p_NumeroLivraisonCreation Packed(8:0);
    End-Pi;

    Dcl-S Erreur Ind Inz(*Off);
    Dcl-S Compteur Packed(10:0);
    Dcl-S NumeroCreationBLConsignes packed(8:0);
    
    Indicateur.MasquerMessageErreurWindow = *On;

    // 1 - On vérifie que la livraison existe dans VENTLV
    If not Erreur;
        Exec SQL
            select COUNT(ENULIV)
            Into :Compteur
            FROM VENTLV
            Where ENULIV = :p_NumeroLivraisonCreation;
        GestionErreurSQL(sqlcode);
        If Compteur = 0;
            Erreur = *On;
            WINDOWMESSAGEERREUR='LIV : ' 
            + %EDITC(p_NumeroLivraisonCreation:'Z') 
            + ' inexistante';
            Indicateur.MasquerMessageErreurWindow = *Off;
        Endif;
    Endif;

    // 2 - On vérifie que la livraison n existe pas déjà dans KCOENT
    If not Erreur;
        Exec SQL
            select COUNT(NumeroLivraison)
            Into :Compteur
            FROM KCOENT
            Where NumeroLivraison = :p_NumeroLivraisonCreation;
        GestionErreurSQL(sqlcode);
        If Compteur > 0;
            Erreur = *On;
            WINDOWMESSAGEERREUR='LIV : ' 
            + %EDITC(p_NumeroLivraisonCreation:'Z') 
            + ' déjà créée';
            Indicateur.MasquerMessageErreurWindow = *Off;
        Endif;
    Endif;

    // 3 - On vérifie que quelqu'un n'est pas entrain de créer en même temps
    If not Erreur;
        // Récupération des paramètres consignes : 
        Exec SQL
            Select XLIPAR
            Into :ParametresConsigne.XLIPAR
            FROM VPARAM
            Where XCORAC = :TABVV_PARAMETRESCONSIGNE;
        GestionErreurSQL(sqlcode);

        // On vérifie qu'un utilisateur n'est pas en création
        NumeroCreationBLConsignes = %dec(%trim(ParametresConsigne.CompteurBLConsignes):8:0) + 1;

        utilisateurBloquant = VerificationBlocage(NumeroCreationBLConsignes);
        If (utilisateurBloquant <> *BLANKS);
            Erreur = *On;
            WINDOWMESSAGEERREUR='bloqué par ' + utilisateurBloquant;
            Indicateur.MasquerMessageErreurWindow = *Off;
        Endif;
    Endif;

    Return not Erreur;
End-Proc;

///
// Creation Retour
// Permet la création d'un retour de livraison sans avoir fait de livraison
///
Dcl-Proc CreationRetour;
    Dcl-Pi *n ;
    End-Pi;

    Dcl-S finSaisie ind Inz(*Off);

    WindowCodeClient = *BLANKS;
    WindowDateRetour = *LOVAL;
    Indicateur.MasquerMessageErreurWindow = *On;
    
    Dow not finSaisie;
        EXFMT ECREAR;
        Select;
            When fichierDS.touchePresse = F12;
                finSaisie = *On;

            When fichierDS.touchePresse = ENTREE;
                If VerificationCreationRetour(WindowCodeClient : WindowDateRetour);
                    // Si vérification OK : Création du BL de consignes
                    KCOP11_p.NumBLConsignes = 
                            %dec(%trim(ParametresConsigne.CompteurBLConsignes):8:0) + 1;
                    
                    // Verrouillage de la livraison
                    CodeActionVerrouillage = CODE_ACTION_RETOUR;
                    VerrouillageLivraison(KCOP11_p.NumBLConsignes
                                        : CodeActionVerrouillage);
                    // Appel du programme de saisie KCOP11 pour un retour sans livraison
                    Monitor;
                        KCOP11(KCOP11_p.NumBLConsignes
                                : RETOUR
                                : CREATION
                                : 0
                                : WindowCodeClient);
                        DeverrouillageLivraison(KCOP11_p.NumBLConsignes);
                    On-Error;
                        dsply 'Erreur pendant execution de KCOP11';
                        DeverrouillageLivraison(KCOP11_p.NumBLConsignes);
                    Endmon;

                    // Fin 
                    finSaisie = *On;
                Endif;
            
            When fichierDS.touchePresse = F4;
                Select;
                    When (ECREARZoneCurseur = 'ECRRET');
                        WindowCodeClient =  
                                    RechercheMulticriteresClient(CodeSociete:WindowCodeClient);
                    Other;
                Endsl;

            Other;
        Endsl;
    Enddo;
End-Proc;

///
// VerificationCreationRetour
// Vérifie que les informations entrées dans l'écran de création retour sont correctes
// - Le code client doit exister
// - Il ne doit pas y avoir de création en cours
// - La date doit être inférieure ou égale à la date du jour
// - La date ne doit pas être la date par défaut (*LOVAL)
//
// @param p_CodeClient - Code du client à vérifier
// @param p_DateRetour - Date du retour à vérifier
//
// @return *On si la création est possible, *Off sinon
///
Dcl-Proc VerificationCreationRetour;
    Dcl-Pi *n Ind;
        p_CodeClient Char(9);
        p_DateRetour Date;
    End-Pi;

    Dcl-S Erreur Ind Inz(*Off);
    Dcl-S Compteur Packed(10:0);
    Dcl-S NumeroCreationBLConsignes packed(8:0);
    Dcl-S DateJour Date;
    
    // Masquage des messages d'erreur précédents
    Indicateur.MasquerMessageErreurWindow = *On;

    // 1 - Vérification que le code client existe
    If not Erreur and p_CodeClient <> *Blanks;
        Exec SQL
            SELECT COUNT(*)
            INTO :Compteur
            FROM CLIENT
            WHERE CCOCLI = :p_CodeClient;
        GestionErreurSQL(sqlcode);
        
        If Compteur = 0;
            Erreur = *On;
            WINDOWMESSAGEERREUR = 'Client ' + %Trim(p_CodeClient) + ' inexistant';
            Indicateur.MasquerMessageErreurWindow = *Off;
        Endif;
    Elseif not Erreur and p_CodeClient = *Blanks;
        Erreur = *On;
        WINDOWMESSAGEERREUR = 'Code client obligatoire';
        Indicateur.MasquerMessageErreurWindow = *Off;
    Endif;
    
    // 2 - Vérification de la date
    If not Erreur;
        // La date doit être renseignée (pas la date par défaut)
        If p_DateRetour = *Loval;
            Erreur = *On;
            WINDOWMESSAGEERREUR = 'Date retour obligatoire';
            Indicateur.MasquerMessageErreurWindow = *Off;
        Else;
            // La date ne doit pas être postérieure à la date du jour
            DateJour = %Date();
            If p_DateRetour > DateJour;
                Erreur = *On;
                WINDOWMESSAGEERREUR = 'Date retour > date du jour';
                Indicateur.MasquerMessageErreurWindow = *Off;
            Endif;
        Endif;
    Endif;
    
    // 3 - Vérification qu'il n'y a pas une création en cours
    If not Erreur;
        // Récupération des paramètres consignes
        Exec SQL
            SELECT XLIPAR
            INTO :ParametresConsigne.XLIPAR
            FROM VPARAM
            WHERE XCORAC = :TABVV_PARAMETRESCONSIGNE;
        GestionErreurSQL(sqlcode);
        
        // Vérification qu'un utilisateur n'est pas en création
        NumeroCreationBLConsignes = %dec(%trim(ParametresConsigne.CompteurBLConsignes):8:0) + 1;
        
        utilisateurBloquant = VerificationBlocage(NumeroCreationBLConsignes);
        If (utilisateurBloquant <> *BLANKS);
            Erreur = *On;
            WINDOWMESSAGEERREUR = 'Bloqué par ' + utilisateurBloquant;
            Indicateur.MasquerMessageErreurWindow = *Off;
        Endif;
    Endif;
    
    Return not Erreur;
End-Proc;