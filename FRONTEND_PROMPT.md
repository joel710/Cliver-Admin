# Prompt pour la Génération du Frontend React du Back-Office Kolisa Admin

## 1. Objectif

Générer une application web React complète pour le back-office de "Kolisa Admin". L'application doit être fonctionnelle, moderne et suivre les meilleures pratiques de développement React.

## 2. Stack Technique

- **Framework :** React (avec Create React App ou Vite)
- **Bibliothèque de composants :** Material-UI (MUI) pour un design cohérent et professionnel.
- **Routage :** React Router pour la navigation entre les pages.
- **Gestion de l'état (optionnel) :** Redux Toolkit ou React Context pour les états globaux complexes.
- **Appels API :** Axios ou Fetch API pour communiquer avec le backend Supabase.

## 3. Palette de Couleurs

L'application doit utiliser une palette de couleurs générée à partir de la couleur de base suivante, conformément aux principes de Material Design 3 :

- **Couleur de base (Seed Color) :** `#2196F3`

Utilisez cette couleur pour générer un thème Material-UI complet avec des variantes pour les modes clair (light) et sombre (dark).

## 4. Structure du Projet

Organisez le code de manière modulaire :

```
/src
  /components  # Composants réutilisables (boutons, cartes, etc.)
  /pages       # Composants de page principaux
  /services    # Logique métier, appels API
  /theme       # Configuration du thème MUI
  /utils       # Fonctions utilitaires
  /routes      # Configuration de React Router
  App.js
  index.js
```

## 5. Pages à Créer

Le back-office doit contenir les pages suivantes, accessibles via un menu de navigation latéral (Drawer) :

### 5.1. Authentification
- **`LoginPage.js` :** Un formulaire de connexion pour les administrateurs.

### 5.2. Navigation Principale
- **`Layout.js` :** Un composant de layout principal qui inclut une barre d'application (AppBar) et un menu latéral persistant (Drawer) pour la navigation.

### 5.3. Pages principales
- **`DashboardPage.js` :**
  - Affiche des cartes de métriques clés (revenus, missions, etc.).
  - Inclut des graphiques pour visualiser les tendances des revenus.
  - Présente une liste des activités récentes.
  - Comporte des onglets pour "Vue d'ensemble", "Revenus", "Livreurs", et "Analytics".

- **`KycPage.js` :**
  - Affiche une table des soumissions KYC avec des filtres par statut.
  - Permet de cliquer sur une soumission pour voir les détails.

- **`KycDetailPage.js` :**
  - Affiche les détails d'une soumission KYC.
  - Permet à l'administrateur d'approuver, de rejeter ou de demander des corrections.

- **`DriversPage.js` :**
  - Affiche une liste de tous les livreurs avec leur statut.
  - Permet de rechercher et de filtrer les livreurs.

- **`DriverProfilePage.js` :**
  - Affiche le profil détaillé d'un livreur.

- **`ClientsPage.js` :**
  - Affiche une liste de tous les clients.

- **`ClientProfilePage.js` :**
  - Affiche le profil détaillé d'un client.

- **`SupportPage.js` :**
  - Affiche un tableau de bord des tickets de support.

- **`SupportTicketDetailPage.js` :**
  - Permet de voir et de répondre à un ticket de support.

- **`ConfigurationPage.js` :**
  - Contient des formulaires pour modifier les paramètres de l'application.

### 5.4. Pages de Surveillance
- **`AdminAlertsPage.js` :**
  - Affiche les alertes importantes.

- **`AuditLogsPage.js` :**
  - Affiche un journal des actions des administrateurs.

- **`CrashReportsPage.js` :**
  - Affiche les rapports de plantage.

- **`MapTrackingPage.js` :**
  - Intègre une carte (par exemple, avec Leaflet ou Google Maps) pour suivre les livreurs en temps réel.

- **`ReportsPage.js` :**
  - Affiche les signalements des utilisateurs.

### 5.5. Pages de Gestion
- **`PromotionsPage.js` :**
  - Permet de créer et de gérer les promotions.

- **`SubscriptionsPage.js` :**
  - Permet d'attribuer des abonnements.

- **`UserBlockingPage.js` :**
  - Permet de bloquer et débloquer des utilisateurs.
