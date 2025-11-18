# Cliver Admin - Application d'administration pour livreurs

Application Flutter d'administration pour la plateforme de livraison Kolisa, permettant aux administrateurs de gérer les livreurs, vérifier les KYC et assurer le support.

## 🚀 Fonctionnalités principales

### 📋 Gestion KYC
- **Vérification des demandes** : Consultez et traitez les demandes de vérification d'identité des livreurs
- **Approbation/Rejet** : Approuvez ou rejetez les demandes KYC avec possibilité de demander des corrections
- **Historique complet** : Accédez à l'historique de toutes les vérifications

### 🚚 Surveillance des livreurs
- **Suivi en temps réel** : Surveillez la position et le statut des livreurs en temps réel
- **Statistiques de performance** : Consultez les métriques de performance (missions, taux de succès, notes)
- **Gestion des statuts** : Modifiez le statut de disponibilité des livreurs
- **Profils détaillés** : Accédez aux informations complètes de chaque livreur

### 🆘 Support et incidents
- **Tickets de support** : Créez et gérez les tickets de support pour les livreurs
- **Gestion des priorités** : Attribuez des priorités aux incidents (urgent, élevé, moyen, faible)
- **Suivi des résolutions** : Suivez l'état d'avancement des problèmes
- **Historique des incidents** : Consultez l'historique complet des problèmes par livreur

### 📊 Tableau de bord
- **Vue d'ensemble** : Statistiques en temps réel de la plateforme
- **Navigation intuitive** : Interface avec navigation en bas pour un accès rapide
- **Activités récentes** : Suivi des dernières actions sur la plateforme

## 🛠️ Architecture technique

### Frontend
- **Framework** : Flutter 3.x
- **Navigation** : Navigation en bas avec 4 onglets principaux
- **État** : StatefulWidget pour la gestion locale de l'état
- **UI** : Material Design 3 avec thème personnalisable

### Backend
- **Base de données** : Supabase (PostgreSQL) avec schéma réel
- **Authentification** : Supabase Auth
- **API** : Requêtes directes vers les tables Supabase
- **Temps réel** : Supabase Realtime pour les mises à jour en direct

### Services
- `DashboardService` : Statistiques globales et activités récentes
- `DriversService` : Gestion des livreurs et surveillance
- `SupportService` : Gestion des tickets de support et incidents
- `SupabaseAdminService` : Gestion des opérations KYC

## 📱 Structure de navigation

L'application utilise une navigation en bas avec 4 onglets principaux :

1. **Tableau de bord** (`/`) : Vue d'ensemble avec statistiques et activités récentes
2. **KYC** : Gestion des demandes de vérification d'identité
3. **Livreurs** : Surveillance et gestion des livreurs
4. **Support** : Gestion des tickets de support et incidents

## 🗄️ Structure de la base de données

L'application utilise le schéma Supabase réel avec les tables suivantes :

### Tables principales
- `user_profiles` : Profils des utilisateurs (clients et livreurs)
- `livreur_kyc_submissions` : Demandes de vérification KYC
- `livreur_kyc_history` : Historique des actions KYC
- `missions` : Missions de livraison
- `ratings` : Évaluations des utilisateurs
- `livreur_tracking` : Suivi GPS des livreurs
- `notifications` : Notifications système
- `messages` : Messages entre utilisateurs

### Relations clés
- Les livreurs ont le rôle 'livreur' dans `user_profiles`
- Les missions sont liées aux clients et livreurs via `client_id` et `livreur_id`
- Les évaluations sont liées aux missions et utilisateurs
- Le suivi GPS est lié aux livreurs via `livreur_id`

## 🚀 Installation et configuration

### Prérequis
- Flutter SDK 3.x
- Dart 3.x
- Android Studio / VS Code
- Compte Supabase

### Configuration Supabase
1. Créez un projet sur [supabase.com](https://supabase.com)
2. Exécutez le script SQL fourni pour créer les tables
3. Configurez les politiques RLS (Row Level Security)
4. Récupérez votre URL et clé API

### Configuration de l'application
1. Clonez le repository
2. Installez les dépendances : `flutter pub get`
3. Configurez Supabase dans `lib/admin/config/supabase_config.dart`
4. Lancez l'application : `flutter run`

### Variables d'environnement
Créez un fichier `.env` avec :
```
SUPABASE_URL=votre_url_supabase
SUPABASE_ANON_KEY=votre_clé_anon
SUPABASE_SERVICE_ROLE_KEY=votre_clé_service
```

## 🔧 Développement

### Ajout de nouvelles fonctionnalités
1. Créez l'écran dans `lib/admin/screens/`
2. Ajoutez le service correspondant dans `lib/admin/services/`
3. Mettez à jour la navigation si nécessaire

### Tests
- Tests unitaires : `flutter test`
- Tests d'intégration : `flutter test integration_test/`

## 📈 Roadmap

### Phase 1 (Actuelle)
- ✅ Gestion KYC de base
- ✅ Surveillance des livreurs
- ✅ Support et incidents
- ✅ Interface d'administration avec navigation en bas
- ✅ Intégration avec le schéma de base de données réel

### Phase 2 (Prévue)
- 🔄 Intégration Google Maps pour la surveillance GPS
- 🔄 Notifications push en temps réel
- 🔄 Chat de support intégré
- 🔄 Rapports et analytics avancés

### Phase 3 (Future)
- 📱 Application mobile pour les livreurs
- 🤖 Système de notifications automatiques
- 📊 Tableaux de bord avancés
- 🔐 Gestion des rôles et permissions

## 🚨 Sécurité

### Politiques RLS recommandées
```sql
-- Exemple pour user_profiles
CREATE POLICY "Les admins peuvent voir tous les profils" ON user_profiles
FOR SELECT USING (auth.role() = 'authenticated');

-- Exemple pour missions
CREATE POLICY "Les admins peuvent voir toutes les missions" ON missions
FOR SELECT USING (auth.role() = 'authenticated');
```

### Authentification
- Utilisez Supabase Auth pour la gestion des sessions
- Limitez l'accès aux fonctionnalités admin
- Implémentez la validation des permissions

## 🤝 Contribution

1. Fork le projet
2. Créez une branche feature (`git checkout -b feature/AmazingFeature`)
3. Committez vos changements (`git commit -m 'Add some AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrez une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 📞 Support

Pour toute question ou problème :
- Créez une issue sur GitHub
- Contactez l'équipe de développement
- Consultez la documentation Supabase

--- 
