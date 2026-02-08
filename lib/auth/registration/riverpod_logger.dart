// riverpod_logger.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

class RiverpodLogger extends ProviderObserver {
  @override
  void didUpdateProvider(
      ProviderBase provider,
      Object? previousValue,
      Object? newValue,
      ProviderContainer container,
      ) {
    if (provider.name == 'justRegisteredProvider' ||
        provider.name == 'authCheckProvider' ||
        provider.runtimeType.toString().contains('authCheck')) {
      debugPrint('LOG [${provider.name ?? provider.runtimeType}]: $previousValue -> $newValue');
    }
  }
}