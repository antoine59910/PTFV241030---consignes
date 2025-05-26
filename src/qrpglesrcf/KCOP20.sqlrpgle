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

/INCLUDE qincsrc,prototypes

/UNDEFINE PR_GOAFENCL
/UNDEFINE PR_GOASER
/UNDEFINE PR_VORPAR
/UNDEFINE PR_VMRCLM
/UNDEFINE PR_VMRICL

// --- Variables -------------------------------------------------------
Dcl-S NombreTotalLignesSF Packed(4:0);
Dcl-S Fin ind;
Dcl-S FinFenetre ind;
Dcl-S Refresh ind;
Dcl-S EcranActuel char(10);
Dcl-S CodeSociete char(2);
Dcl-S NumeroInventaire Packed(10:0);

// Statistiques inventaire (stockées en interne seulement)
Dcl-S NbTotalArticles Packed(3:0);
Dcl-S NbEcartsPositifs Packed(3:0);
Dcl-S NbEcartsNegatifs Packed(3:0);

// Variable pour stocker l'écart calculé
Dcl-S EcartCalcule Packed(4:0);

// --- Constantes -------------------------------------------------------
Dcl-C ECRAN_SELECTION 'SELECT';
Dcl-C ECRAN_INVENTAIRE 'INVENTAIRE';
Dcl-C TABVV_PARAMETRESCONSIGNE 'XCOPAR';

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
    
    // Initialisation des variables
    Fin = *Off;
    Refresh = *Off;
    
    // Récupération du code société par défaut
    CodeSociete = GetCodeSociete();
    
    // Initialisation de l'écran
    Indicateur.MasquerMessageErreur = *On;
    Indicateur.MasquerMessageInfo = *On;
    EcranLibelleSociete = GetLibelleSociete();
    EcranLibelleAction = £LibelleAction;
    EcranVerbeObjet = £CodeVerbe + £CodeObjet;
    
    // Initialisation écran sélection
    EcranCodeSociete = CodeSociete;
    EcranLibelleSocieteSelect = GetLibelleSociete();
    EcranCodeClient = *Blanks;
    EcranClientLibelle = *Blanks;
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
                // Charger les données et passer à l'écran d'inventaire
                ChargerSousFichier();
                EcranActuel = ECRAN_INVENTAIRE;
                Indicateur.MasquerEcranSelection = *On;
            EndIf;
            
        Other;
    EndSl;
End-Proc;

///
// GestionEcranInventaire()
// Gère l'écran d'inventaire avec le sous-fichier
///
Dcl-Proc GestionEcranInventaire;
    Dcl-Pi *N;
    End-Pi;
    
    // Afficher le sous-fichier et masquer l'écran de sélection
    Indicateur.MasquerEcranSelection = *On;
    
    Write GESTIONBAS;
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
            Else;
                // Recalculer les statistiques internes
                CalculerStatistiques();
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
    If GestionErreurSQL() Or Compteur = 0;
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
    If GestionErreurSQL() Or Compteur = 0;
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
    
    // Vérification qu'il existe des consignes pour ce client
    Exec SQL
        SELECT COUNT(*)
        INTO :Compteur
        FROM KCOCUM
        WHERE CodeClient = :EcranCodeClient;
    If GestionErreurSQL();
        EcranMessageErreur = 'Erreur accès données consignes';
        Indicateur.MasquerMessageErreur = *Off;
        Return *Off;
    EndIf;
    
    If Compteur = 0;
        EcranMessageErreur = 'Aucune consigne trouvée pour ce client';
        Indicateur.MasquerMessageErreur = *Off;
        Return *Off;
    EndIf;
    
    // Mise à jour des données
    CodeSociete = EcranCodeSociete;
    
    Return *On;
End-Proc;

