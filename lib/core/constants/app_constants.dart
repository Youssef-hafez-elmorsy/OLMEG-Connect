class AppConstants {
  AppConstants._();

  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String postsCollection = 'posts';
  static const String chatsCollection = 'chats';

  static const String categoryNew = 'New';
  static const String categoryUsed = 'Used';
  static const String categoryHandmade = 'Handmade';

  static const List<String> categories = [
    categoryNew,
    categoryUsed,
    categoryHandmade,
  ];

  static const String productImagesPath = 'product_images';
  static const String userAvatarsPath = 'user_avatars';
  static const String postImagesPath = 'post_images';

  static const String appWebBaseUrl = 'https://olmeg-connect.web.app';

  static String postShareUrl(String postId) => '$appWebBaseUrl/posts/$postId';
  static String productShareUrl(String productId) =>
      '$appWebBaseUrl/#/product/$productId';
  static String feedShareUrl() => '$appWebBaseUrl/#/home';
}
