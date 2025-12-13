import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../models/meal.dart';
import 'meal_service.dart';

// Background message handler - мора да биде top-level функција
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  final MealService _mealService = MealService();

  // Callback за отворање на детали за рецепт
  Function(String mealId)? onMealNotificationTap;

  // Иницијализација
  Future<void> init() async {
    // Барај дозвола за нотификации
    await _requestPermission();

    // Конфигурирај локални нотификации
    await _setupLocalNotifications();

    // Конфигурирај Firebase Messaging
    await _setupFirebaseMessaging();

    // Земи FCM token
    await _getToken();
  }

  // Барање дозвола
  Future<void> _requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('Notification permission status: ${settings.authorizationStatus}');
  }

  // Setup локални нотификации
  Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Креирај notification channel за Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'recipe_of_day_channel',
      'Рецепт на денот',
      description: 'Нотификации за дневен рецепт',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Setup Firebase Messaging
  Future<void> _setupFirebaseMessaging() async {
    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background/terminated messages (кога се кликне на нотификација)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Провери дали апликацијата е отворена од нотификација
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  // Земи FCM token
  Future<String?> _getToken() async {
    String? token = await _messaging.getToken();
    print('FCM Token: $token');

    // Слушај за промени на token
    _messaging.onTokenRefresh.listen((newToken) {
      print('FCM Token refreshed: $newToken');
      // Тука можеш да го зачуваш новиот token на сервер
    });

    return token;
  }

  // Handle foreground message
  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message received: ${message.notification?.title}');

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'recipe_of_day_channel',
            'Рецепт на денот',
            channelDescription: 'Нотификации за дневен рецепт',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: message.data['mealId'],
      );
    }
  }

  // Handle message opened app
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Message opened app: ${message.data}');

    String? mealId = message.data['mealId'];
    if (mealId != null && onMealNotificationTap != null) {
      onMealNotificationTap!(mealId);
    }
  }

  // Handle local notification tap
  void _onNotificationTap(NotificationResponse response) {
    String? mealId = response.payload;
    if (mealId != null && onMealNotificationTap != null) {
      onMealNotificationTap!(mealId);
    }
  }

  // Прикажи локална нотификација за рандом рецепт
  Future<void> showRandomMealNotification() async {
    try {
      Meal? randomMeal = await _mealService.getRandomMeal();

      if (randomMeal != null) {
        await _localNotifications.show(
          DateTime.now().millisecond,
          '🍽️ Рецепт на денот',
          'Пробај го денес: ${randomMeal.strMeal}',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'recipe_of_day_channel',
              'Рецепт на денот',
              channelDescription: 'Нотификации за дневен рецепт',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: randomMeal.idMeal,
        );
      }
    } catch (e) {
      print('Error showing random meal notification: $e');
    }
  }

  // Закажи дневна нотификација
  Future<void> scheduleDailyNotification({
    required int hour,
    required int minute,
  }) async {
    // Откажи претходни закажани нотификации
    await _localNotifications.cancelAll();

    // За периодични нотификации со новата верзија
    await _localNotifications.periodicallyShow(
      0,
      '🍽️ Рецепт на денот',
      'Отвори ја апликацијата за да видиш нов рецепт!',
      RepeatInterval.daily,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'recipe_of_day_channel',
          'Рецепт на денот',
          channelDescription: 'Нотификации за дневен рецепт',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );

    print('Daily notification scheduled');
  }

  // Тест нотификација
  Future<void> showTestNotification() async {
    await _localNotifications.show(
      999,
      '🧪 Тест нотификација',
      'Нотификациите работат правилно!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'recipe_of_day_channel',
          'Рецепт на денот',
          channelDescription: 'Нотификации за дневен рецепт',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}