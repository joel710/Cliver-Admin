# Documentation du Back-Office Kolisa Admin

Bienvenue dans la documentation du back-office de Kolisa Admin. Ce document a pour but de décrire en détail les fonctionnalités et les pages disponibles dans l'application d'administration.

## 1. Introduction Générale

Le back-office Kolisa Admin est une application Flutter conçue pour fournir une interface centralisée pour la gestion et la surveillance de la plateforme Kolisa. Il permet aux administrateurs d'accéder à des données critiques, de gérer les utilisateurs (clients et livreurs), de superviser les opérations et de configurer divers aspects de l'application.

### Architecture

L'application est construite avec le framework **Flutter**, garantissant une expérience utilisateur fluide et réactive sur le web et les plateformes de bureau. La navigation est gérée par le package `go_router`, offrant un routage robuste et basé sur les chemins.

La communication avec la base de données et les services backend est assurée par **Supabase**, une plateforme open-source qui fournit une base de données PostgreSQL, une authentification, des fonctions serverless et un stockage de fichiers.

## 2. Navigation Principale

L'interface principale du back-office est structurée autour d'un menu de navigation latéral (Drawer) qui donne accès aux sections principales de l'application.

Voici les éléments du menu principal :

- **Tableau de bord :** La page d'accueil, offrant une vue d'ensemble des métriques clés.
- **KYC (Know Your Customer) :** Pour la vérification et la gestion des documents d'identité des utilisateurs.
- **Livreurs :** Outils pour la surveillance et la gestion des chauffeurs.
- **Support :** Section dédiée à la gestion des tickets de support et à l'assistance aux utilisateurs.
- **Configuration :** Permet de modifier les paramètres généraux de l'application.

En plus de la navigation principale, le menu latéral contient également des sections pour les **Actions rapides** et les **Promotions & Abonnements**, offrant un accès direct à des fonctionnalités importantes.

## 3. Pages et Fonctionnalités

Cette section décrit en détail chaque page accessible depuis le back-office.

### 3.1. Tableau de bord (`dashboard_screen.dart`)

Le tableau de bord est la page d'accueil de l'application d'administration. Il est conçu pour donner un aperçu rapide de l'état de la plateforme.

**Widgets et Informations :**

