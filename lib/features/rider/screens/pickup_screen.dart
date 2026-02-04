import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/network/api_client.dart';
import '../../../core/services/order_service.dart';
import 'delivery_screen.dart';

/// Pickup screen.
///
/// Map shows static dummy coordinates for now.
/// - Rider "current" location (placeholder)
/// - Shop marker
///
/// Navigation button is UI-only (no intent).
class PickupScreen extends StatefulWidget {
  const PickupScreen({
    super.key,
    required this.order,
    required this.orderService,
    required this.onAuthExpired,
    this.onOrderUpdated,
  });

  final OrderModel order;
  final OrderService orderService;
  final VoidCallback onAuthExpired;
  final VoidCallback? onOrderUpdated;

  @override
  State<PickupScreen> createState() => _PickupScreenState();
}

class _PickupScreenState extends State<PickupScreen> {
  GoogleMapController? _controller;
  bool _submitting = false;

  // Dummy coordinates (Bengaluru area). Replace later with real location service.
  static const LatLng _riderLocation = LatLng(12.9716, 77.5946);
  static const LatLng _shopLocation = LatLng(12.9752, 77.6050);

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Set<Marker> get _markers => {
        const Marker(
          markerId: MarkerId('rider'),
          position: _riderLocation,
          infoWindow: InfoWindow(title: 'You'),
        ),
        Marker(
          markerId: const MarkerId('shop'),
          position: _shopLocation,
          infoWindow: InfoWindow(title: widget.order.vendorName),
        ),
      };

  Future<void> _markPicked() async {
    setState(() => _submitting = true);
    try {
      final updated = await widget.orderService.markPicked(widget.order.id);
      widget.onOrderUpdated?.call();
      if (!mounted) return;
      setState(() => _submitting = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DeliveryScreen(
            order: updated,
            orderService: widget.orderService,
            onAuthExpired: widget.onAuthExpired,
            onOrderUpdated: widget.onOrderUpdated,
          ),
        ),
      );
    } on AuthExpiredException {
      if (!mounted) return;
      setState(() => _submitting = false);
      widget.onAuthExpired();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to mark picked up.')),
      );
    }
  }

  Future<void> _fitBounds() async {
    final controller = _controller;
    if (controller == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        _riderLocation.latitude < _shopLocation.latitude ? _riderLocation.latitude : _shopLocation.latitude,
        _riderLocation.longitude < _shopLocation.longitude ? _riderLocation.longitude : _shopLocation.longitude,
      ),
      northeast: LatLng(
        _riderLocation.latitude > _shopLocation.latitude ? _riderLocation.latitude : _shopLocation.latitude,
        _riderLocation.longitude > _shopLocation.longitude ? _riderLocation.longitude : _shopLocation.longitude,
      ),
    );

    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 72));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup'),
        actions: [
          IconButton(
            tooltip: 'Fit map',
            onPressed: _fitBounds,
            icon: const Icon(Icons.my_location),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _riderLocation,
                zoom: 13,
              ),
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              compassEnabled: true,
              zoomControlsEnabled: false,
              markers: _markers,
              onMapCreated: (c) async {
                _controller = c;
                await _fitBounds();
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Pickup from', style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text(widget.order.vendorName, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text('Order: ${widget.order.id}', style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Navigation coming soon.')),
                                );
                              },
                              icon: const Icon(Icons.navigation),
                              label: const Text('Navigate'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _submitting ? null : _markPicked,
                              child: _submitting
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Mark Picked Up'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
