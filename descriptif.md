# GESTION DES CONSIGNES : Suivi non unitaire, sans PDA

## Introduction

Dans le cadre des activités de livraison, nos sociétés mettent à disposition de leurs clients des articles consignés (frigos, rolls, etc.).
Pour assurer une gestion efficace de ce parc d'articles et maintenir un niveau de service optimal, il est essentiel de mettre en place un système de suivi rigoureux.
Sans PDA, le suivi sera principalement quantitatif et simplifié pour s'adapter aux contraintes des sociétés. L'utilisation d'un PDA permettra d'apporter une dimension qualitative supplémentaire, en individualisant chaque article consigné. Il sera ainsi possible de connaître l'historique et la localisation de chaque article à tout moment, que ce soit chez le client ou au sein de la société.
La gestion des consignes permet non seulement de réduire les pertes et d’effectuer un inventaire précis, mais aussi de garantir la disponibilité et la traçabilité des consignes tant chez nos clients qu'au sein de nos sociétés.

## Tables utilisées

### Tables existantes

### Tables à créer

XCOPAR : TBVV des paramètres des consignes
    - Chrono de bon de mise à disposition
    - Type article considéré comme consigne
    - Dépôt des consignes
    - code mouvement des consignes

KCOENT : Table des entêtes des livraisons de consignes
    - Numéro de bon de mise à disposition
    - Numéro d'édition du bon de mise à disposition
    - Livraison associée
    - Facture associée
    - Horodatage lors de la validation
    - Utilisateur effectuant la validation

KCOLIG : Table des lignes des livraisons de consignes
    - Numéro de bon de mise à disposition
    - Numéro d'édition du bon de mise à disposition
    - Code article
    - Quantité livrée
    - Quantité retournée

KCOCUM : Table des cumuls par clients
    - Code client
    - Code article
    - Quantité livrée
    - Quantité retournée
    - Horodatage derniere mise à jour
  
## Editions

Edition du bon de mise à disposition :
entête :
    - Code client
    - Raison sociale
    - Nom commercial
    - Adresse
    - Numéro de bon de mise à disposition des consignes
    - Numéro d'édition du bon de mise à disposition
    - Date
    - Heure

Lignes :
    - Code article
    - Quantité livrée
    - Quantité retournée
    - Prix HT

Somme des prix

## Livraison des consignes

l’opérateur du dépôt saisit les consignes à livrer avant que le chauffeur ne soit parti en livraison.

Action : Stocks -> suivi article consignés -> Livraison des consignes
Code Action : GER LIVCON -> Gestion
Code Action : VIS LIVCON -> Visualisation

1 écran : écran de garde
Permet de sélectionner la livraison

2 écran : écran de saisie des consignes
Permet de saisir les quantités des consignes associées à la livraison

### Livraison des consignes : écran de garde

L'utilisateur peut saisir :

- numéro de livraison
- numéro de facture
- numéro de bon de mise à disposition (pour modifier une saisie)

Si saisie d'une facture et que la facture a plusieurs livraisons => Message d'erreur, l'utilisateur doit forcément saisir soit le bon de mise à disposition soit le numéro de livraison.

La saisie du bon de mise à disposition permet à l'utilisateur, lors d'une modifcation de la livraison de consignes, de modifier directement son bon de mise à disposition. Cela simplifie la gestion pour l'utilisateur qui a le bon en main.

#### Livraison des consignes : écran de garde : affichage

TITRE : GESTION DES CONSIGNES: AVANT LIVRAISON

Données en saisie :
    - Code Société (obligatoire)
    - Numéro de livraison
    - Numéro de facture
    - Numéro de bon de mise à disposition (inconnu si on est en création)

Fonctions :
    - F2=Utilisateur
    - F3=Fin
    - F4=Recherche
    - F6=Services
    - F10=Action
    - F12=Abandon
    - F23=Recherche multi-critères

#### Livraison des consignes : écran de garde : saisies

Saisie du code société (obligatoire)
Saisie soit du numéro de livraison ou du numéro de facture. Le but étant de retrouver le numéro de livraison.
Si l'utilisateur saisit le numéro de livraison et le numéro de facture, on vérifie que les 2 sont bien associés
sinon => Message d'erreur.

