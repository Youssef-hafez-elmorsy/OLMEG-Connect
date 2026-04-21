import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/products/domain/entities/product_entity.dart';
import '../../features/products/presentation/screens/product_detail_screen.dart';
import '../../features/posts/presentation/screens/create_post_screen.dart';
import '../../features/shell/presentation/main_shell.dart';
import '../../features/chat/data/models/chat_model.dart';
import '../../features/chat/presentation/screens/chat_list_screen.dart';
import '../../features/chat/presentation/screens/chat_detail_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final notifierState = ref.read(authNotifierProvider).value;
      final streamState = ref.read(authStateProvider).value;
      
      final isLoggedIn = (notifierState != null) || (streamState != null);
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      print('[Router] Location: ${state.matchedLocation}, isLoggedIn: $isLoggedIn');

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    refreshListenable: GoRouterRefreshStream(ref),
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/home',
        builder: (_, __) => const MainShell(),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final product = state.extra as ProductEntity;
          return ProductDetailScreen(product: product);
        },
      ),
      GoRoute(
        path: '/create-post',
        builder: (_, __) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/chats',
        builder: (_, __) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final chat = state.extra as ChatModel;
          return ChatDetailScreen(chat: chat);
        },
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    ref.listen(authStateProvider, (_, __) {
      notifyListeners();
    });
  }
}