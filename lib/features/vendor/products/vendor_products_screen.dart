import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../models/vendor_product.dart';
import '../services/vendor_products_service.dart';

class VendorProductsScreen extends StatefulWidget {
  const VendorProductsScreen({
    super.key,
    required this.apiClient,
  });

  final ApiClient apiClient;

  @override
  State<VendorProductsScreen> createState() => _VendorProductsScreenState();
}

class _VendorProductsScreenState extends State<VendorProductsScreen> {
  late final _Controller _controller;

  @override
  void initState() {
    super.initState();
    _controller = _Controller(service: VendorProductsService(apiClient: widget.apiClient));
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _controller.loading ? null : _controller.load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _controller.loading
            ? null
            : () async {
                final created = await showModalBottomSheet<VendorProduct>(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (context) => _ProductEditorSheet(initial: null),
                );
                if (created == null) return;

                if (!context.mounted) return;
                final messenger = ScaffoldMessenger.of(context);
                await _controller.create(created);
                if (!context.mounted) return;
                messenger.showSnackBar(const SnackBar(content: Text('Product created')));
              },
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.loading && _controller.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.error != null && _controller.products.isEmpty) {
            return _ErrorState(message: _controller.error!, onRetry: _controller.load);
          }

          return RefreshIndicator(
            onRefresh: () => _controller.load(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _controller.products.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final p = _controller.products[index];
                return _ProductCard(
                  product: p,
                  busy: _controller.busyIds.contains(p.id),
                  onToggleActive: () async {
                    await _controller.update(p.id, {'is_active': !p.isActive});
                  },
                  onEdit: () async {
                    final edited = await showModalBottomSheet<VendorProduct>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (context) => _ProductEditorSheet(initial: p),
                    );
                    if (edited == null) return;
                    await _controller.update(p.id, edited.toWriteJson());
                  },
                  onDelete: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete product?'),
                        content: Text('Delete "${p.name}" permanently?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                        ],
                      ),
                    );
                    if (ok != true) return;

                    if (!context.mounted) return;
                    final messenger = ScaffoldMessenger.of(context);
                    await _controller.delete(p.id);
                    if (!context.mounted) return;
                    messenger.showSnackBar(const SnackBar(content: Text('Product deleted')));
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _Controller extends ChangeNotifier {
  _Controller({required VendorProductsService service}) : _service = service;

  final VendorProductsService _service;

  bool loading = false;
  String? error;
  List<VendorProduct> products = <VendorProduct>[];
  final Set<String> busyIds = <String>{};

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      products = await _service.listProducts();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> create(VendorProduct product) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      await _service.createProduct(product);
      products = await _service.listProducts();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> update(String id, Map<String, dynamic> patch) async {
    busyIds.add(id);
    error = null;
    notifyListeners();

    try {
      await _service.updateProduct(id, patch);
      products = await _service.listProducts();
    } catch (e) {
      error = e.toString();
    } finally {
      busyIds.remove(id);
      notifyListeners();
    }
  }

  Future<void> delete(String id) async {
    busyIds.add(id);
    error = null;
    notifyListeners();

    try {
      await _service.deleteProduct(id);
      products = await _service.listProducts();
    } catch (e) {
      error = e.toString();
    } finally {
      busyIds.remove(id);
      notifyListeners();
    }
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.busy,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
  });

  final VendorProduct product;
  final bool busy;
  final Future<void> Function() onToggleActive;
  final Future<void> Function() onEdit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: product.isActive,
                  onChanged: busy ? null : (_) => onToggleActive(),
                ),
              ],
            ),
            if (product.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(product.description, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _Pill(label: '₹${product.price.toStringAsFixed(2)}'),
                const SizedBox(width: 8),
                _Pill(label: 'Stock: ${product.stock}'),
                const Spacer(),
                if (busy) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : () => onEdit(),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : () => onDelete(),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _ProductEditorSheet extends StatefulWidget {
  const _ProductEditorSheet({required this.initial});

  final VendorProduct? initial;

  @override
  State<_ProductEditorSheet> createState() => _ProductEditorSheetState();
}

class _ProductEditorSheetState extends State<_ProductEditorSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _name = TextEditingController(text: p?.name ?? '');
    _desc = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(text: p == null ? '' : p.price.toStringAsFixed(2));
    _stock = TextEditingController(text: p == null ? '' : p.stock.toString());
    _active = p?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  VendorProduct _buildProduct() {
    return VendorProduct(
      id: widget.initial?.id ?? '',
      name: _name.text.trim(),
      description: _desc.text.trim(),
      price: double.tryParse(_price.text.trim()) ?? 0.0,
      stock: int.tryParse(_stock.text.trim()) ?? 0,
      isActive: _active,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, bottom: bottom + 16, top: 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(widget.initial == null ? 'New product' : 'Edit product', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _desc,
                    decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _price,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()),
                          validator: (v) {
                            final d = double.tryParse((v ?? '').trim());
                            if (d == null || d < 0) return 'Enter valid price';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _stock,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Stock', border: OutlineInputBorder()),
                          validator: (v) {
                            final i = int.tryParse((v ?? '').trim());
                            if (i == null || i < 0) return 'Enter valid stock';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: _active,
                    onChanged: (v) => setState(() => _active = v),
                    title: const Text('Active'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (!(_formKey.currentState?.validate() ?? false)) return;
                        Navigator.pop(context, _buildProduct());
                      },
                      child: Text(widget.initial == null ? 'Create' : 'Save'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
