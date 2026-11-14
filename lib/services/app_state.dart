import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kaydedilen stiller ve son analiz sonucu. Uygulama genelinde tek örnek.
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  static const _favKey = 'favorites';
  static const _shapeKey = 'my_shape';

  late SharedPreferences _prefs;

  /// "hair:quiff@oval" biçiminde anahtarlar (stil + hangi yüz şekli için).
  final List<String> favorites = [];
  String? myShape;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    favorites
      ..clear()
      ..addAll(_prefs.getStringList(_favKey) ?? const []);
    myShape = _prefs.getString(_shapeKey);
  }

  static String key(String kind, String styleId, String shapeId) => '$kind:$styleId@$shapeId';

  bool isFavorite(String k) => favorites.contains(k);

  Future<void> toggleFavorite(String k) async {
    favorites.contains(k) ? favorites.remove(k) : favorites.insert(0, k);
    notifyListeners();
    await _prefs.setStringList(_favKey, favorites);
  }

  Future<void> setMyShape(String id) async {
    myShape = id;
    notifyListeners();
    await _prefs.setString(_shapeKey, id);
  }
}
