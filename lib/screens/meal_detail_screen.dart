import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/meal.dart';
import '../services/meal_service.dart';
import '../widgets/loading_widget.dart';

class MealDetailScreen extends StatefulWidget {
  final String mealId;

  const MealDetailScreen({
    Key? key,
    required this.mealId,
  }) : super(key: key);

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  final MealService _mealService = MealService();
  Meal? _meal;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMealDetails();
  }

  Future<void> _loadMealDetails() async {
    try {
      setState(() => _isLoading = true);
      final meal = await _mealService.getMealById(widget.mealId);
      setState(() {
        _meal = meal;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Грешка: $e')),
        );
      }
    }
  }

  Future<void> _launchYoutube(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не може да се отвори YouTube')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _meal?.strMeal ?? 'Детали за рецепт',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _meal == null
              ? const Center(
                  child: Text(
                    'Рецептот не е пронајден',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CachedNetworkImage(
                        imageUrl: _meal!.strMealThumb,
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 300,
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _meal!.strMeal,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (_meal!.strCategory != null) ...[
                                  Chip(
                                    avatar: const Icon(Icons.folder, size: 18),
                                    label: Text(_meal!.strCategory!),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (_meal!.strArea != null)
                                  Chip(
                                    avatar: const Icon(Icons.public, size: 18),
                                    label: Text(_meal!.strArea!),
                                  ),
                              ],
                            ),
                            if (_meal!.strTags != null &&
                                _meal!.strTags!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _meal!.strTags!
                                    .split(',')
                                    .map((tag) => Chip(
                                          label: Text(tag.trim()),
                                          backgroundColor:
                                              const Color(0xFF667eea),
                                          labelStyle: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ],
                            const SizedBox(height: 24),
                            const Text(
                              'Состојки',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(thickness: 2),
                            const SizedBox(height: 8),
                            ..._meal!.ingredients.map((ingredient) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.circle,
                                          size: 8, color: Color(0xFF667eea)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${ingredient.ingredient}${ingredient.measure.isNotEmpty ? ' - ${ingredient.measure}' : ''}',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                            const SizedBox(height: 24),
                            const Text(
                              'Инструкции',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(thickness: 2),
                            const SizedBox(height: 8),
                            Text(
                              _meal!.strInstructions ?? 'Нема достапни инструкции',
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                              ),
                            ),
                            if (_meal!.strYoutube != null) ...[
                              const SizedBox(height: 24),
                              const Text(
                                'Видео рецепт',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(thickness: 2),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () => _launchYoutube(_meal!.strYoutube!),
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Отвори на YouTube'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
