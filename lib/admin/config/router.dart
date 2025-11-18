import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/login_screen.dart';
import '../screens/main_admin_screen.dart';
import '../screens/submissions_list_screen.dart';
import '../screens/submission_detail_screen.dart';
import '../screens/drivers_monitoring_screen.dart';
import '../screens/driver_profile_screen.dart';
import '../screens/clients_monitor_screen.dart';
import '../screens/map_tracking_screen.dart';
import '../screens/reports_management_screen.dart';
import '../screens/user_blocks_screen.dart';
import '../screens/client_profile_screen.dart';
import '../widgets/maintenance_wrapper.dart';

final GoRouter adminRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;
    
    if (session == null && state.matchedLocation != '/login') {
      return '/login';
    }
    
    if (session != null && state.matchedLocation == '/login') {
      return '/';
    }
    
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const MaintenanceWrapper(
        child: MainAdminScreen(),
      ),
    ),
    GoRoute(
      path: '/submissions',
      builder: (context, state) => const SubmissionsListScreen(),
    ),
    GoRoute(
      path: '/submissions/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return SubmissionDetailScreen(id: id);
      },
    ),
    GoRoute(
      path: '/drivers',
      builder: (context, state) => const DriversMonitoringScreen(),
    ),
    GoRoute(
      path: '/drivers/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return DriverProfileScreen(id: id);
      },
    ),
    GoRoute(
      path: '/clients-monitor',
      builder: (context, state) => const ClientsMonitorScreen(),
    ),
    GoRoute(
      path: '/map-tracking',
      builder: (context, state) => const MapTrackingScreen(),
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) => const ReportsManagementScreen(),
    ),
    GoRoute(
      path: '/user-blocks',
      builder: (context, state) => const UserBlocksScreen(),
    ),
    GoRoute(
      path: '/clients/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ClientProfileScreen(id: id);
      },
    ),
  ],
);