Recherches :
    multi-critères :
    - Numéro de livraison (voir programme de livraison)

#### Livraison des consignes : écran de garde : règles générales

Vérifications existance :
    - Code Société
    - Numéro de livraison
    - Numéro de facture
    - Numéro de bon de mise à disposition

Vérification champs obligatoire :
    - Code société
    - Numéro de livraison ou numéro de facture ou numéro de bon de mise à disposition

Les données en saisies sont sauvegardées pour proposer à l'utilisateur son dernier choix par défaut.
Si il y a déjà eu un retour du bon de mise à disposition, il n'est pas possible d'effectuer une nouvelle livraison.
Si la date confirmée de livraison est déjà passé, on autorise quand même la saisie du bon de mise à disposition des consignes.

#### Livraison des consignes : écran de garde : validation de la saisie

Validation par "enter" : amène à l'écran de saisie, sauvegarde les choix par défaut et on "verrouille" le bon de mise à disposition.
Si on est en gestion et que le bon de mise à disposition est déjà "verrouillé" par un utilisateur, on reste sur le même écran et on affiche un message d'erreur.

### Livraison des consignes : écran de saisies

Permet la saisie des quanitités des articles consignés livrés

#### Livraison des consignes : écran de saisies : affichage

Entête :
    - Code client
    - Raison sociale
    - Nom commercial
    - Adresse
    - Numéro de bon de mise à disposition des consignes + numéro d'édition (inconnu si on est en création)
    - Numéro de livraison
    - Date confirmée de la livraison
    - Numéro de facture

Sous-fichier :
    - Code article
    - Libellé 1
    - Libellé 2 (multi-lignes)
    - Quantité livrée
    - Quantité retournée

Fonctions :
    - F2=Utilisateur
    - F3=Fin
    - F4=Recherche
    - F6=Services
    - F10=Action
    - F12=Abandon
    - F14=multi-lignes
    - F17=Valider
    - F20=Imprimer
    - F23=Recherche multi-critères

#### Livraison des consignes : écran de saisies : saisies

Saisie possible uniquement dans la colonne quantité livrée
Saisie impossible dans la colonne quantité retournée

#### Livraison des consignes : écran de saisies : règles

- Les articles sont pré-chargés en fonction de leur type article. Il faut sortir la liste des articles qui sont du même type que ceux définis dans la TBVV XCOPAR
- Les quantités des articles sont pré-chargés si il y a déjà eu une saisie, idem pour le numéro d'édition

#### Livraison des consignes : écran de saisies : validation de la saisie

Validation de la saisie par F17 :

- Message fenetre : "Livraison mise à jour" validation par n'importe quel touche
- Edition
- Génération mouvements  de stock :
  - VMTSTK
  - Mise à jour de la nouvelle table de gestion des consignes cumul par client
  - Mise à jour table des ent

## Retour consignes

Le retour de consigne permet, lors du retour du chauffeur :

- Saisir la correction de la livraison réelle des quantités des consignes
- Saisir le retour des consignes

Action : Stocks -> suivi article consignés -> Retour des consignes

### Retour consignes : écran de garde

Permet de saisir le numéro de bon de mise à disposition pour effectuer un retour.
Si l'utilisateur n'a pas de numéro de document, il pourra effectuer le retour via la saisie d'un code client et d'une date (fenetre).

#### Retour consignes : écran de garde : affichage

TITRE : GESTION DES CONSIGNES: APRES LIVRAISON

Données en saisie :
    - Code Société (obligatoire)
    - Numéro de livraison
    - Numéro de facture
    - Numéro de bon de mise à disposition
    - Zone "pas de document"

Fonctions :
    - F2=Utilisateur
    - F3=Fin
    - F4=Recherche
    - F6=Services
    - F12=Abandon
    - F23=Recherche multi-critères

#### Retour consignes : écran de garde : règles

Vérification existances :
    - Code Société
    - Numéro de livraison
    - Numéro de facture
    - Numéro de bon de mise à disposition
    - Zone "pas de document"

