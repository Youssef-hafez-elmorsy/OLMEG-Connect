import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:olmeg_connect/features/payments/domain/entities/paymob_checkout_session.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymobCheckoutLauncher {
  static const MethodChannel _sdkChannel = MethodChannel('paymob_sdk_flutter');

  const PaymobCheckoutLauncher();

  Future<void> launch(PaymobCheckoutSession session) async {
    final canUseNativeSdk = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    if (canUseNativeSdk) {
      try {
        await _sdkChannel.invokeMethod<String>('payWithPaymob', {
          'clientSecret': session.clientSecret,
          'publicKey': session.publicKey,
          'appName': 'Olmeg Connect',
          'buttonBackgroundColor': 0xFF00C853,
          'buttonTextColor': 0xFFFFFFFF,
          'saveCardDefault': false,
          'showSaveCard': true,
        });
        return;
      } on PlatformException catch (error) {
        if (error.code != 'paymob_sdk_missing') rethrow;
      } on MissingPluginException {
        // Fall through to hosted checkout when native SDK is unavailable.
      }
    }

    final uri = Uri.tryParse(session.checkoutUrl);
    if (uri == null) {
      throw Exception('Paymob checkout URL is invalid.');
    }

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      throw Exception('Could not open Paymob checkout.');
    }
  }
}
