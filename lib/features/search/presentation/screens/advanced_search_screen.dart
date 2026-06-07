import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:olmeg_connect/core/localization/app_localizations.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/features/analytics/presentation/providers/analytics_provider.dart';
import 'package:olmeg_connect/features/auth/presentation/providers/auth_provider.dart';
import 'package:olmeg_connect/features/search/domain/entities/search_filter_entity.dart';
import 'package:olmeg_connect/features/search/presentation/providers/search_provider.dart';
import 'package:olmeg_connect/features/products/presentation/widgets/product_card.dart';

class AdvancedSearchScreen extends ConsumerStatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  ConsumerState<AdvancedSearchScreen> createState() =>
      _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends ConsumerState<AdvancedSearchScreen> {
  late TextEditingController _searchController;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  late TextEditingController _cityController;
  String? _selectedCategory;
  String? _selectedCondition;
  double? _minRating;
  bool _onlyAvailable = false;
  String _sortBy = 'relevance';
  String? _lastImpressionKey;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _minPriceController = TextEditingController();
    _maxPriceController = TextEditingController();
    _cityController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _performSearch() {
    setState(() {});
    final filter = SearchFilterEntity(
      query: _searchController.text.isEmpty ? null : _searchController.text,
      minPrice: _minPriceController.text.isEmpty
          ? null
          : double.tryParse(_minPriceController.text),
      maxPrice: _maxPriceController.text.isEmpty
          ? null
          : double.tryParse(_maxPriceController.text),
      category: _selectedCategory,
      condition: _selectedCondition,
      location: _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      minRating: _minRating,
      onlyAvailable: _onlyAvailable,
      sortBy: _sortBy,
    );

    final user = ref.read(authStateProvider).value;
    if (user != null && _searchController.text.trim().isNotEmpty) {
      ref
          .read(analyticsServiceProvider)
          .trackSearchPerformed(user.id, _searchController.text.trim())
          .catchError((_) {});
    }
    ref.read(searchResultsProvider(filter));
  }

  Future<void> _saveSearchAlert() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to save search alerts')),
      );
      return;
    }

    final query = _searchController.text.trim();
    final hasFilter = query.isNotEmpty ||
        _minPriceController.text.trim().isNotEmpty ||
        _maxPriceController.text.trim().isNotEmpty ||
        _selectedCategory != null ||
        _selectedCondition != null ||
        _cityController.text.trim().isNotEmpty ||
        _minRating != null ||
        _onlyAvailable;
    if (!hasFilter) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a query or filter before saving')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('saved_searches').add({
      'userId': user.id,
      'query': query,
      'minPrice': double.tryParse(_minPriceController.text.trim()),
      'maxPrice': double.tryParse(_maxPriceController.text.trim()),
      'category': _selectedCategory,
      'condition': _selectedCondition,
      'city': _cityController.text.trim(),
      'minRating': _minRating,
      'onlyAvailable': _onlyAvailable,
      'sortBy': _sortBy,
      'alertEnabled': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Search alert saved')),
    );
  }

  void _recordSearchImpression(int resultCount) {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final query = _searchController.text.trim();
    final city = _cityController.text.trim();
    if (query.isEmpty &&
        city.isEmpty &&
        !_onlyAvailable &&
        _minRating == null) {
      return;
    }
    final key = [
      user.id,
      query,
      _minPriceController.text.trim(),
      _maxPriceController.text.trim(),
      _selectedCategory ?? '',
      _selectedCondition ?? '',
      city,
      _minRating?.toString() ?? '',
      _onlyAvailable.toString(),
      _sortBy,
      resultCount.toString(),
    ].join('|');
    if (_lastImpressionKey == key) return;
    _lastImpressionKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(analyticsServiceProvider)
          .trackSearchResultsViewed(
            user.id,
            query: query,
            resultCount: resultCount,
            sortBy: _sortBy,
          )
          .catchError((_) {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final filter = SearchFilterEntity(
      query: _searchController.text.isEmpty ? null : _searchController.text,
      minPrice: _minPriceController.text.isEmpty
          ? null
          : double.tryParse(_minPriceController.text),
      maxPrice: _maxPriceController.text.isEmpty
          ? null
          : double.tryParse(_maxPriceController.text),
      category: _selectedCategory,
      condition: _selectedCondition,
      location: _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      minRating: _minRating,
      onlyAvailable: _onlyAvailable,
      sortBy: _sortBy,
    );

    final searchResults = ref.watch(searchResultsProvider(filter));
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('advancedSearch')),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: l10n.t('saveSearchAlert'),
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: _saveSearchAlert,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: l10n.t('searchProducts'),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (_) => _performSearch(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.t('minPrice'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onChanged: (_) => _performSearch(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextField(
                          controller: _maxPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.t('maxPrice'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onChanged: (_) => _performSearch(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _cityController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.t('city'),
                      prefixIcon: const Icon(Icons.location_city_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (_) => _performSearch(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.t('availableNow')),
                    value: _onlyAvailable,
                    onChanged: (value) {
                      setState(() => _onlyAvailable = value);
                      _performSearch();
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<double>(
                    initialValue: _minRating,
                    decoration: InputDecoration(
                      labelText: l10n.t('minimumRating'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 4, child: Text('4 stars & up')),
                      DropdownMenuItem(value: 3, child: Text('3 stars & up')),
                      DropdownMenuItem(value: 2, child: Text('2 stars & up')),
                    ],
                    onChanged: (value) {
                      setState(() => _minRating = value);
                      _performSearch();
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCondition,
                    decoration: InputDecoration(
                      labelText: l10n.t('condition'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: ['New', 'Used', 'Refurbished']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedCondition = value);
                      _performSearch();
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: _sortBy,
                    decoration: InputDecoration(
                      labelText: l10n.t('sortBy'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: [
                      'relevance',
                      'newest',
                      'price_low',
                      'price_high',
                      'rating',
                      'availability',
                      'discount',
                    ]
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.replaceAll('_', ' ')),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _sortBy = value ?? 'newest');
                      _performSearch();
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: searchResults.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Text('Error: $error'),
                ),
                data: (products) {
                  _recordSearchImpression(products.length);
                  if (products.isEmpty) {
                    return Center(
                      child: Text(l10n.noProductsFound),
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return ProductCard(product: products[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