///
// ChargerSousFichier()
// Charge le sous-fichier avec les données des consignes du client
///
Dcl-Proc ChargerSousFichier;
    Dcl-Pi *N;
    End-Pi;
    
    // Nettoyage du sous-fichier
    Indicateur.SousFichierClear = *On;
    Write GESTIONCTL;
    Indicateur.SousFichierClear = *Off;
    
    // Initialisation
    fichierDS.rang_sfl = 0;
    Indicateur.SousFichierEnd = *Off;
    
    // Récupération des libellés client
    VMRICL.UCOSTE = CodeSociete;
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
    
    // Déclaration du curseur pour les consignes du client
    Exec SQL
        DECLARE C_INVENTAIRE CURSOR FOR
        SELECT K.CodeArticle,
               A.ALIAR1 as LibelleArticle,
               K.QuantiteTheoriqueStock
        FROM KCOCUM K
        LEFT JOIN VARTIC A ON A.ACOART = K.CodeArticle
        WHERE K.CodeClient = :EcranCodeClient
        AND K.QuantiteTheoriqueStock <> 0
        ORDER BY K.CodeArticle;
    
    If GestionErreurSQL();
        EcranMessageErreur = 'Erreur préparation données';
        Indicateur.MasquerMessageErreur = *Off;
        Return;
    EndIf;
    
    // Ouverture et lecture du curseur
    Exec SQL OPEN C_INVENTAIRE;
    If GestionErreurSQL();
        EcranMessageErreur = 'Erreur ouverture curseur';
        Indicateur.MasquerMessageErreur = *Off;
        Return;
    EndIf;
    
    Exec SQL FETCH FROM C_INVENTAIRE INTO 
            :EcranLigneCodeArticle,
            :EcranLigneLIbelle1Article,
            :EcranLigneQuantiteTheorie;
    
    If SQLCode = 100;
        EcranMessageErreur = 'Aucune consigne à inventorier';
        Indicateur.MasquerMessageErreur = *Off;
    ElseIf SQLCode = 0;
        DoW SQLCode = 0;
            fichierDS.rang_sfl += 1;
            
            // Initialisation des quantités
            EcranLigneQuantiteInventaire = 0;
            
            // Couleurs par défaut
            Indicateur.SousFichierCouleurBleu = *On;
            
            Write GESTIONSFL;
            
            Exec SQL FETCH FROM C_INVENTAIRE INTO 
                    :EcranLigneCodeArticle,
                    :EcranLigneLIbelle1Article,
                    :EcranLigneQuantiteTheorie;
            If GestionErreurSQL();
                Leave;
            EndIf;
        EndDo;
    Else;
        If GestionErreurSQL();
            EcranMessageErreur = 'Erreur lecture données';
            Indicateur.MasquerMessageErreur = *Off;
        EndIf;
    EndIf;
    
    Exec SQL CLOSE C_INVENTAIRE;
    
    // Configuration du sous-fichier
    NombreTotalLignesSF = fichierDS.rang_sfl;
    
    If NombreTotalLignesSF > 0;
        Indicateur.SousFichierDisplay = *On;
        Indicateur.SousFichierDisplayControl = *On;
        Indicateur.SousFichierEnd = *On;
    Else;
        Indicateur.SousFichierDisplay = *Off;
        Indicateur.SousFichierDisplayControl = *On;
        Indicateur.SousFichierEnd = *Off;
    EndIf;
    
    // Initialisation des statistiques
    CalculerStatistiques();
    
    // Positionnement initial
    EcranLigneSousFichier = 1;
    EcranDeplacerCurseurLigne = 9;
    EcranDeplacerCurseurColonne = 70;
End-Proc;

///
// VerificationInventaire()
// Vérifie les quantités saisies dans l'inventaire
// @return *On si OK, *Off si erreur
///
Dcl-Proc VerificationInventaire;
    Dcl-Pi *N Ind;
    End-Pi;
    
    Dcl-S i Zoned(4:0);
    Dcl-S CurseurPositionne Ind Inz(*Off);
    
    // Réinitialisation des messages
    Indicateur.MasquerMessageErreur = *On;
    Indicateur.MasquerMessageInfo = *On;
    
    For i = 1 to NombreTotalLignesSF;
        Chain i GESTIONSFL;
        
        // Vérification que les quantités ne sont pas négatives
        If EcranLigneQuantiteInventaire < 0;
            If Not CurseurPositionne;
                EcranDeplacerCurseurLigne = i + 8;
                EcranDeplacerCurseurColonne = 70;
                CurseurPositionne = *On;
            EndIf;
            EcranMessageErreur = 'Quantités négatives non autorisées';
            Indicateur.MasquerMessageErreur = *Off;
            Return *Off;
        EndIf;
        
        Update GESTIONSFL;
    EndFor;
    
    Return *On;
End-Proc;

