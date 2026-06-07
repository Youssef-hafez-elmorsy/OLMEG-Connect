import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:olmeg_connect/core/widgets/app_state_widgets.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/products/domain/entities/product_entity.dart';
import '../../features/products/presentation/providers/product_provider.dart';
import '../../features/cart/presentation/screens/checkout_review_screen.dart';
import '../../features/products/presentation/screens/product_detail_screen.dart';
import '../../features/products/presentation/screens/cart_screen.dart';
import '../../features/posts/screens/create_post_screen.dart';
import '../../features/posts/screens/demo_screen.dart';
import '../../features/shell/presentation/main_shell.dart';
import '../../features/chat/data/models/chat_model.dart';
import '../../features/chat/presentation/screens/chat_list_screen.dart';
import '../../features/chat/presentation/screens/chat_detail_screen.dart';
import '../../features/chat/presentation/providers/chat_provider.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/favorites_screen.dart';
import '../../features/profile/presentation/screens/my_products_screen.dart';
import '../../features/profile/presentation/screens/privacy_policy_screen.dart';
import '../../features/profile/presentation/screens/terms_of_service_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/address_book_screen.dart';
import '../../features/home/presentation/screens/search_screen.dart';
import '../../features/search/presentation/screens/advanced_search_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/orders/presentation/screens/order_list_screen.dart';
import '../../features/payments/presentation/screens/paymob_payment_result_screen.dart';
import '../../features/seller/presentation/screens/seller_dashboard_screen.dart';
import '../../features/seller/presentation/screens/seller_inventory_screen.dart';
import '../../features/seller/presentation/screens/seller_order_queue_screen.dart';
import '../../features/seller/presentation/screens/seller_storefront_screen.dart';
import '../../features/seller/presentation/screens/seller_bulk_tools_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final notifierState = ref.read(authNotifierProvider).value;
      final streamState = ref.read(authStateProvider).value;

      final currentUser = notifierState ?? streamState;
      final isLoggedIn = currentUser != null;
      final isSellerRoute = state.matchedLocation == '/seller' ||
          state.matchedLocation.startsWith('/seller/');
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/home';
      if (isSellerRoute &&
          currentUser?.isAdmin != true &&
          currentUser?.isApprovedMerchant != true) {
        return '/home';
      }
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
          final product = state.extra;
          return _ProductRouteScreen(
            productId: state.pathParameters['id']!,
            initialProduct: product is ProductEntity ? product : null,
          );
        },
      ),
      GoRoute(
        path: '/cart',
        builder: (_, __) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (_, __) => const CheckoutReviewScreen(),
      ),
      GoRoute(
        path: '/payment-result',
        builder: (context, state) {
          final query = state.uri.queryParameters;
          final orderId = query['orderId'] ??
              query['merchant_order_id'] ??
              query['special_reference'] ??
              query['merchant_intention_id'];
          return PaymobPaymentResultScreen(
            orderId: orderId,
            gatewayStatus: query['status'] ?? query['success'],
          );
        },
      ),
      GoRoute(
        path: '/orders',
        builder: (_, __) => const OrderListScreen(),
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (context, state) {
          return OrderDetailScreen(orderId: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/seller',
        builder: (_, __) => const SellerDashboardScreen(),
      ),
      GoRoute(
        path: '/seller/inventory',
        builder: (_, __) => const SellerInventoryScreen(),
      ),
      GoRoute(
        path: '/seller/orders',
        builder: (_, __) => const SellerOrderQueueScreen(),
      ),
      GoRoute(
        path: '/seller/storefront',
        builder: (_, __) => const SellerStorefrontScreen(),
      ),
      GoRoute(
        path: '/seller/bulk-tools',
        builder: (_, __) => const SellerBulkToolsScreen(),
      ),
      GoRoute(
        path: '/create-post',
        builder: (_, __) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/demo',
        builder: (_, __) => const DemoScreen(),
      ),
      GoRoute(
        path: '/chats',
        builder: (_, __) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final chat = state.extra;
          return _ChatRouteScreen(
            chatId: state.pathParameters['id']!,
            initialChat: chat is ChatModel ? chat : null,
          );
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const UserProfileScreen(),
      ),
      GoRoute(
        path: '/favorites',
        builder: (_, __) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/my-products',
        builder: (_, __) => const MyProductsScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (_, __) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/terms',
        builder: (_, __) => const TermsOfServiceScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/addresses',
        builder: (_, __) => const AddressBookScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (_, __) => const SearchScreen(),
      ),
      GoRoute(
        path: '/advanced-search',
        builder: (_, __) => const AdvancedSearchScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
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

class _ProductRouteScreen extends ConsumerWidget {
  final String productId;
  final ProductEntity? initialProduct;

  const _ProductRouteScreen({
    required this.productId,
    required this.initialProduct,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = initialProduct;
    if (product != null) {
      return ProductDetailScreen(product: product);
    }

    final productAsync = ref.watch(productByIdProvider(productId));
    return productAsync.when(
      loading: () => const Scaffold(
        body: AppLoadingState(label: 'Loading product'),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: const Text('Product')),
        body: AppErrorState(
          title: 'Could not load product',
          message: 'This product link could not be opened. Please try again.',
          onRetry: () => ref.invalidate(productByIdProvider(productId)),
        ),
      ),
      data: (product) {
        if (product == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Product')),
            body: AppEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Product not found',
              message:
                  'This product may have been removed or is no longer public.',
              action: FilledButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Back to marketplace'),
              ),
            ),
          );
        }
        return ProductDetailScreen(product: product);
      },
    );
  }
}

class _ChatRouteScreen extends ConsumerWidget {
  final String chatId;
  final ChatModel? initialChat;

  const _ChatRouteScreen({
    required this.chatId,
    required this.initialChat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chat = initialChat;
    if (chat != null) {
      return ChatDetailScreen(chat: chat);
    }

    final chatAsync = ref.watch(chatByIdProvider(chatId));
    return chatAsync.when(
      loading: () => const Scaffold(
        body: AppLoadingState(label: 'Loading conversation'),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: const Text('Conversation')),
        body: AppErrorState(
          title: 'Could not load conversation',
          message:
              'This conversation link could not be opened. Please try again.',
          onRetry: () => ref.invalidate(chatByIdProvider(chatId)),
        ),
      ),
      data: (chat) {
        if (chat == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Conversation')),
            body: AppEmptyState(
              icon: Icons.chat_bubble_outline,
              title: 'Conversation not found',
              message:
                  'This chat may have been deleted, hidden, or unavailable to your account.',
              action: FilledButton.icon(
                onPressed: () => context.go('/chats'),
                icon: const Icon(Icons.forum_outlined),
                label: const Text('Back to chats'),
              ),
            ),
          );
        }
        return ChatDetailScreen(chat: chat);
      },
    );
  }
}
