class Meal {
  final String idMeal;
  final String strMeal;
  final String? strCategory;
  final String? strArea;
  final String? strInstructions;
  final String strMealThumb;
  final String? strTags;
  final String? strYoutube;
  final List<Ingredient> ingredients;

  Meal({
    required this.idMeal,
    required this.strMeal,
    this.strCategory,
    this.strArea,
    this.strInstructions,
    required this.strMealThumb,
    this.strTags,
    this.strYoutube,
    required this.ingredients,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    List<Ingredient> ingredients = [];
    
    for (int i = 1; i <= 20; i++) {
      String? ingredient = json['strIngredient$i'];
      String? measure = json['strMeasure$i'];
      
      if (ingredient != null && ingredient.trim().isNotEmpty) {
        ingredients.add(Ingredient(
          ingredient: ingredient.trim(),
          measure: measure?.trim() ?? '',
        ));
      }
    }

    return Meal(
      idMeal: json['idMeal'] ?? '',
      strMeal: json['strMeal'] ?? '',
      strCategory: json['strCategory'],
      strArea: json['strArea'],
      strInstructions: json['strInstructions'],
      strMealThumb: json['strMealThumb'] ?? '',
      strTags: json['strTags'],
      strYoutube: json['strYoutube'],
      ingredients: ingredients,
    );
  }

  String? getYoutubeVideoId() {
    if (strYoutube == null) return null;
    final uri = Uri.parse(strYoutube!);
    return uri.queryParameters['v'];
  }
}

class Ingredient {
  final String ingredient;
  final String measure;

  Ingredient({
    required this.ingredient,
    required this.measure,
  });
}
