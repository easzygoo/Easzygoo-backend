import 'package:flutter/foundation.dart';

import '../models/customer_me.dart';
import '../services/customer_profile_service.dart';

class CustomerProfileController extends ChangeNotifier {
  CustomerProfileController({required CustomerProfileService profileService})
      : _profile = profileService;

  final CustomerProfileService _profile;

  bool _loading = false;
  String? _error;
  CustomerMe? _me;

  bool get isLoading => _loading;
  String? get error => _error;
  CustomerMe? get me => _me;

  Future<void> load() async {
    if (_loading) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _me = await _profile.getMe();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
