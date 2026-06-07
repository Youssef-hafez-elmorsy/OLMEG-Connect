import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/features/profile/domain/entities/address_entity.dart';

class AddressBookNotifier extends Notifier<List<AddressEntity>> {
  @override
  List<AddressEntity> build() => const [];

  void upsert(AddressEntity address) {
    final next = address.isDefault ? _clearDefault(state) : state;
    final index = next.indexWhere((item) => item.id == address.id);
    if (index == -1) {
      state = [
        ...next,
        address.copyWith(isDefault: address.isDefault || next.isEmpty),
      ];
      return;
    }

    state = [
      for (var i = 0; i < next.length; i++)
        if (i == index) address else next[i],
    ];
  }

  void remove(String id) {
    final wasDefault = state.any((item) => item.id == id && item.isDefault);
    final remaining = state.where((item) => item.id != id).toList();
    if (wasDefault && remaining.isNotEmpty) {
      state = [
        remaining.first.copyWith(isDefault: true),
        ...remaining.skip(1),
      ];
      return;
    }
    state = remaining;
  }

  void setDefault(String id) {
    state = [
      for (final address in state)
        address.copyWith(isDefault: address.id == id),
    ];
  }

  List<AddressEntity> _clearDefault(List<AddressEntity> addresses) {
    return [
      for (final address in addresses) address.copyWith(isDefault: false),
    ];
  }
}

final addressBookProvider =
    NotifierProvider<AddressBookNotifier, List<AddressEntity>>(() {
  return AddressBookNotifier();
});

final defaultAddressProvider = Provider<AddressEntity?>((ref) {
  final addresses = ref.watch(addressBookProvider);
  if (addresses.isEmpty) return null;
  return addresses.firstWhere(
    (address) => address.isDefault,
    orElse: () => addresses.first,
  );
});