- **Cartes de Métriques :** Affichent les revenus (aujourd'hui, cette semaine, ce mois, total), le nombre total de missions et la commission moyenne.
- **Graphique de Revenus :** Visualisation de l'évolution des revenus sur une période donnée.
- **Actions Rapides :** Raccourcis pour accéder à la gestion des promotions et à l'attribution d'abonnements.
- **Activité Récente :** Liste des dernières transactions et événements sur la plateforme.

Le tableau de bord comporte également des onglets pour une analyse plus approfondie :

- **Vue d'ensemble :** La vue par défaut avec les métriques principales.
- **Revenus :** Informations détaillées sur le solde de la plateforme et l'historique des revenus.
- **Livreurs :** Classement des livreurs les plus performants en fonction de leurs commissions.
- **Analytics :** Métriques détaillées sur les utilisateurs, les missions, les revenus et l'état du système.

### 3.2. KYC (`submissions_list_screen.dart`, `submission_detail_screen.dart`)

La section KYC est cruciale pour la vérification des utilisateurs.

- **`submissions_list_screen.dart` :** Affiche la liste de toutes les soumissions KYC, avec des filtres pour trier par statut (en attente, approuvé, rejeté).
- **`submission_detail_screen.dart` :** Montre les détails d'une soumission spécifique, y compris les documents soumis. L'administrateur peut y approuver, rejeter ou demander des corrections.

### 3.3. Gestion des Livreurs (`drivers_monitoring_screen.dart`, `driver_profile_screen.dart`)

Cette section permet de gérer et de suivre les livreurs.

- **`drivers_monitoring_screen.dart` :** Fournit une vue d'ensemble de tous les livreurs, avec leur statut actuel (en ligne, hors ligne, en mission).
- **`driver_profile_screen.dart` :** Affiche le profil détaillé d'un livreur, incluant ses informations personnelles, l'historique de ses missions et ses évaluations.

### 3.4. Gestion des Clients (`clients_monitor_screen.dart`, `client_profile_screen.dart`)

Similaire à la gestion des livreurs, cette section est dédiée aux clients.

- **`clients_monitor_screen.dart` :** Liste tous les clients inscrits, avec des informations de base.
- **`client_profile_screen.dart` :** Vue détaillée du profil d'un client, avec l'historique de ses commandes et ses informations de contact.

### 3.5. Support (`support_dashboard_screen.dart`, `ticket_details_admin_screen.dart`)

Cette section est le centre de gestion de l'assistance aux utilisateurs.

- **`support_dashboard_screen.dart` :** Affiche un tableau de bord avec tous les tickets de support, triés par statut (ouvert, en cours, résolu).
- **`ticket_details_admin_screen.dart` :** Permet de visualiser et de répondre à un ticket de support spécifique.

### 3.6. Configuration (`app_config_screen.dart`, `settings_screen.dart`)

Ici, les administrateurs peuvent configurer le comportement de l'application.

- **`app_config_screen.dart` :** Permet de modifier des variables de configuration globales, telles que les tarifs, les zones de service, etc.
- **`settings_screen.dart` :** Contient des paramètres généraux pour le back-office lui-même.

### 3.7. Surveillance et Rapports (`admin_alerts_screen.dart`, `audit_logs_screen.dart`, `crash_reporting_screen.dart`, `map_tracking_screen.dart`, `reports_management_screen.dart`, `system_errors_screen.dart`)

Cette suite d'écrans est dédiée à la surveillance avancée de la plateforme.

- **`admin_alerts_screen.dart` :** Affiche les alertes importantes nécessitant une attention immédiate.
- **`audit_logs_screen.dart` :** Journal de toutes les actions effectuées par les administrateurs dans le back-office.
- **`crash_reporting_screen.dart` :** Rapports de plantage de l'application, utiles pour le débogage.
- **`map_tracking_screen.dart` :** Carte en temps réel pour suivre la position des livreurs.
- **`reports_management_screen.dart` :** Gestion des signalements faits par les utilisateurs.
- **`system_errors_screen.dart` :** Journal des erreurs système et des problèmes techniques.

### 3.8. Promotions et Abonnements (`promotions_management_screen.dart`, `subscription_grants_screen.dart`)

Cette section permet de gérer les offres marketing et les abonnements des utilisateurs.

- **`promotions_management_screen.dart` :** Interface pour créer, modifier et supprimer des codes promotionnels et des offres spéciales.
- **`subscription_grants_screen.dart` :** Permet d'attribuer manuellement des abonnements ou des avantages à des utilisateurs spécifiques.

### 3.9. Gestion des Utilisateurs (`user_blocks_screen.dart`)

- **`user_blocks_screen.dart` :** Permet de bloquer ou de débloquer des utilisateurs (clients ou livreurs) qui ont enfreint les règles de la plateforme.

## 4. Services

Les services contiennent la logique métier de l'application. Ils sont responsables de la communication avec Supabase et de la manipulation des données.

Voici un aperçu des principaux services :

- **`auth_service.dart` :** Gère l'authentification des administrateurs.
- **`analytics_service.dart` :** Fournit les données pour l'onglet Analytics du tableau de bord.
- **`unified_revenue_service.dart` :** Centralise la logique de calcul et de récupération des revenus.
- **`kyc_repository.dart` :** Gère les opérations liées aux soumissions KYC.
- **`support_service.dart` :** S'occupe de la logique métier pour les tickets de support.
- **`promotions_service.dart` :** Gère la création et la validation des codes promotionnels.
- **`user_blocks_service.dart` :** Gère le blocage et le déblocage des utilisateurs.
- **`app_config_service.dart` :** Permet de lire et de modifier la configuration de l'application.

## 5. Conclusion

Cette documentation fournit un aperçu complet du back-office Kolisa Admin. Pour des détails plus techniques sur l'implémentation, veuillez vous référer directement au code source dans le répertoire `lib/admin`.
