import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  bool get isArabic => locale.languageCode == 'ar';

  String get appName => 'Olmeg Connect';
  String get marketplaceTagline => isArabic
      ? 'كل ما تحتاجه في مكان واحد'
      : 'Everything you need in one place';
  String get welcomeBack => isArabic ? 'مرحباً بعودتك' : 'Welcome back';
  String get signInToAccount =>
      isArabic ? 'سجل الدخول إلى حسابك' : 'Sign in to your account';
  String get email => isArabic ? 'البريد الإلكتروني' : 'Email';
  String get emailHint => 'you@example.com';
  String get emailRequired =>
      isArabic ? 'البريد الإلكتروني مطلوب' : 'Email is required';
  String get validEmail =>
      isArabic ? 'أدخل بريداً إلكترونياً صحيحاً' : 'Enter a valid email';
  String get password => isArabic ? 'كلمة المرور' : 'Password';
  String get passwordRequired =>
      isArabic ? 'كلمة المرور مطلوبة' : 'Password is required';
  String get passwordTooShort => isArabic
      ? 'يجب أن تكون كلمة المرور 6 أحرف على الأقل'
      : 'Password must be at least 6 characters';
  String get signIn => isArabic ? 'تسجيل الدخول' : 'Sign In';
  String get noAccount =>
      isArabic ? 'ليس لديك حساب؟ ' : "Don't have an account? ";
  String get signUp => isArabic ? 'إنشاء حساب' : 'Sign Up';

  String get home => isArabic ? 'الرئيسية' : 'Home';
  String get feed => isArabic ? 'المنشورات' : 'Feed';
  String get chat => isArabic ? 'الدردشة' : 'Chat';
  String get notify => isArabic ? 'الإشعارات' : 'Notify';
  String get profile => isArabic ? 'الملف الشخصي' : 'Profile';

  String hello(String name) => isArabic ? 'مرحباً، $name' : 'Hello, $name';
  String get there => isArabic ? 'صديقي' : 'there';
  String get all => isArabic ? 'الكل' : 'All';
  String get failedToLoad => isArabic ? 'تعذر التحميل' : 'Failed to load';
  String get noProductsFound =>
      isArabic ? 'لا توجد منتجات' : 'No products found';
  String get firstProductPrompt =>
      isArabic ? 'كن أول من يضيف منتجاً!' : 'Be the first to list a product!';
  String noCategoryProducts(String category) => isArabic
      ? 'لا توجد منتجات في $category بعد'
      : 'No $category products yet';
  String get deleteProduct => isArabic ? 'حذف المنتج' : 'Delete Product';
  String deleteProductQuestion(String title) =>
      isArabic ? 'هل تريد حذف "$title"؟' : 'Delete "$title"?';
  String get productDeleted => isArabic ? 'تم حذف المنتج' : 'Product deleted';
  String get signInForFavorites => isArabic
      ? 'يرجى تسجيل الدخول لإضافة المفضلة'
      : 'Please sign in to add favorites';
  String get removedFromFavorites =>
      isArabic ? 'تمت الإزالة من المفضلة' : 'Removed from favorites';
  String get addedToFavorites =>
      isArabic ? 'تمت الإضافة إلى المفضلة' : 'Added to favorites';

  String get settings => isArabic ? 'الإعدادات' : 'Settings';
  String get lightMode => isArabic ? 'الوضع الفاتح' : 'Light Mode';
  String get language => isArabic ? 'اللغة' : 'Language';
  String get english => isArabic ? 'الإنجليزية' : 'English';
  String get arabic => 'العربية';
  String get selectLanguage => isArabic ? 'اختر اللغة' : 'Select Language';
  String get notifications => isArabic ? 'الإشعارات' : 'Notifications';
  String get privacyPolicy => isArabic ? 'سياسة الخصوصية' : 'Privacy Policy';
  String get termsOfService => isArabic ? 'شروط الخدمة' : 'Terms of Service';
  String get about => isArabic ? 'حول التطبيق' : 'About';
  String get version => isArabic ? 'الإصدار 2.1.0' : 'Version 2.1.0';

  String get products => isArabic ? 'المنتجات' : 'Products';
  String get sold => isArabic ? 'المبيعات' : 'Sold';
  String get rating => isArabic ? 'التقييم' : 'Rating';
  String get guest => isArabic ? 'زائر' : 'Guest';
  String get myProducts => isArabic ? 'منتجاتي' : 'My Products';
  String get favorites => isArabic ? 'المفضلة' : 'Favorites';
  String get orderHistory => isArabic ? 'سجل الطلبات' : 'Order History';
  String get helpSupport => isArabic ? 'المساعدة والدعم' : 'Help & Support';
  String get deleteAccount => isArabic ? 'حذف الحساب' : 'Delete Account';
  String get signOut => isArabic ? 'تسجيل الخروج' : 'Sign Out';
  String get deleteAccountQuestion =>
      isArabic ? 'حذف الحساب؟' : 'Delete Account?';
  String get deleteAccountWarning => isArabic
      ? 'سيتم حذف حسابك وكل بياناتك نهائياً. لا يمكن التراجع عن هذا الإجراء.'
      : 'This will permanently delete your account and all data. This action cannot be undone.';
  String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  String get delete => isArabic ? 'حذف' : 'Delete';
  String errorDeletingAccount(Object error) => isArabic
      ? 'حدث خطأ أثناء حذف الحساب: $error'
      : 'Error deleting account: $error';

  String t(String key) {
    final en = _en[key];
    if (!isArabic) return en ?? key;
    return _ar[key] ?? en ?? key;
  }

  String categoryLabel(String value) => _label('category', value);
  String subcategoryLabel(String value) => _label('subcategory', value);

  String postTypeLabel(String value) {
    final normalized = value.trim().toLowerCase();
    return switch (normalized) {
      'made' => t('made'),
      'wanted' => t('wanted'),
      'all' => all,
      _ => value,
    };
  }

  String noPostsYet(String filter) =>
      isArabic ? 'لا توجد منشورات $filter بعد' : 'No $filter posts yet';

  String chatStats(int total, int buying, int selling) => isArabic
      ? '$total محادثة • $buying شراء • $selling بيع'
      : '$total conversations • $buying buying • $selling selling';

  String noChatsMatch(String query) =>
      isArabic ? 'لا توجد محادثات تطابق "$query"' : 'No chats match "$query"';

  String emptyConversationMessage(String user) => isArabic
      ? 'ابدأ المحادثة مع $user وتأكد من التفاصيل قبل الشراء أو البيع.'
      : 'Say hello to $user and confirm details before you buy or sell.';

  String activeItemsReady(int count) => isArabic
      ? '$count عنصر نشط جاهز للمراجعة'
      : '$count active item${count == 1 ? '' : 's'} ready for review';

  String sellerName(String name) =>
      isArabic ? 'البائع: $name' : 'Seller: $name';

  String variantName(String name) =>
      isArabic ? 'الخيار: $name' : 'Variant: $name';

  String onlyAvailable(int count) =>
      isArabic ? 'متاح $count فقط' : 'Only $count available';

  String cartQuantityIssue(String title, int count) => isArabic
      ? '$title متاح منه $count فقط.'
      : '$title has only $count available.';

  String cartUnavailable(String title) =>
      isArabic ? '$title لم يعد متاحاً.' : '$title is no longer available.';

  String cartPriceChanged(String title) =>
      isArabic ? 'تغير سعر $title.' : '$title price changed.';

  String cartNotSellable(String title) => isArabic
      ? '$title غير متاح للبيع حالياً.'
      : '$title is not currently sellable.';

  String postMoreComments(int count) =>
      isArabic ? 'عرض $count تعليقات أخرى' : 'View $count more comments';

  String errorWithMessage(Object error) =>
      isArabic ? 'خطأ: $error' : 'Error: $error';

  String _label(String prefix, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    final key = '${prefix}_${_normalizeLabel(trimmed)}';
    final en = _en[key];
    if (!isArabic) return en ?? trimmed;
    return _ar[key] ?? en ?? trimmed;
  }

  static String _normalizeLabel(String value) {
    return value
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  static const Map<String, String> _en = {
    'sponsored': 'Sponsored',
    'deals': 'Deals',
    'topRated': 'Top rated',
    'aiPicks': 'AI picks',
    'recommendedForYou': 'Recommended for you',
    'recentlyViewed': 'Recently viewed',
    'sponsoredSubtitle': 'Paid placements from active sellers',
    'dealsSubtitle': 'Discounts and limited-time offers',
    'topRatedSubtitle': 'Products with stronger buyer signals',
    'aiPicksSubtitle':
        'Ranked from your marketplace signals and current supply',
    'recommendedSubtitle': 'Personalized from recent marketplace activity',
    'recentlyViewedSubtitle': 'Pick up where you left off',
    'curatedProducts': 'Curated marketplace products',
    'marketplacePicks': 'Marketplace picks',
    'findRightDeal': 'Find the right deal',
    'homeHeroMessage':
        'Browse handmade, new, and used products with clearer delivery, stock, and seller trust signals.',
    'trustedSellers': 'Trusted sellers',
    'deliveryReadyItems': 'Delivery-ready items',
    'chatBeforeBuying': 'Chat before buying',
    'openCart': 'Open cart',
    'deliveryReady': 'Delivery ready',
    'contactSeller': 'Contact seller',
    'inStock': 'in stock',
    'outOfStock': 'Out of stock',
    'marketplaceSeller': 'Marketplace seller',
    'verifiedSeller': 'Verified seller',
    'sellerProfile': 'Seller profile',
    'uncategorized': 'Uncategorized',
    'noImage': 'No image',
    'imageUnavailable': 'Image unavailable',
    'myCart': 'My Cart',
    'cart': 'Cart',
    'cartEmptyTitle': 'Your cart is ready for great finds',
    'cartEmptyMessage':
        'Add delivery-ready products to compare totals, shipping, and checkout next steps in one place.',
    'browseMarketplace': 'Browse marketplace',
    'cartSummary': 'Cart summary',
    'subtotal': 'Subtotal:',
    'reviewCheckoutSecurely': 'Review checkout securely',
    'recommendedAddOns': 'Recommended add-ons',
    'moveToCart': 'Move to cart',
    'saveForLater': 'Save for later',
    'communityPosts': 'Community posts',
    'communityPostsMessage':
        'Share finds, requests, repairs, and handmade work with the marketplace.',
    'create': 'Create',
    'createPost': 'Create post',
    'myPosts': 'My posts',
    'made': 'Made',
    'wanted': 'Wanted',
    'postPrompt': 'Post an item, request, or update...',
    'errorLoadingPosts': 'Error loading posts',
    'retry': 'Retry',
    'emptyPostMessage':
        'Be the first to share something useful with the community.',
    'seeMore': 'See more',
    'savePost': 'Save Post',
    'copyLink': 'Copy Link',
    'reportPost': 'Report Post',
    'share': 'Share',
    'like': 'Like',
    'liked': 'Liked',
    'comment': 'Comment',
    'pleaseSignInToChat': 'Please sign in to chat',
    'youOwnThisPost': 'You own this post',
    'postChat': 'Post chat',
    'deleteThisPost': 'Delete this post?',
    'cannotBeUndone': 'This cannot be undone.',
    'postDeletedSuccessfully': 'Post deleted successfully',
    'linkCopied': 'Link copied!',
    'postReported': 'Post reported',
    'shareNow': 'Share Now',
    'linkCopiedToClipboard': 'Link copied to clipboard!',
    'commentAdded': 'Comment added!',
    'pleaseSignIn': 'Please sign in',
    'startConversation': 'Start a conversation',
    'deleteConversation': 'Delete conversation',
    'deleteConversationQuestion': 'Delete conversation?',
    'deleteConversationHelp':
        'This removes the conversation from your inbox only.',
    'conversationDeleted': 'Conversation deleted from your inbox.',
    'couldNotDeleteConversation': 'Could not delete conversation',
    'couldNotLoadMessages': 'Could not load messages',
    'noMessagesYet': 'No messages yet',
    'contactSellerToStart':
        'Contact a seller from a product page to start a conversation.',
    'hideConversation': 'Hide conversation from my inbox',
    'otherKeepsConversation': 'The other participant will still keep it.',
    'conversationHidden': 'Conversation hidden from your inbox.',
    'attachmentsUnavailable': 'Attachments are not available in chat yet.',
    'conversationOptions': 'Conversation options',
    'muteConversation': 'Mute conversation',
    'unmuteConversation': 'Unmute conversation',
    'muteConversationHelp': 'Notifications are changed only for your account.',
    'conversationMuted': 'Conversation muted.',
    'conversationUnmuted': 'Conversation unmuted.',
    'blockConversation': 'Block conversation',
    'unblockConversation': 'Unblock',
    'blockConversationHelp':
        'Blocks new messages and unsafe notifications for your account.',
    'conversationBlocked': 'Conversation blocked.',
    'conversationUnblocked': 'Conversation unblocked.',
    'blockedNotice': 'You blocked this conversation.',
    'reportConversation': 'Report conversation',
    'reportConversationHelp': 'Send safety evidence to the operations team.',
    'reportReason': 'Reason',
    'reportDescriptionOptional': 'Description (optional)',
    'submitReport': 'Submit report',
    'conversationReported': 'Report submitted.',
    'addAttachment': 'Add attachment',
    'typeMessage': 'Type a message...',
    'send': 'Send',
    'couldNotLoadConversation': 'Could not load conversation',
    'notificationsTitle': 'Notifications',
    'signInNotifications': 'Please sign in to view notifications',
    'noNotificationsYet': 'No notifications yet',
    'category_new': 'New',
    'category_used': 'Used',
    'category_handicraft': 'Handicraft',
    'category_jewelry': 'Jewelry',
    'category_electronics': 'Electronics',
    'category_clothing': 'Clothing',
    'category_home': 'Home',
    'category_sports': 'Sports',
    'category_books': 'Books',
    'category_toys': 'Toys',
    'category_furniture': 'Furniture',
    'category_cars': 'Cars',
    'category_bikes': 'Bikes',
    'category_fashion': 'Fashion',
    'category_beauty': 'Beauty',
    'category_other': 'Other',
    'subcategory_electronics': 'Electronics',
    'subcategory_clothing': 'Clothing',
    'subcategory_furniture': 'Furniture',
    'subcategory_sports': 'Sports',
    'subcategory_books': 'Books',
    'subcategory_toys': 'Toys',
    'subcategory_cars': 'Cars',
    'subcategory_bikes': 'Bikes',
    'subcategory_jewelry': 'Jewelry',
    'subcategory_home_and_garden': 'Home & Garden',
    'subcategory_fashion': 'Fashion',
    'subcategory_beauty': 'Beauty',
    'subcategory_other': 'Other',
    'subcategory_pottery': 'Pottery',
    'subcategory_textiles': 'Textiles',
    'subcategory_woodwork': 'Woodwork',
    'subcategory_paintings': 'Paintings',
    'subcategory_candles': 'Candles',
    'subcategory_knitting': 'Knitting',
    'subcategory_embroidery': 'Embroidery',
    'subcategory_rings': 'Rings',
    'subcategory_necklaces': 'Necklaces',
    'subcategory_bracelets': 'Bracelets',
    'subcategory_earrings': 'Earrings',
    'subcategory_watches': 'Watches',
    'subcategory_pendants': 'Pendants',
    'subcategory_anklets': 'Anklets',
    'addProduct': 'List a Product',
    'tapToAddImages': 'Tap to add images',
    'selectMultiple': 'Select multiple',
    'productTitle': 'Product Title',
    'description': 'Description',
    'price': 'Price',
    'quantity': 'Quantity',
    'location': 'Location',
    'cityOrArea': 'City or area',
    'locationHint': 'Example: Cairo, Nasr City',
    'category': 'Category',
    'subcategory': 'Subcategory',
    'categoryRequired': 'Please select a category',
    'subcategoryRequired': 'Please select a subcategory',
    'imageRequired': 'Please select a product image',
    'locationRequired': 'Please add product location',
    'signInFirst': 'Please sign in first',
    'titleRequired': 'Title is required',
    'descriptionRequired': 'Description is required',
    'priceRequired': 'Price is required',
    'validNumber': 'Enter a valid number',
    'saveAsDraft': 'Save as draft',
    'draftSubtitle': 'Drafts stay out of public product discovery.',
    'scheduleTomorrow': 'Schedule for tomorrow',
    'scheduleSubtitle': 'Stores a scheduled publish time for seller planning.',
    'listProduct': 'List Product',
    'listingQuality': 'Listing quality',
    'clearTitle': 'Clear title',
    'helpfulDescription': 'Helpful description',
    'validPrice': 'Valid price',
    'atLeastOneImage': 'At least one image',
    'stockQuantitySet': 'Stock quantity set',
    'locationAdded': 'Location added',
    'loadingCategories': 'Loading categories...',
    'noCategoriesFound': 'No categories found',
    'initializeCategories': 'Initialize Categories',
    'selectCategory': 'Select Category',
    'selectCategoryFirst': 'Select Category First',
    'selectSubcategory': 'Select Subcategory',
    'noSubcategories': 'No subcategories available',
    'categoriesInitialized': 'Categories initialized!',
    'productApproved': 'Product approved',
    'productApprovedScheduled':
        'Product approved and scheduled for publishing.',
    'productApprovedListed': 'Product approved and listed successfully!',
    'productSavedDraft': 'Product saved as draft.',
    'productSentReview': 'Product sent to admin review before publication.',
    'editProfile': 'Edit profile',
    'save': 'Save',
    'fullName': 'Full name',
    'bio': 'Bio',
    'profileSaved': 'Profile saved',
    'choosePhoto': 'Choose photo',
    'remove': 'Remove',
    'profilePhoto': 'Profile photo',
    'profilePhotoHelp':
        'This photo appears on your profile, posts, and marketplace activity.',
    'searchProducts': 'Search products...',
    'searchForProducts': 'Search for products',
    'messages': 'Messages',
    'refresh': 'Refresh',
    'marketplaceInbox': 'Marketplace inbox',
    'conversationStats': 'conversations',
    'buying': 'buying',
    'selling': 'selling',
    'searchMessages': 'Search products, people, messages',
    'comments': 'Comments',
    'noCommentsYet': 'No comments yet',
    'writeComment': 'Write a comment...',
    'sendComment': 'Send comment',
    'signInToComment': 'Please sign in to comment',
    'advancedSearch': 'Advanced Search',
    'saveSearchAlert': 'Save search alert',
    'minPrice': 'Min Price',
    'maxPrice': 'Max Price',
    'city': 'City',
    'availableNow': 'Available now',
    'minimumRating': 'Minimum rating',
    'condition': 'Condition',
    'sortBy': 'Sort By',
    'promoteSponsor': 'Promote / Sponsor',
    'createOffer': 'Create Offer',
    'sponsorPost': 'Sponsor Post',
    'deletePost': 'Delete Post',
  };

  static const Map<String, String> _ar = {
    'sponsored': 'إعلانات ممولة',
    'deals': 'العروض',
    'topRated': 'الأعلى تقييماً',
    'recommendedForYou': 'مقترح لك',
    'recentlyViewed': 'شوهدت مؤخراً',
    'sponsoredSubtitle': 'مساحات مدفوعة من بائعين نشطين',
    'dealsSubtitle': 'خصومات وعروض لفترة محدودة',
    'topRatedSubtitle': 'منتجات لديها إشارات ثقة أفضل',
    'recommendedSubtitle': 'اختيارات حسب نشاطك الأخير في السوق',
    'recentlyViewedSubtitle': 'تابع من حيث توقفت',
    'curatedProducts': 'منتجات مختارة من السوق',
    'marketplacePicks': 'اختيارات السوق',
    'findRightDeal': 'اعثر على العرض المناسب',
    'homeHeroMessage':
        'تصفح المنتجات اليدوية والجديدة والمستعملة مع معلومات أوضح عن التوصيل والمخزون وثقة البائع.',
    'trustedSellers': 'بائعون موثوقون',
    'deliveryReadyItems': 'منتجات جاهزة للتوصيل',
    'chatBeforeBuying': 'راسل قبل الشراء',
    'openCart': 'فتح السلة',
    'deliveryReady': 'جاهز للتوصيل',
    'contactSeller': 'تواصل مع البائع',
    'inStock': 'في المخزون',
    'outOfStock': 'غير متوفر',
    'marketplaceSeller': 'بائع في السوق',
    'verifiedSeller': 'بائع موثق',
    'sellerProfile': 'ملف البائع',
    'uncategorized': 'غير مصنف',
    'noImage': 'لا توجد صورة',
    'imageUnavailable': 'الصورة غير متاحة',
    'myCart': 'سلتي',
    'cart': 'السلة',
    'cartEmptyTitle': 'سلتك جاهزة لاكتشافات رائعة',
    'cartEmptyMessage':
        'أضف منتجات جاهزة للتوصيل لمقارنة الإجمالي والشحن وخطوات الدفع في مكان واحد.',
    'browseMarketplace': 'تصفح السوق',
    'cartSummary': 'ملخص السلة',
    'subtotal': 'الإجمالي الفرعي:',
    'reviewCheckoutSecurely': 'مراجعة الدفع بأمان',
    'recommendedAddOns': 'إضافات مقترحة',
    'moveToCart': 'نقل إلى السلة',
    'saveForLater': 'حفظ لوقت لاحق',
    'communityPosts': 'منشورات المجتمع',
    'communityPostsMessage':
        'شارك الاكتشافات والطلبات والإصلاحات والأعمال اليدوية مع السوق.',
    'create': 'إنشاء',
    'createPost': 'إنشاء منشور',
    'myPosts': 'منشوراتي',
    'made': 'مصنوع',
    'wanted': 'مطلوب',
    'postPrompt': 'انشر منتجاً أو طلباً أو تحديثاً...',
    'errorLoadingPosts': 'تعذر تحميل المنشورات',
    'retry': 'إعادة المحاولة',
    'emptyPostMessage': 'كن أول من يشارك شيئاً مفيداً مع المجتمع.',
    'seeMore': 'عرض المزيد',
    'savePost': 'حفظ المنشور',
    'copyLink': 'نسخ الرابط',
    'reportPost': 'الإبلاغ عن المنشور',
    'share': 'مشاركة',
    'like': 'إعجاب',
    'liked': 'تم الإعجاب',
    'comment': 'تعليق',
    'pleaseSignInToChat': 'سجل الدخول للدردشة',
    'youOwnThisPost': 'أنت مالك هذا المنشور',
    'postChat': 'دردشة المنشور',
    'deleteThisPost': 'حذف هذا المنشور؟',
    'cannotBeUndone': 'لا يمكن التراجع عن هذا الإجراء.',
    'postDeletedSuccessfully': 'تم حذف المنشور بنجاح',
    'linkCopied': 'تم نسخ الرابط!',
    'postReported': 'تم الإبلاغ عن المنشور',
    'shareNow': 'مشاركة الآن',
    'linkCopiedToClipboard': 'تم نسخ الرابط إلى الحافظة!',
    'commentAdded': 'تمت إضافة التعليق!',
    'pleaseSignIn': 'يرجى تسجيل الدخول',
    'startConversation': 'ابدأ محادثة',
    'deleteConversation': 'حذف المحادثة',
    'deleteConversationQuestion': 'حذف المحادثة؟',
    'deleteConversationHelp': 'سيتم حذف المحادثة من صندوقك فقط.',
    'conversationDeleted': 'تم حذف المحادثة من صندوقك.',
    'couldNotDeleteConversation': 'تعذر حذف المحادثة',
    'couldNotLoadMessages': 'تعذر تحميل الرسائل',
    'noMessagesYet': 'لا توجد رسائل بعد',
    'contactSellerToStart': 'تواصل مع بائع من صفحة المنتج لبدء محادثة.',
    'hideConversation': 'إخفاء المحادثة من صندوقي',
    'otherKeepsConversation': 'سيظل الطرف الآخر محتفظاً بها.',
    'conversationHidden': 'تم إخفاء المحادثة من صندوقك.',
    'attachmentsUnavailable': 'المرفقات غير متاحة في الدردشة حالياً.',
    'conversationOptions': 'خيارات المحادثة',
    'muteConversation': 'كتم المحادثة',
    'unmuteConversation': 'إلغاء كتم المحادثة',
    'muteConversationHelp': 'يتم تغيير الإشعارات لحسابك فقط.',
    'conversationMuted': 'تم كتم المحادثة.',
    'conversationUnmuted': 'تم إلغاء كتم المحادثة.',
    'blockConversation': 'حظر المحادثة',
    'unblockConversation': 'إلغاء الحظر',
    'blockConversationHelp':
        'يمنع الرسائل الجديدة والإشعارات غير الآمنة لحسابك.',
    'conversationBlocked': 'تم حظر المحادثة.',
    'conversationUnblocked': 'تم إلغاء حظر المحادثة.',
    'blockedNotice': 'لقد حظرت هذه المحادثة.',
    'reportConversation': 'الإبلاغ عن المحادثة',
    'reportConversationHelp': 'إرسال دليل السلامة إلى فريق العمليات.',
    'reportReason': 'السبب',
    'reportDescriptionOptional': 'الوصف (اختياري)',
    'submitReport': 'إرسال البلاغ',
    'conversationReported': 'تم إرسال البلاغ.',
    'addAttachment': 'إضافة مرفق',
    'typeMessage': 'اكتب رسالة...',
    'send': 'إرسال',
    'couldNotLoadConversation': 'تعذر تحميل المحادثة',
    'notificationsTitle': 'الإشعارات',
    'signInNotifications': 'سجل الدخول لعرض الإشعارات',
    'noNotificationsYet': 'لا توجد إشعارات بعد',
    'category_new': 'جديد',
    'category_used': 'مستعمل',
    'category_handicraft': 'حرف يدوية',
    'category_jewelry': 'مجوهرات',
    'category_electronics': 'إلكترونيات',
    'category_clothing': 'ملابس',
    'category_home': 'المنزل',
    'category_sports': 'رياضة',
    'category_books': 'كتب',
    'category_toys': 'ألعاب',
    'category_furniture': 'أثاث',
    'category_cars': 'سيارات',
    'category_bikes': 'دراجات',
    'category_fashion': 'أزياء',
    'category_beauty': 'جمال',
    'category_other': 'أخرى',
    'subcategory_electronics': 'إلكترونيات',
    'subcategory_clothing': 'ملابس',
    'subcategory_furniture': 'أثاث',
    'subcategory_sports': 'رياضة',
    'subcategory_books': 'كتب',
    'subcategory_toys': 'ألعاب',
    'subcategory_cars': 'سيارات',
    'subcategory_bikes': 'دراجات',
    'subcategory_jewelry': 'مجوهرات',
    'subcategory_home_and_garden': 'المنزل والحديقة',
    'subcategory_fashion': 'أزياء',
    'subcategory_beauty': 'جمال',
    'subcategory_other': 'أخرى',
    'subcategory_pottery': 'فخار',
    'subcategory_textiles': 'منسوجات',
    'subcategory_woodwork': 'أعمال خشبية',
    'subcategory_paintings': 'لوحات',
    'subcategory_candles': 'شموع',
    'subcategory_knitting': 'حياكة',
    'subcategory_embroidery': 'تطريز',
    'subcategory_rings': 'خواتم',
    'subcategory_necklaces': 'قلادات',
    'subcategory_bracelets': 'أساور',
    'subcategory_earrings': 'أقراط',
    'subcategory_watches': 'ساعات',
    'subcategory_pendants': 'دلايات',
    'subcategory_anklets': 'خلاخيل',
    'addProduct': 'إضافة منتج',
    'tapToAddImages': 'اضغط لإضافة صور',
    'selectMultiple': 'يمكن اختيار أكثر من صورة',
    'productTitle': 'عنوان المنتج',
    'description': 'الوصف',
    'price': 'السعر',
    'quantity': 'الكمية',
    'location': 'الموقع',
    'cityOrArea': 'المدينة أو المنطقة',
    'locationHint': 'مثال: القاهرة، مدينة نصر',
    'category': 'القسم',
    'subcategory': 'القسم الفرعي',
    'categoryRequired': 'اختر قسم المنتج',
    'subcategoryRequired': 'اختر القسم الفرعي',
    'imageRequired': 'اختر صورة للمنتج',
    'locationRequired': 'أضف موقع المنتج',
    'signInFirst': 'سجل الدخول أولاً',
    'titleRequired': 'عنوان المنتج مطلوب',
    'descriptionRequired': 'وصف المنتج مطلوب',
    'priceRequired': 'السعر مطلوب',
    'validNumber': 'أدخل رقماً صحيحاً',
    'saveAsDraft': 'حفظ كمسودة',
    'draftSubtitle': 'المسودات لا تظهر في المنتجات العامة.',
    'scheduleTomorrow': 'جدولة للنشر غداً',
    'scheduleSubtitle': 'يحفظ وقت نشر مجدول للبائع.',
    'listProduct': 'نشر المنتج',
    'listingQuality': 'جودة الإعلان',
    'clearTitle': 'عنوان واضح',
    'helpfulDescription': 'وصف مفيد',
    'validPrice': 'سعر صحيح',
    'atLeastOneImage': 'صورة واحدة على الأقل',
    'stockQuantitySet': 'تحديد الكمية',
    'locationAdded': 'إضافة الموقع',
    'loadingCategories': 'جاري تحميل الأقسام...',
    'noCategoriesFound': 'لا توجد أقسام',
    'initializeCategories': 'تهيئة الأقسام',
    'selectCategory': 'اختر القسم',
    'selectCategoryFirst': 'اختر القسم أولاً',
    'selectSubcategory': 'اختر القسم الفرعي',
    'noSubcategories': 'لا توجد أقسام فرعية',
    'categoriesInitialized': 'تمت تهيئة الأقسام!',
    'productApproved': 'تمت الموافقة على المنتج',
    'productApprovedScheduled': 'تمت الموافقة على المنتج وجدولته للنشر.',
    'productApprovedListed': 'تمت الموافقة على المنتج ونشره بنجاح!',
    'productSavedDraft': 'تم حفظ المنتج كمسودة.',
    'productSentReview': 'تم إرسال المنتج لمراجعة الإدارة قبل النشر.',
    'editProfile': 'تعديل الملف الشخصي',
    'save': 'حفظ',
    'fullName': 'الاسم الكامل',
    'bio': 'نبذة',
    'profileSaved': 'تم حفظ الملف الشخصي',
    'choosePhoto': 'اختيار صورة',
    'remove': 'إزالة',
    'profilePhoto': 'صورة الملف الشخصي',
    'profilePhotoHelp':
        'تظهر هذه الصورة في ملفك الشخصي ومنشوراتك ونشاطك في السوق.',
    'searchProducts': 'ابحث عن منتجات...',
    'searchForProducts': 'ابحث عن منتجات',
    'messages': 'الرسائل',
    'refresh': 'تحديث',
    'marketplaceInbox': 'صندوق رسائل السوق',
    'conversationStats': 'محادثات',
    'buying': 'شراء',
    'selling': 'بيع',
    'searchMessages': 'ابحث في المنتجات والأشخاص والرسائل',
    'comments': 'التعليقات',
    'noCommentsYet': 'لا توجد تعليقات بعد',
    'writeComment': 'اكتب تعليقاً...',
    'sendComment': 'إرسال التعليق',
    'signInToComment': 'سجل الدخول للتعليق',
    'advancedSearch': 'بحث متقدم',
    'saveSearchAlert': 'حفظ تنبيه البحث',
    'minPrice': 'أقل سعر',
    'maxPrice': 'أعلى سعر',
    'city': 'المدينة',
    'availableNow': 'متاح الآن',
    'minimumRating': 'أقل تقييم',
    'condition': 'الحالة',
    'sortBy': 'ترتيب حسب',
    'promoteSponsor': 'ترويج / إعلان ممول',
    'sponsorPost': 'إعلان ممول للمنشور',
    'deletePost': 'حذف المنشور',
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return const ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
