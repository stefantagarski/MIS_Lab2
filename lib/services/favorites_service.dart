import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/meal.dart';

class FavoritesService {
  static const String _favoritesKey = 'favorite_meals';

  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  List<String> _favoriteIds = [];
  Map<String, Map<String, dynamic>> _favoriteMeals = {};

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favoritesJson = prefs.getString(_favoritesKey);

    if (favoritesJson != null) {
      final Map<String, dynamic> data = json.decode(favoritesJson);
      _favoriteIds = List<String>.from(data['ids'] ?? []);
      _favoriteMeals = Map<String, Map<String, dynamic>>.from(
          (data['meals'] ?? {}).map((key, value) =>
              MapEntry(key, Map<String, dynamic>.from(value))
          )
      );
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'ids': _favoriteIds,
      'meals': _favoriteMeals,
    };
    await prefs.setString(_favoritesKey, json.encode(data));
  }

  bool isFavorite(String mealId) {
    return _favoriteIds.contains(mealId);
  }

  Future<void> addFavorite(Meal meal) async {
    if (!_favoriteIds.contains(meal.idMeal)) {
      _favoriteIds.add(meal.idMeal);
      _favoriteMeals[meal.idMeal] = {
        'idMeal': meal.idMeal,
        'strMeal': meal.strMeal,
        'strMealThumb': meal.strMealThumb,
        'strCategory': meal.strCategory,
        'strArea': meal.strArea,
      };
      await _save();
    }
  }

  Future<void> removeFavorite(String mealId) async {
    _favoriteIds.remove(mealId);
    _favoriteMeals.remove(mealId);
    await _save();
  }

  Future<bool> toggleFavorite(Meal meal) async {
    if (isFavorite(meal.idMeal)) {
      await removeFavorite(meal.idMeal);
      return false;
    } else {
      await addFavorite(meal);
      return true;
    }
  }

  List<Meal> getFavorites() {
    return _favoriteMeals.values.map((mealData) {
      return Meal(
        idMeal: mealData['idMeal'] ?? '',
        strMeal: mealData['strMeal'] ?? '',
        strMealThumb: mealData['strMealThumb'] ?? '',
        strCategory: mealData['strCategory'],
        strArea: mealData['strArea'],
        ingredients: [],
      );
    }).toList();
  }

  int get favoritesCount => _favoriteIds.length;
}