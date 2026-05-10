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
  String get marketplaceTagline =>
      isArabic ? 'سوقك لكل شيء' : 'Your marketplace for everything';
  String get welcomeBack => isArabic ? 'مرحباً بعودتك' : 'Welcome back';
  String get signInToAccount =>
      isArabic ? 'سجّل الدخول إلى حسابك' : 'Sign in to your account';
  String get email => isArabic ? 'البريد الإلكتروني' : 'Email';
  String get emailHint => isArabic ? 'you@example.com' : 'you@example.com';
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
