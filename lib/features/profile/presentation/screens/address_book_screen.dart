import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/features/profile/domain/entities/address_entity.dart';
import 'package:olmeg_connect/features/profile/presentation/providers/address_provider.dart';

class AddressBookScreen extends ConsumerWidget {
  const AddressBookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressBookProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Addresses')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddressSheet(context, ref),
        child: const Icon(Icons.add_location_alt_outlined),
      ),
      body: addresses.isEmpty
          ? const Center(child: Text('No addresses yet'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final address = addresses[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      address.isDefault
                          ? Icons.home
                          : Icons.location_on_outlined,
                    ),
                    title: Text(address.fullName),
                    subtitle: Text('${address.formatted}\n${address.phone}'),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        final notifier = ref.read(addressBookProvider.notifier);
                        if (value == 'default') notifier.setDefault(address.id);
                        if (value == 'edit') {
                          _showAddressSheet(context, ref, address: address);
                        }
                        if (value == 'delete') notifier.remove(address.id);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'default',
                          child: Text('Set default'),
                        ),
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: addresses.length,
            ),
    );
  }

  void _showAddressSheet(
    BuildContext context,
    WidgetRef ref, {
    AddressEntity? address,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddressForm(address: address, ref: ref),
    );
  }
}

class _AddressForm extends StatefulWidget {
  final AddressEntity? address;
  final WidgetRef ref;

  const _AddressForm({this.address, required this.ref});

  @override
  State<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<_AddressForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _line1;
  late final TextEditingController _line2;
  late final TextEditingController _city;
  late final TextEditingController _region;
  late final TextEditingController _postalCode;
  late final TextEditingController _country;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    _name = TextEditingController(text: address?.fullName ?? '');
    _phone = TextEditingController(text: address?.phone ?? '');
    _line1 = TextEditingController(text: address?.line1 ?? '');
    _line2 = TextEditingController(text: address?.line2 ?? '');
    _city = TextEditingController(text: address?.city ?? '');
    _region = TextEditingController(text: address?.region ?? '');
    _postalCode = TextEditingController(text: address?.postalCode ?? '');
    _country = TextEditingController(text: address?.country ?? 'Egypt');
    _isDefault = address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _line1.dispose();
    _line2.dispose();
    _city.dispose();
    _region.dispose();
    _postalCode.dispose();
    _country.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.address == null ? 'Add address' : 'Edit address',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _field(_name, 'Full name'),
                _field(_phone, 'Phone'),
                _field(_line1, 'Address line 1'),
                _field(_line2, 'Address line 2', required: false),
                _field(_city, 'City'),
                _field(_region, 'Region', required: false),
                _field(_postalCode, 'Postal code', required: false),
                _field(_country, 'Country'),
                SwitchListTile(
                  value: _isDefault,
                  onChanged: (value) => setState(() => _isDefault = value),
                  title: const Text('Default address'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Save address'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (value) =>
                value == null || value.trim().isEmpty ? 'Required' : null
            : null,
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now().millisecondsSinceEpoch.toString();
    final address = AddressEntity(
      id: widget.address?.id ?? now,
      fullName: _name.text.trim(),
      phone: _phone.text.trim(),
      line1: _line1.text.trim(),
      line2: _line2.text.trim(),
      city: _city.text.trim(),
      region: _region.text.trim(),
      postalCode: _postalCode.text.trim(),
      country: _country.text.trim(),
      isDefault: _isDefault,
    );
    widget.ref.read(addressBookProvider.notifier).upsert(address);
    Navigator.pop(context);
  }
}
