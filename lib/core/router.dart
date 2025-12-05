import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/home/home_screen.dart';
import '../features/home/party_type_screen.dart';
import '../features/home/provider_home_screen.dart';
import '../features/requests/my_requests_screen.dart';
import '../features/requests/request_detail_screen.dart';
import '../features/requests/service_request_screen.dart';
import '../features/requests/provider_requests_screen.dart';
import '../features/chat/chat_list_screen.dart';
import '../features/chat/chat_detail_screen.dart';
import '../features/profile/client_profile_screen.dart';
import '../features/profile/provider_profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final userProfileAsync = ref.watch(userProfileProvider);
  
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/provider-home',
        builder: (context, state) => const ProviderHomeScreen(),
      ),
      GoRoute(
        path: '/party-type',
        builder: (context, state) => const PartyTypeScreen(),
      ),
      GoRoute(
        path: '/my-requests',
        builder: (context, state) => const MyRequestsScreen(),
      ),
      GoRoute(
        path: '/provider-requests',
        builder: (context, state) => const ProviderRequestsScreen(),
      ),
      GoRoute(
        path: '/service-request',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ServiceRequestScreen(
            id: extra?['id'],
            categoryId: extra?['categoryId'],
            categoryName: extra?['categoryName'],
            description: extra?['description'],
            eventDate: extra?['eventDate'],
            eventTime: extra?['eventTime'],
            location: extra?['location'],
            guestCount: extra?['guestCount'],
          );
        },
      ),
      GoRoute(
        path: '/request-detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return RequestDetailScreen(requestId: id);
        },
      ),
      GoRoute(
        path: '/chats',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ChatListScreen(requestId: extra?['requestId']);
        },
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ChatDetailScreen(channelId: id);
        },
      ),
      GoRoute(
        path: '/client-profile',
        builder: (context, state) => const ClientProfileScreen(),
      ),
      GoRoute(
        path: '/provider-profile',
        builder: (context, state) => const ProviderProfileScreen(),
      ),
    ],
    redirect: (context, state) {
      final session = authState.value?.session;
      final isLoggingIn = state.uri.path == '/login';
      final isRegistering = state.uri.path == '/register';

      if (session == null) {
        if (!isLoggingIn && !isRegistering) return '/login';
        return null;
      }

      if (isLoggingIn || isRegistering) return '/';

      if (state.uri.path == '/') {
        if (userProfileAsync.isLoading) return null;
        
        final profile = userProfileAsync.value;
        if (profile != null) {
          final role = profile['role'];
          if (role == 'provider') {
            return '/provider-home';
          } else {
            return '/party-type';
          }
        }
      }

      return null;
    },
  );
});
