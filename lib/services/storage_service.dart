import 'package:hive_ce/hive.dart';

class StorageService {
  // ============================================================
  // HIVE BOX
  // ============================================================

  static const String _boxName = 'vsf_storage';

  // ============================================================
  // STORAGE KEYS
  // ============================================================

  static const String _tokenKey = 'auth_token';

  // ============================================================
  // BOX INSTANCE
  // ============================================================

  Box<dynamic>? _box;

  // ============================================================
  // INITIALIZE BOX
  // ============================================================

  Future<void> init() async {
    if (_box != null && _box!.isOpen) {
      return;
    }

    _box = await Hive.openBox<dynamic>(
      _boxName,
    );
  }

  // ============================================================
  // ENSURE INITIALIZED
  // ============================================================

  Future<void> _ensureInitialized() async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }
  }

  // ============================================================
  // SAVE TOKEN
  // ============================================================

  Future<void> saveToken(String token) async {
    await _ensureInitialized();

    await _box!.put(
      _tokenKey,
      token,
    );
  }

  // ============================================================
  // GET TOKEN
  // ============================================================

  Future<String?> getToken() async {
    await _ensureInitialized();

    final value = _box!.get(
      _tokenKey,
    );

    if (value is String && value.isNotEmpty) {
      return value;
    }

    return null;
  }

  // ============================================================
  // CHECK TOKEN
  // ============================================================

  Future<bool> hasToken() async {
    final token = await getToken();

    return token != null && token.isNotEmpty;
  }

  // ============================================================
  // REMOVE TOKEN
  // ============================================================

  Future<void> removeToken() async {
    await _ensureInitialized();

    await _box!.delete(
      _tokenKey,
    );
  }

  // ============================================================
  // CLEAR STORAGE
  // ============================================================

  Future<void> clear() async {
    await _ensureInitialized();

    await _box!.clear();
  }
}