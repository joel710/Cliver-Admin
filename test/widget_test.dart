// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kolisa_admin/main.dart';
import 'package:kolisa_admin/admin/services/analytics_service.dart';
import 'package:kolisa_admin/admin/services/clients_service.dart';

void main() {
  setUpAll(() async {
    // Initialiser Supabase pour les tests
    await Supabase.initialize(
      url: 'https://iubqntlugpwormuzefga.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml1YnFudGx1Z3B3b3JtdXplZmdhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIxNDQ1MTEsImV4cCI6MjA2NzcyMDUxMX0.XvZ6e_2Q9UILZ2gASdh1a_VJk3xqWYoMZFxLhJXJX1M',
    );
  });

  group('Admin Panel Tests avec données réelles', () {
    testWidgets('Application se charge avec Supabase', (WidgetTester tester) async {
      await tester.pumpWidget(const KolisaAdminApp());
      await tester.pumpAndSettle();
      
      // Vérifier que l'app se charge sans crash
      expect(tester.takeException(), isNull);
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Service Analytics - Métriques utilisateurs', (WidgetTester tester) async {
      // Test du service Analytics avec vraies données Supabase
      final userMetrics = await AnalyticsService.getUserMetrics();
      
      expect(userMetrics, isA<Map<String, dynamic>>());
      expect(userMetrics.containsKey('totalUsers'), isTrue);
      expect(userMetrics.containsKey('newUsersToday'), isTrue);
      expect(userMetrics.containsKey('activeUsersToday'), isTrue);
      
      // Vérifier que les données sont numériques
      expect(userMetrics['totalUsers'], isA<int>());
      expect(userMetrics['newUsersToday'], isA<int>());
      expect(userMetrics['activeUsersToday'], isA<int>());
    });

    testWidgets('Service Clients récupère vrais profils', (WidgetTester tester) async {
      // Test du service Clients avec vraies données
      final clients = await ClientsService.getClientsWithPresence();
      
      expect(clients, isA<List<Map<String, dynamic>>>());
      
      if (clients.isNotEmpty) {
        final client = clients.first;
        expect(client.containsKey('id'), isTrue);
        expect(client.containsKey('fullname'), isTrue);
        expect(client.containsKey('role'), isTrue);
        expect(client['role'], equals('client'));
      }
    });

    testWidgets('Service Analytics - Métriques revenus', (WidgetTester tester) async {
      // Test des métriques revenus en temps réel
      final revenueMetrics = await AnalyticsService.getRevenueMetrics();
      
      expect(revenueMetrics, isA<Map<String, dynamic>>());
      expect(revenueMetrics.containsKey('totalRevenue'), isTrue);
      expect(revenueMetrics.containsKey('revenueToday'), isTrue);
      expect(revenueMetrics.containsKey('revenueThisWeek'), isTrue);
      
      // Vérifier que les revenus sont des nombres valides
      expect(revenueMetrics['totalRevenue'], isA<double>());
      expect(revenueMetrics['revenueToday'], isA<double>());
      expect(revenueMetrics['revenueThisWeek'], isA<double>());
    });

    testWidgets('Service Analytics - Métriques missions', (WidgetTester tester) async {
      // Test de cohérence des données missions
      final missionMetrics = await AnalyticsService.getMissionMetrics();
      
      expect(missionMetrics, isA<Map<String, dynamic>>());
      expect(missionMetrics.containsKey('totalMissions'), isTrue);
      expect(missionMetrics.containsKey('missionsToday'), isTrue);
      expect(missionMetrics.containsKey('completedMissions'), isTrue);
      
      final totalMissions = missionMetrics['totalMissions'] as int;
      final completedMissions = missionMetrics['completedMissions'] as int;
      
      // Vérifier la cohérence logique
      expect(totalMissions, greaterThanOrEqualTo(0));
      expect(completedMissions, greaterThanOrEqualTo(0));
      expect(completedMissions, lessThanOrEqualTo(totalMissions));
    });
  });
}
