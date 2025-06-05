import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:practica_3_database/models/user.dart';
import 'package:practica_3_database/models/category.dart';
import 'package:practica_3_database/models/equipment.dart';
import 'package:practica_3_database/models/rent.dart';
import 'package:practica_3_database/models/rent_detail.dart';

class DBService {
  static final DBService _instance = DBService._internal();
  factory DBService() => _instance;
  DBService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'rentav.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT,
        phone TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        imagePath TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE equipment (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        description TEXT,
        price REAL,
        imagePath TEXT,
        categoryId INTEGER,
        FOREIGN KEY (categoryId) REFERENCES categories(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE rents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        startDate TEXT,
        endDate TEXT,
        status TEXT,
        reminderDate TEXT,
        userId INTEGER,
        FOREIGN KEY (userId) REFERENCES users(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE rent_details (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        rentId INTEGER,
        equipmentId INTEGER,
        quantity INTEGER,
        FOREIGN KEY (rentId) REFERENCES rents(id),
        FOREIGN KEY (equipmentId) REFERENCES equipment(id)
      );
    ''');
  }

  Future<void> insertCategory(Category category) async {
    final db = await database;
    await db.insert('categories', category.toMap());
  }

  Future<void> insertEquipment(Equipment equipment) async {
    final db = await database;
    await db.insert('equipment', equipment.toMap());
  }

  Future<void> insertUser(User user) async {
    final db = await database;
    await db.insert('users', user.toMap());
  }

  Future<int> insertRent(Rent rent) async {
    final db = await database;
    return await db.insert('rents', rent.toMap());
  }

  Future<void> insertRentDetail(RentDetail detail) async {
    final db = await database;
    await db.insert('rent_details', detail.toMap());
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final result = await db.query('users');
    return result.map((map) => User.fromMap(map)).toList();
  }

  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final result = await db.query('categories');
    return result.map((map) => Category.fromMap(map)).toList();
  }

  Future<List<Equipment>> getEquipmentByCategory(int categoryId) async {
    final db = await database;
    final result = await db.query(
      'equipment',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
    );
    return result.map((map) => Equipment.fromMap(map)).toList();
  }

  Future<List<Rent>> getRentsByStatus(String status) async {
    final db = await database;
    final result = await db.query(
      'rents',
      where: 'status = ?',
      whereArgs: [status],
    );
    return result.map((map) => Rent.fromMap(map)).toList();
  }

  Future<void> updateRentStatus(int rentId, String newStatus) async {
    final db = await database;
    await db.update(
      'rents',
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [rentId],
    );
  }

  Future<Equipment?> getEquipmentById(int equipmentId) async {
    final db = await database;
    final result = await db.query(
      'equipment',
      where: 'id = ?',
      whereArgs: [equipmentId],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return Equipment.fromMap(result.first);
    }
    return null;
  }

  Future<String> getUserNameById(int userId) async {
    final db = await database;
    final result = await db.query(
      'users',
      columns: ['name'],
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first['name'] as String;
    }
    return 'Desconocido';
  }

  Future<List<RentDetail>> getRentDetails(int rentId) async {
    final db = await database;
    final result = await db.query(
      'rent_details',
      where: 'rentId = ?',
      whereArgs: [rentId],
    );
    return result.map((map) => RentDetail.fromMap(map)).toList();
  }

  Future<void> deleteRent(int rentId) async {
    final db = await database;
    await db.delete('rents', where: 'id = ?', whereArgs: [rentId]);
  }

  Future<void> deleteDatabaseFile() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'rentav.db');
    await deleteDatabase(path);
  }

  Future<void> preloadData() async {
    final db = await database;
    final existingCategories = await db.query('categories');

    if (existingCategories.isEmpty) {
      await db.insert('users', {
        'name': 'Carlos Mendoza',
        'email': 'carlos@example.com',
        'phone': '4621234567',
      });
      await db.insert('users', {
        'name': 'María López',
        'email': 'maria@example.com',
        'phone': '4627654321',
      });
      await db.insert('users', {
        'name': 'Alejandro Torres',
        'email': 'alejandro@example.com',
        'phone': '4628889999',
      });
      // Categorías
      final audioId = await db.insert('categories', {
        'name': 'Audio',
        'imagePath': 'assets/images/categories/audio.png',
      });
      final videoId = await db.insert('categories', {
        'name': 'Video',
        'imagePath': 'assets/images/categories/video.png',
      });
      final iluminacionId = await db.insert('categories', {
        'name': 'Iluminación',
        'imagePath': 'assets/images/categories/iluminacion.png',
      });
      final sonidoId = await db.insert('categories', {
        'name': 'Sonido',
        'imagePath': 'assets/images/categories/sonido.png',
      });

      // Equipos de Audio
      await db.insert('equipment', {
        'name': 'Micrófono Inalámbrico',
        'description': 'Micrófono ideal para presentaciones en vivo.',
        'price': 150.0,
        'imagePath': 'assets/images/equipment/microfono.png',
        'categoryId': audioId,
      });
      await db.insert('equipment', {
        'name': 'Bocina JBL Pro',
        'description': 'Bocina de alta potencia y fidelidad de sonido.',
        'price': 300.0,
        'imagePath': 'assets/images/equipment/bocina_jbl.png',
        'categoryId': audioId,
      });

      // Equipos de Video
      await db.insert('equipment', {
        'name': 'Cámara Canon XA40',
        'description': 'Cámara profesional con zoom óptico 20x.',
        'price': 500.0,
        'imagePath': 'assets/images/equipment/canon_xa40.png',
        'categoryId': videoId,
      });
      await db.insert('equipment', {
        'name': 'Trípode Manfrotto',
        'description': 'Trípode estable para cámaras profesionales.',
        'price': 120.0,
        'imagePath': 'assets/images/equipment/tripode.png',
        'categoryId': videoId,
      });

      // Equipos de Iluminación
      await db.insert('equipment', {
        'name': 'Panel LED Neewer',
        'description': 'Luz LED con control de temperatura.',
        'price': 200.0,
        'imagePath': 'assets/images/equipment/panel_led.png',
        'categoryId': iluminacionId,
      });
      await db.insert('equipment', {
        'name': 'Luz Par LED RGB',
        'description': 'Luz escénica multicolor controlable.',
        'price': 180.0,
        'imagePath': 'assets/images/equipment/luz_par.png',
        'categoryId': iluminacionId,
      });

      // Equipos de Sonido
      await db.insert('equipment', {
        'name': 'Consola Behringer Xenyx',
        'description': 'Mezcladora de 8 canales con efectos.',
        'price': 350.0,
        'imagePath': 'assets/images/equipment/console_xenyx.png',
        'categoryId': sonidoId,
      });
      await db.insert('equipment', {
        'name': 'Monitor de escenario Yamaha',
        'description': 'Altavoz pasivo para monitoreo en vivo.',
        'price': 275.0,
        'imagePath': 'assets/images/equipment/monitor_yamaha.png',
        'categoryId': sonidoId,
      });
    }
  }
}
