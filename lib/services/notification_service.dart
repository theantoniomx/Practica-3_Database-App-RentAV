import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class NotificationService {
  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    tz.initializeTimeZones();
  }

  static Future<void> scheduleRentReminder({
    required int id,
    required String title,
    required DateTime startDate,
  }) async {
    final reminderDate = startDate.subtract(const Duration(days: 2));

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'Recordatorio de renta',
      'Tu renta "$title" es el ${startDate.day}/${startDate.month}/${startDate.year}',
      tz.TZDateTime.from(reminderDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'rent_reminder_channel',
          'Recordatorios de Renta',
          channelDescription: 'Notificación 2 días antes de una renta',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  static Future<void> cancelReminder(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  static Future<void> showTestNotification() async {
    final now = DateTime.now();
    final testTime = now.add(const Duration(seconds: 10));

    await flutterLocalNotificationsPlugin.zonedSchedule(
      9999, // Prueba
      'Notificación de prueba',
      'Esto es una prueba.',
      tz.TZDateTime.from(testTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Pruebas',
          channelDescription: 'Canal para pruebas de notificaciones',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }
}
