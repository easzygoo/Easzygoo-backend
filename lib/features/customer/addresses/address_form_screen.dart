import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'models/customer_address.dart';
import 'services/customer_address_service.dart';

class CustomerAddressFormScreen extends StatefulWidget {
  const CustomerAddressFormScreen({
    super.key,
    required this.addressService,
    this.initial,
  });

  final CustomerAddressService addressService;
  final CustomerAddress? initial;

  @override
  State<CustomerAddressFormScreen> createState() =>
      _CustomerAddressFormScreenState();
}

class _CustomerAddressFormScreenState extends State<CustomerAddressFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _label;
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _line1;
  late final TextEditingController _line2;
  late final TextEditingController _landmark;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _pincode;

  bool _isDefault = false;
  bool _busy = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _label = TextEditingController(text: i?.label ?? '');
    _name = TextEditingController(text: i?.receiverName ?? '');
    _phone = TextEditingController(text: i?.receiverPhone ?? '');
    _line1 = TextEditingController(text: i?.line1 ?? '');
    _line2 = TextEditingController(text: i?.line2 ?? '');
    _landmark = TextEditingController(text: i?.landmark ?? '');
    _city = TextEditingController(text: i?.city ?? '');
    _state = TextEditingController(text: i?.state ?? '');
    _pincode = TextEditingController(text: i?.pincode ?? '');
    _isDefault = i?.isDefault ?? false;
  }

  @override
  void dispose() {
    _label.dispose();
    _name.dispose();
    _phone.dispose();
    _line1.dispose();
    _line2.dispose();
    _landmark.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
    super.dispose();
  }

  String? _req(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Required';
    return null;
  }

  String _joinParts(List<String?> parts) {
    return parts
        .where((p) => p != null)
        .map((p) => p!.trim())
        .where((p) => p.isNotEmpty)
        .toSet()
        .join(', ');
  }

  Future<void> _fillFromCurrentLocation() async {
    if (_busy || _locating) return;

    setState(() => _locating = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable GPS.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission permanently denied. Please enable it in Settings.',
        );
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      if (placemarks.isEmpty) {
        throw Exception('Could not resolve address from current location.');
      }

      final p = placemarks.first;

      final line1 = _joinParts([
        p.name,
        p.street,
        p.subLocality,
      ]);
      final line2 = _joinParts([
        p.locality,
        p.subAdministrativeArea,
      ]);

      if (_line1.text.trim().isEmpty && line1.isNotEmpty) _line1.text = line1;
      if (_line2.text.trim().isEmpty && line2.isNotEmpty) _line2.text = line2;

      final city = (p.locality ?? p.subAdministrativeArea ?? '').trim();
      if (_city.text.trim().isEmpty && city.isNotEmpty) _city.text = city;

      final state = (p.administrativeArea ?? '').trim();
      if (_state.text.trim().isEmpty && state.isNotEmpty) _state.text = state;

      final pincode = (p.postalCode ?? '').trim();
      if (_pincode.text.trim().isEmpty && pincode.isNotEmpty) _pincode.text = pincode;

      if (_landmark.text.trim().isEmpty) {
        final landmark = _joinParts([
          p.subLocality,
          p.thoroughfare,
          p.subThoroughfare,
        ]);
        if (landmark.isNotEmpty) _landmark.text = landmark;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _busy = true);

    try {
      final body = <String, dynamic>{
        'label': _label.text.trim(),
        'receiver_name': _name.text.trim(),
        'receiver_phone': _phone.text.trim(),
        'line1': _line1.text.trim(),
        'line2': _line2.text.trim(),
        'landmark': _landmark.text.trim(),
        'city': _city.text.trim(),
        'state': _state.text.trim(),
        'pincode': _pincode.text.trim(),
        'is_default': _isDefault,
      };

      final initial = widget.initial;
      final CustomerAddress saved;
      if (initial == null) {
        saved = await widget.addressService.createAddress(body: body);
      } else {
        saved = await widget.addressService.updateAddress(id: initial.id, body: body);
      }

      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit address' : 'Add address')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _label,
              decoration: const InputDecoration(labelText: 'Label (Home/Work)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Receiver name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Receiver phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: (_busy || _locating) ? null : _fillFromCurrentLocation,
              icon: _locating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(_locating ? 'Fetching location…' : 'Use current location'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _line1,
              decoration: const InputDecoration(labelText: 'Address line 1'),
              validator: _req,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _line2,
              decoration: const InputDecoration(labelText: 'Address line 2'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _landmark,
              decoration: const InputDecoration(labelText: 'Landmark'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'City'),
              validator: _req,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _state,
              decoration: const InputDecoration(labelText: 'State'),
              validator: _req,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pincode,
              decoration: const InputDecoration(labelText: 'Pincode'),
              validator: _req,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _isDefault,
              onChanged: _busy ? null : (v) => setState(() => _isDefault = v),
              title: const Text('Set as default'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(_busy ? 'Saving…' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