Vérification saisie obligatoire :
    - Code société
    - Numéro de livraison ou numéro de facture ou numéro de bon de mise à disposition ou zone "pas de document"

Il n'est pas possible de saisir "pas de document" et de saisir en même temps d'autres données (numéro de livraison, numéro de facture ou numéro de bon de mise à disposition)

S'il y a une saisie de plusieurs critères (numéro de livraison, numéro de facture et numéro de bon de mise à disposition), on vérifie qu'ils sont tous cohérents

#### Retour consignes : écran de garde : validation de la saisie

Si la zone "pas de document" est cochée :
Ouverture d'une fenetre permettant de saisir un code client et une date de retour.

Si on est en gestion et que le bon de mise à disposition est déjà "verrouillé" par un utilisateur, on reste sur le même écran et on affiche un message d'erreur.
La validation amène à l'écran de saisie, sauvegarde les chois utilisateurs et on "verrouille" le bon de mise à disposition.

### Retour consignes : écran de saisies

### Retour consignes : écran de saisies : affichage

Entête :
    - Code client
    - Raison sociale
    - Nom commercial
    - Adresse
    - Numéro de bon de mise à disposition des consignes + numéro d'édition
    - Numéro de livraison
    - Date confirmée de la livraison
    - Numéro de facture

Sous-fichier :
    - Code article
    - Libellé 1
    - Libellé 2 (multi-lignes)
    - Quantité livrée
    - Quantité retournée

Fonctions :
    - F2=Utilisateur
    - F3=Fin
    - F6=Services
    - F12=Abandon
    - F14=multi-lignes
    - F17=Valider
    - F23=Recherche multi-critères

### Retour consignes : écran de saisies : saisies

Saisie possible uniquement dans la colonne quantité livrée
Saisie impossible dans la colonne quantité retournée

### Retour consignes : écran de saisies : règles

L'impression ne sera pas disponible

Cas avec document :
Les quantités des articles sont pré-chargés via la table des lignes des articles consignés

Cas sans document :
Les quantités des articles sont forcément à 0 par défaut et il n'est pas possible de modifier les quantités livrés mais seulement les quantités retournée.
Dans ce cas, on incrémentera un nouveau bon de mise à disposition.

### Retour consignes : écran de saisies : validation de la saisie

Validation de la saisie par F17 :

- Message fenetre : "Retour mis à jour" validation par n'importe quel touche
- Edition
- Génération mouvements  de stock :
  - VMTSTK
  - Mise à jour de la nouvelle table de gestion des consignes cumul par client
  - Mise à jour table des ent

## Gestion des consignes par client

Cette action permet de mettre à jour le soldes pour chaque client (cumul par client)

Action : Stocks -> suivi article consignés -> Cumul par client
Code Action : GER CLICON -> Gestion
Code Action : VIS CLICON -> Visualisation

### Gestion des consignes par client : écran de garde

### Gestion des consignes par client : écran de garde : affichage

Saisie :
    - Code société
    - Code client (F23 possible)

Fonctions :
    - F2=Utilisateur
    - F3=Fin
    - F6=Services
    - F12=Abandon
    - F23=Recherche multi-critères

### Gestion des consignes par client : écran de garde : règles

Vérifications :
    - Code société
    - Code client

### Gestion des consignes par client : écran de garde : validation

Entête :
    - Code client
    - Raison sociale
    - Nom commercial
    - Adresse
    - Horodatage dernière mise à jour des consignes

Sous-fichier :
    - Code article
    - Libellé 1
    - Libellé 2 (multi-lignes)
    - Quantité

Fonctions :
    - F2=Utilisateur
    - F3=Fin
    - F6=Services
    - F12=Abandon
    - F14=multi-lignes
    - F17=Valider
    - F23=Recherche multi-critères

### Gestion des consignes par client : écran de garde : saisie

L'utilisateur peut saisir les quantité

### Gestion des consignes par client : écran de garde : règles

Si l

### Gestion des consignes par client : écran de garde : validation

Validation par F17: Vient mettre à jour le stock cumul du client et vient faire des mouvements I-, I+ dans le fichier des mouvements de stock.