///
// CalculerStatistiques()
// Calcule les statistiques d'inventaire (stockées en interne seulement)
///
Dcl-Proc CalculerStatistiques;
    Dcl-Pi *N;
    End-Pi;
    
    Dcl-S i Zoned(4:0);
    
    // Initialisation des compteurs
    NbTotalArticles = 0;
    NbEcartsPositifs = 0;
    NbEcartsNegatifs = 0;
    
    For i = 1 to NombreTotalLignesSF;
        Chain i GESTIONSFL;
        
        NbTotalArticles += 1;
        
        // Calcul de l'écart (en interne seulement)
        EcartCalcule = EcranLigneQuantiteInventaire - EcranLigneQuantiteTheorie;
        
        // Comptage des écarts
        If EcartCalcule > 0;
            NbEcartsPositifs += 1;
        ElseIf EcartCalcule < 0;
            NbEcartsNegatifs += 1;
        EndIf;
        
        Update GESTIONSFL;
    EndFor;
    
    // Affichage d'un message d'information sur les statistiques
    EcranMessageInfo = 'Articles: ' + %Char(NbTotalArticles);
    If NbEcartsPositifs > 0 Or NbEcartsNegatifs > 0;
        EcranMessageInfo = %Trim(EcranMessageInfo) + ' - Écarts: ' + 
                         %Char(NbEcartsPositifs + NbEcartsNegatifs);
    EndIf;
    Indicateur.MasquerMessageInfo = *Off;
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
        For i = 1 to NombreTotalLignesSF;
            Chain i GESTIONSFL;
            
            // Calcul de l'écart pour cette ligne
            EcartLigne = EcranLigneQuantiteInventaire - EcranLigneQuantiteTheorie;
            
            // Ne traiter que les lignes avec des quantités saisies ou des écarts
            If EcranLigneQuantiteInventaire > 0 Or EcartLigne <> 0;
                
                // Mise à jour KCOCUM avec le nouvel écart
                Exec SQL
                    UPDATE KCOCUM
                    SET QuantiteCumulEcart = :EcartLigne,
                        QuantiteTheoriqueStock = QuantiteLivree - QuantiteRetournee + :EcartLigne,
                        HorodatageSaisie = CURRENT TIMESTAMP,
                        ProfilUser = :psds.User
                    WHERE CodeClient = :EcranCodeClient
                    AND CodeArticle = :EcranLigneCodeArticle;
                
                If GestionErreurSQL();
                    EcranMessageErreur = 'Erreur mise à jour KCOCUM: ' + EcranLigneCodeArticle;
                    Indicateur.MasquerMessageErreur = *Off;
                    Exec SQL ROLLBACK TO SAVEPOINT DEBUT_INVENTAIRE;
                    Return;
                EndIf;
                
                
                If GestionErreurSQL();
                    EcranMessageErreur = 'Erreur historique: ' + EcranLigneCodeArticle;
                    Indicateur.MasquerMessageErreur = *Off;
                    Exec SQL ROLLBACK TO SAVEPOINT DEBUT_INVENTAIRE;
                    Return;
                EndIf;
                
                // TODO: Optionnellement générer mouvements de stock d'ajustement
                // si paramètre activé dans TABVV
            EndIf;
        EndFor;
        
        // Validation de la transaction
        Exec SQL COMMIT;
        
        // Message de confirmation
        EcranMessageInfo = 'Inventaire sauvegardé - ' 
                         + %Char(NbTotalArticles) + ' articles traités';
        Indicateur.MasquerMessageInfo = *Off;
        
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
// GetCodeSociete()
// Récupère le code société par défaut
// @return Code société
///
Dcl-Proc GetCodeSociete;
    Dcl-Pi *N Char(2);
    End-Pi;
    
    Dcl-S CodeSocieteReturn Char(2);
    
    Exec SQL
        SELECT XCOARG
        INTO :CodeSocieteReturn
        FROM VPARAM
        WHERE XCORAC = 'STE';
    If SQLCode <> 0;
        GestionErreurSQL();
        CodeSocieteReturn = *ALL'?';
    EndIf;
    
    Return CodeSocieteReturn;
End-Proc;

///
// GestionErreurSQL()
// Gère les erreurs SQL et retourne un indicateur d'erreur
// @return *On si erreur, *Off si OK
///
Dcl-Proc GestionErreurSQL;
    Dcl-Pi *N Ind;
    End-Pi;
    
    Dcl-S MessageId         Char(10);
    Dcl-S MessageText       Varchar(200);
    Dcl-S ReturnedSQLCode   Char(5);
    Dcl-S ReturnedSQLState  Char(5);
    
    If (SqlCode <> 0 And SqlCode <> 100);
        Exec SQL GET DIAGNOSTICS CONDITION 1
                :ReturnedSQLCode = DB2_RETURNED_SQLCODE,
                :ReturnedSQLState = RETURNED_SQLSTATE,
                :MessageText = MESSAGE_TEXT,
                :MessageId = DB2_MESSAGE_ID;
        
        DSPLY ('SQLCode: ' + ReturnedSQLCode);
        DSPLY ('SQLState: ' + ReturnedSQLState);
        DSPLY ('Error ID: ' + %Trim(MessageId));
        
        Return *On;
    EndIf;
    
    Return *Off;
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