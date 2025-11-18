class SupabaseConfig {
  static const String url = 'https://iqbuntlugpwormuezefga.supabase.co';

  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml1YnFudGx1Z3B3b3JtdXplZmdhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIxNDQ1MTEsImV4cCI6MjA2NzcyMDUxMX0.XvZ6e_2Q9UILZ2gASdh1a_VJk3xqWYoMZFxLhJXJX1M';

  static const String serviceRoleKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml1YnFudGx1Z3B3b3JtdXplZmdhIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjE0NDUxMSwiZXhwIjoyMDY3NzIwNTExfQ.JDV_WIBP0mNSfIua6WKRbjDXvf9-SIYgnHHF_hUp-1s';

  static const Map<String, String> tables = {
    'user_profiles': 'Profils des utilisateurs (clients et livreurs)',
    'livreur_kyc_submissions': 'Soumissions KYC des livreurs',
    'livreur_kyc_history': 'Historique des actions KYC',
    'missions': 'Missions de livraison',
    'ratings': 'Évaluations des utilisateurs',
    'livreur_tracking': 'Suivi GPS des livreurs',
    'notifications': 'Notifications système',
    'messages': 'Messages entre utilisateurs',
  };

  static const Map<String, String> userRoles = {
    'client': 'Client qui commande des livraisons',
    'livreur': 'Livreur qui effectue les livraisons',
    'admin': 'Administrateur de la plateforme',
  };

  static const Map<String, String> missionStatuses = {
    'en_attente': 'Mission en attente d\'attribution',
    'attribuée': 'Mission attribuée à un livreur',
    'en_livraison': 'Mission en cours de livraison',
    'livrée': 'Mission terminée avec succès',
    'annulée': 'Mission annulée',
  };

  static const Map<String, String> kycStatuses = {
    'pending': 'En attente de vérification',
    'approved': 'Approuvé',
    'rejected': 'Rejeté',
    'correction_required': 'Correction demandée',
  };

  static const Map<String, String> deliveryTypes = {
    'me': 'Livraison à moi-même',
    'other': 'Livraison à quelqu\'un d\'autre',
  };

  static const Map<String, String> deliveryOutcomes = {
    'livré': 'Livraison réussie',
    'refusé': 'Livraison refusée par le destinataire',
    'echec': 'Échec de la livraison',
  };
}
