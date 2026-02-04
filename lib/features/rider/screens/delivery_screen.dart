import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/network/api_client.dart';
import '../../../core/services/order_service.dart';

/// Delivery screen.
///
/// Map uses placeholder coordinates for now.
class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({
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
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  GoogleMapController? _controller;
  bool _submitting = false;

  // Dummy coordinates (Bengaluru area). Replace later with real location service.
  static const LatLng _customerLocation = LatLng(12.9698, 77.6090);
  static const LatLng _riderLocation = LatLng(12.9724, 77.6021);

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
        const Marker(
          markerId: MarkerId('customer'),
          position: _customerLocation,
          infoWindow: InfoWindow(title: 'Customer'),
        ),
      };

  Future<void> _fitBounds() async {
    final controller = _controller;
    if (controller == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        _riderLocation.latitude < _customerLocation.latitude ? _riderLocation.latitude : _customerLocation.latitude,
        _riderLocation.longitude < _customerLocation.longitude ? _riderLocation.longitude : _customerLocation.longitude,
      ),
      northeast: LatLng(
        _riderLocation.latitude > _customerLocation.latitude ? _riderLocation.latitude : _customerLocation.latitude,
        _riderLocation.longitude > _customerLocation.longitude ? _riderLocation.longitude : _customerLocation.longitude,
      ),
    );

    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 72));
  }

  Future<void> _markDelivered() async {
    setState(() => _submitting = true);
    try {
      await widget.orderService.markDelivered(widget.order.id);
      widget.onOrderUpdated?.call();
      if (!mounted) return;
      setState(() => _submitting = false);
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).popUntil((route) => route.isFirst);
      messenger.showSnackBar(
        const SnackBar(content: Text('Order delivered.')),
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
        const SnackBar(content: Text('Failed to mark delivered.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery'),
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
                target: _customerLocation,
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
                      Text('Deliver to', style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text('Customer: ${widget.order.customerId}', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text('Address: (not provided)', style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _submitting ? null : _markDelivered,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Mark Delivered'),
                        ),
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
