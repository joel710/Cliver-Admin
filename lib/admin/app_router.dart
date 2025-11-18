import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/main_admin_screen.dart';
import 'screens/submission_detail_screen.dart';
import 'screens/driver_profile_screen.dart';
import 'screens/map_tracking_screen.dart';
import 'screens/clients_monitor_screen.dart';
import 'screens/reports_management_screen.dart';
import 'screens/client_profile_screen.dart';
import 'screens/support_dashboard_screen.dart';
import 'screens/drivers_monitoring_screen.dart';

final adminRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;
    final loggingIn = state.fullPath == '/login';

    if (session == null) {
      return loggingIn ? null : '/login';
    }

    final uid = session.user.id;
    final data = await client
        .from('user_profiles')
        .select('is_admin')
        .eq('id', uid)
        .maybeSingle();
    final isAdmin = data != null && data['is_admin'] == true;

    if (!isAdmin && !loggingIn) return '/login';
    if (isAdmin && loggingIn) return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, __) => const MainAdminScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(
      path: '/submissions/:id',
      builder: (ctx, st) =>
          SubmissionDetailScreen(id: st.pathParameters['id']!),
    ),
    GoRoute(
      path: '/drivers/:id',
      builder: (ctx, st) => DriverProfileScreen(id: st.pathParameters['id']!),
    ),
    GoRoute(
      path: '/clients/:id',
      builder: (ctx, st) => ClientProfileScreen(id: st.pathParameters['id']!),
    ),
    GoRoute(
      path: '/map-tracking',
      builder: (_, __) => const MapTrackingScreen(),
    ),
    GoRoute(
      path: '/clients-monitor',
      builder: (_, __) => const ClientsMonitorScreen(),
    ),
    GoRoute(
      path: '/drivers-monitor',
      builder: (_, __) => const DriversMonitoringScreen(),
    ),
    GoRoute(
      path: '/reports',
      builder: (_, __) => const ReportsManagementScreen(),
    ),
    GoRoute(
      path: '/support',
      builder: (_, __) => const SupportDashboardScreen(),
    ),
  ],
);
