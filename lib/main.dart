// ============================================================
// SPIT Campus Canteen App — main.dart
// Place this file inside your Flutter project's /lib folder.
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

// ─────────────────────────────────────────────────────────
//  ENTRY POINT
// ─────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseMessaging.instance.requestPermission();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const CanteenApp(),
    ),
  );
}

// ─────────────────────────────────────────────────────────
//  CONSTANTS
// ─────────────────────────────────────────────────────────
class AppColors {
  static const primary = Color(0xFFD64000); // deep saffron-orange
  static const secondary = Color(0xFF1A1A2E); // dark navy
  static const accent = Color(0xFFFFB703); // golden yellow
  static const bg = Color(0xFFF5F0EB); // warm off-white
  static const cardBg = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF1A1A2E);
  static const textMuted = Color(0xFF6B7280);
  static const success = Color(0xFF22C55E);
  static const error = Color(0xFFEF4444);
}

class AppTextStyles {
  static const displayLarge = TextStyle(
    fontFamily: 'Playfair Display',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
    height: 1.15,
  );
  static const titleLarge = TextStyle(
    fontFamily: 'Playfair Display',
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );
  static const bodyMedium = TextStyle(
    fontFamily: 'Lato',
    fontSize: 14,
    color: AppColors.textDark,
    height: 1.5,
  );
  static const labelSmall = TextStyle(
    fontFamily: 'Lato',
    fontSize: 12,
    color: AppColors.textMuted,
    letterSpacing: 0.4,
  );
  static const priceLarge = TextStyle(
    fontFamily: 'Lato',
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
  );
}

// ─────────────────────────────────────────────────────────
//  ADMIN CREDENTIALS (hardcoded, obfuscated at build time)
// ─────────────────────────────────────────────────────────
const _adminEmail = 'sujalmeshram612@gmail.com';
const _adminPassword = '#PASSword12!';

const _genderOptions = ['Male', 'Female', 'Prefer not to say'];
const _branchOptions = ['CSE', 'EXTC', 'COMS'];
const _divisionOptions = ['A', 'B', 'C', 'D'];

List<String> classOptionsForBranch(String? branch) {
  const base = [
    '1st Year BTech',
    '2nd Year BTech',
    '3rd Year BTech',
    '4th Year BTech',
    'FYMTech',
    'SYMTech',
  ];
  if (branch == 'CSE') {
    return [...base, 'FYMCA', 'SYMCA'];
  }
  return base;
}

final _starterMenu = <Map<String, dynamic>>[
  {
    'name': 'Vada Pav',
    'description': 'Mumbai-style potato slider with chutneys.',
    'price': 20.0,
    'category': 'Snacks',
    'isVeg': true,
    'imageHint': 'menu/vada_pav.jpg'
  },
  {
    'name': 'Samosa (2 pcs)',
    'description': 'Crisp pastry with spiced potato filling.',
    'price': 25.0,
    'category': 'Snacks',
    'isVeg': true,
    'imageHint': 'menu/samosa.jpg'
  },
  {
    'name': 'Poha',
    'description': 'Light flattened rice with peanuts and coriander.',
    'price': 35.0,
    'category': 'Breakfast',
    'isVeg': true,
    'imageHint': 'menu/poha.jpg'
  },
  {
    'name': 'Upma',
    'description': 'Savory semolina breakfast with vegetables.',
    'price': 35.0,
    'category': 'Breakfast',
    'isVeg': true,
    'imageHint': 'menu/upma.jpg'
  },
  {
    'name': 'Idli Sambhar (3)',
    'description': 'Three soft idlis served with sambhar.',
    'price': 45.0,
    'category': 'Breakfast',
    'isVeg': true,
    'imageHint': 'menu/idli_sambhar.jpg'
  },
  {
    'name': 'Masala Dosa',
    'description': 'Crisp dosa with spiced potato masala.',
    'price': 60.0,
    'category': 'Breakfast',
    'isVeg': true,
    'imageHint': 'menu/masala_dosa.jpg'
  },
  {
    'name': 'Pav Bhaji',
    'description': 'Buttery pav with spiced mashed vegetables.',
    'price': 70.0,
    'category': 'Meals',
    'isVeg': true,
    'imageHint': 'menu/pav_bhaji.jpg'
  },
  {
    'name': 'Dal Chawal',
    'description': 'Comfort meal of dal and steamed rice.',
    'price': 65.0,
    'category': 'Meals',
    'isVeg': true,
    'imageHint': 'menu/dal_chawal.jpg'
  },
  {
    'name': 'Chicken Biryani',
    'description': 'Fragrant rice layered with spiced chicken.',
    'price': 110.0,
    'category': 'Meals',
    'isVeg': false,
    'imageHint': 'menu/chicken_biryani.jpg'
  },
  {
    'name': 'Egg Fried Rice',
    'description': 'Wok-tossed rice with egg and vegetables.',
    'price': 85.0,
    'category': 'Meals',
    'isVeg': false,
    'imageHint': 'menu/egg_fried_rice.jpg'
  },
  {
    'name': 'Veg Pulao',
    'description': 'Mildly spiced rice with seasonal vegetables.',
    'price': 75.0,
    'category': 'Meals',
    'isVeg': true,
    'imageHint': 'menu/veg_pulao.jpg'
  },
  {
    'name': 'Chole Bhature',
    'description': 'Punjabi chickpeas with fluffy bhature.',
    'price': 80.0,
    'category': 'Meals',
    'isVeg': true,
    'imageHint': 'menu/chole_bhature.jpg'
  },
  {
    'name': 'Chicken Roll',
    'description': 'Roomali-style wrap with spicy chicken filling.',
    'price': 90.0,
    'category': 'Snacks',
    'isVeg': false,
    'imageHint': 'menu/chicken_roll.jpg'
  },
  {
    'name': 'Paneer Sandwich',
    'description': 'Grilled sandwich stuffed with paneer masala.',
    'price': 55.0,
    'category': 'Snacks',
    'isVeg': true,
    'imageHint': 'menu/paneer_sandwich.jpg'
  },
  {
    'name': 'Masala Chai',
    'description': 'Classic ginger-cardamom tea.',
    'price': 15.0,
    'category': 'Drinks',
    'isVeg': true,
    'imageHint': 'menu/masala_chai.jpg'
  },
  {
    'name': 'Cold Coffee',
    'description': 'Chilled coffee blended with milk.',
    'price': 55.0,
    'category': 'Drinks',
    'isVeg': true,
    'imageHint': 'menu/cold_coffee.jpg'
  },
  {
    'name': 'Sugarcane Juice',
    'description': 'Fresh sugarcane juice with lemon.',
    'price': 30.0,
    'category': 'Drinks',
    'isVeg': true,
    'imageHint': 'menu/sugarcane_juice.jpg'
  },
  {
    'name': 'Mango Lassi',
    'description': 'Sweet yogurt shake with mango pulp.',
    'price': 50.0,
    'category': 'Drinks',
    'isVeg': true,
    'imageHint': 'menu/mango_lassi.jpg'
  },
  {
    'name': 'Gulab Jamun (2)',
    'description': 'Two warm gulab jamuns in sugar syrup.',
    'price': 30.0,
    'category': 'Desserts',
    'isVeg': true,
    'imageHint': 'menu/gulab_jamun.jpg'
  },
  {
    'name': 'Jalebi (100g)',
    'description': 'Fresh syrup-soaked jalebi spirals.',
    'price': 35.0,
    'category': 'Desserts',
    'isVeg': true,
    'imageHint': 'menu/jalebi.jpg'
  },
];

final _defaultMenuItems = List<MenuItem>.unmodifiable(
  _starterMenu.asMap().entries.map((entry) {
    final item = entry.value;
    final imageName = (item['imageHint'] as String).split('/').last;
    return MenuItem(
      id: 'asset_${entry.key}',
      name: item['name'] as String,
      description: item['description'] as String,
      imageUrl: 'assets/images/$imageName',
      category: item['category'] as String,
      price: item['price'] as double,
      isVeg: item['isVeg'] as bool,
    );
  }),
);

final _featuredSpecials = List<MenuItem>.unmodifiable([
  _defaultMenuItems[0],
  _defaultMenuItems[5],
  _defaultMenuItems[8],
  _defaultMenuItems[14],
  _defaultMenuItems[18],
]);

class LocalProfilePhotoStore {
  static String _prefsKey(String uid) => 'profile_photo_path_$uid';

  static Future<String?> loadPath(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_prefsKey(uid));
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    return await file.exists() ? path : null;
  }

  static Future<String> savePhoto(String uid, File source) async {
    final dir = await getApplicationDocumentsDirectory();
    final target = File('${dir.path}/profile_$uid.jpg');
    await source.copy(target.path);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey(uid), target.path);
    return target.path;
  }

  static Future<void> clear(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_prefsKey(uid));
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await prefs.remove(_prefsKey(uid));
  }
}

class LocalMenuStore {
  static const _prefsKey = 'local_menu_items_v1';

  static Future<List<MenuItem>> loadMenu() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((entry) {
      final map = Map<String, dynamic>.from(entry as Map);
      return MenuItem.fromMap(map, map['id'] as String);
    }).toList();
  }

  static Future<void> saveMenu(List<MenuItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((item) => {'id': item.id, ...item.toMap()}).toList());
    await prefs.setString(_prefsKey, raw);
  }

  static Future<List<MenuItem>> ensureSeeded() async {
    final existing = await loadMenu();
    if (existing.isNotEmpty) return existing;
    await saveMenu(_defaultMenuItems);
    return _defaultMenuItems;
  }
}

class LocalMenuImageStore {
  static Future<String> saveImage(File source) async {
    final dir = await getApplicationDocumentsDirectory();
    final target = File('${dir.path}/menu_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await source.copy(target.path);
    return target.path;
  }
}

// ─────────────────────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────────────────────
class UserModel {
  final String uid, fullName, email, gender, branch, role;
  final String? ucid, division, classYear, designation, photoUrl, fcmToken;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.gender,
    required this.branch,
    required this.role,
    this.ucid,
    this.division,
    this.classYear,
    this.designation,
    this.photoUrl,
    this.fcmToken,
  });

  factory UserModel.fromMap(Map<String, dynamic> m, String uid) => UserModel(
        uid: uid,
        fullName: m['fullName'],
        email: m['email'],
        gender: m['gender'],
        branch: m['branch'],
        role: m['role'],
        ucid: m['ucid'],
        division: m['division'],
        classYear: m['classYear'],
        designation: m['designation'],
        photoUrl: m['photoUrl'],
        fcmToken: m['fcmToken'],
      );

  Map<String, dynamic> toMap() => {
        'fullName': fullName,
        'email': email,
        'gender': gender,
        'branch': branch,
        'role': role,
        'ucid': ucid,
        'division': division,
        'classYear': classYear,
        'designation': designation,
        'photoUrl': photoUrl,
        'fcmToken': fcmToken,
      };
}

class MenuItem {
  final String id, name, description, imageUrl, category;
  final double price;
  final bool isVeg;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.price,
    required this.isVeg,
  });

  factory MenuItem.fromMap(Map<String, dynamic> m, String id) => MenuItem(
        id: id,
        name: m['name'],
        description: m['description'],
        imageUrl: m['imageUrl'],
        category: m['category'],
        price: (m['price'] as num).toDouble(),
        isVeg: m['isVeg'] ?? true,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'category': category,
        'price': price,
        'isVeg': isVeg,
      };
}

class CartItem {
  final MenuItem item;
  int quantity;
  CartItem({required this.item, this.quantity = 1});
}

class OrderModel {
  final String id, userId, userName, userEmail, status;
  final List<Map<String, dynamic>> items;
  final double total;
  final Timestamp createdAt;
  final String? ucid;

  OrderModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.status,
    required this.items,
    required this.total,
    required this.createdAt,
    this.ucid,
  });

  factory OrderModel.fromMap(Map<String, dynamic> m, String id) => OrderModel(
        id: id,
        userId: m['userId'],
        userName: m['userName'],
        userEmail: m['userEmail'],
        status: m['status'],
        items: List<Map<String, dynamic>>.from(m['items']),
        total: (m['total'] as num).toDouble(),
        createdAt: m['createdAt'],
        ucid: m['ucid'],
      );
}

class UserNotification {
  final String id;
  final String orderId;
  final String title;
  final String message;
  final String status;
  final Timestamp? createdAt;
  final bool read;

  UserNotification({
    required this.id,
    required this.orderId,
    required this.title,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.read,
  });

  factory UserNotification.fromMap(Map<String, dynamic> map, String id) =>
      UserNotification(
        id: id,
        orderId: map['orderId'] ?? '',
        title: map['title'] ?? 'Notification',
        message: map['message'] ?? '',
        status: map['status'] ?? '',
        createdAt: map['createdAt'] as Timestamp?,
        read: map['read'] ?? false,
      );
}

// ─────────────────────────────────────────────────────────
//  PROVIDERS
// ─────────────────────────────────────────────────────────
class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => _items;
  int get itemCount => _items.values.fold(0, (s, e) => s + e.quantity);
  double get total =>
      _items.values.fold(0.0, (s, e) => s + e.item.price * e.quantity);

  void addItem(MenuItem item) {
    if (_items.containsKey(item.id)) {
      if (_items[item.id]!.quantity < 6) {
        _items[item.id]!.quantity++;
        notifyListeners();
      }
    } else {
      _items[item.id] = CartItem(item: item);
      notifyListeners();
    }
  }

  void removeItem(String id) {
    if (_items.containsKey(id)) {
      if (_items[id]!.quantity > 1) {
        _items[id]!.quantity--;
      } else {
        _items.remove(id);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}

class MenuProvider extends ChangeNotifier {
  List<MenuItem> _items = [];
  bool _initialized = false;

  List<MenuItem> get items => _items;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    _items = await LocalMenuStore.ensureSeeded();
    _initialized = true;
    notifyListeners();
  }

  Future<void> addItem(MenuItem item) async {
    _items = [..._items, item];
    await LocalMenuStore.saveMenu(_items);
    notifyListeners();
  }

  Future<void> updateItem(String id, MenuItem updated) async {
    _items = _items.map((item) => item.id == id ? updated : item).toList();
    await LocalMenuStore.saveMenu(_items);
    notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    _items = _items.where((item) => item.id != id).toList();
    await LocalMenuStore.saveMenu(_items);
    notifyListeners();
  }

  Future<void> seedDefaultsIfEmpty() async {
    if (_items.isEmpty) {
      _items = await LocalMenuStore.ensureSeeded();
      notifyListeners();
    }
  }
}

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isAdmin = false;
  String? _localPhotoPath;

  UserModel? get user => _user;
  bool get isAdmin => _isAdmin;
  bool get isLoggedIn => _user != null || _isAdmin;
  String? get localPhotoPath => _localPhotoPath;

  Future<void> loadUser(String uid) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      _user = UserModel.fromMap(doc.data()!, uid);
      _isAdmin = _user!.role == 'admin';
      _localPhotoPath = await LocalProfilePhotoStore.loadPath(uid);
      notifyListeners();
    }
  }

  Future<void> setLocalPhotoPath(String uid, String? path) async {
    _localPhotoPath = path;
    notifyListeners();
  }

  void setAdmin() {
    _isAdmin = true;
    _user = null;
    _localPhotoPath = null;
    notifyListeners();
  }

  void logout() {
    _user = null;
    _isAdmin = false;
    _localPhotoPath = null;
    notifyListeners();
  }
}

// ─────────────────────────────────────────────────────────
//  FIREBASE SERVICE LAYER
// ─────────────────────────────────────────────────────────
class FirebaseService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;
  static final _messaging = FirebaseMessaging.instance;

  // ── Auth ──────────────────────────────────────────────
  static Future<UserCredential> registerWithEmail(
          String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  static Future<void> sendVerificationEmail() => 
      _auth.currentUser!.sendEmailVerification();

  static Future<UserCredential> loginWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  static Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  static Future<void> logout() => _auth.signOut();

  static User? get currentUser => _auth.currentUser;

  // ── Firestore: Users ──────────────────────────────────
  static Future<void> createUserDoc(UserModel user) =>
      _db.collection('users').doc(user.uid).set({
        ...user.toMap(),
        'emailLower': user.email.toLowerCase(),
      });

  static Future<void> updateUserDoc(String uid, Map<String, dynamic> data) {
    // Replace null values with FieldValue.delete() so Firestore fields are
    // actually removed rather than left with a null/error value.
    final cleaned = data.map((k, v) =>
        MapEntry(k, v == null ? FieldValue.delete() : v));
    return _db.collection('users').doc(uid).update(cleaned);
  }

  static Future<bool> emailExists(String email) async {
    final snap = await _db
        .collection('users')
        .where('emailLower', isEqualTo: email.toLowerCase())
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  static Future<bool> ucidExists(String ucid) async {
    final snap = await _db
        .collection('users')
        .where('ucid', isEqualTo: ucid)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // ── Firestore: Menu ───────────────────────────────────
  static Stream<QuerySnapshot> menuStream() =>
      _db.collection('menu').orderBy('category').snapshots();

  static Future<void> addMenuItem(MenuItem item) =>
      _db.collection('menu').add(item.toMap());

  static Future<void> updateMenuItem(String id, Map<String, dynamic> data) =>
      _db.collection('menu').doc(id).update(data);

  static Future<void> deleteMenuItem(String id) =>
      _db.collection('menu').doc(id).delete();

  static Future<void> seedDefaultMenu() async {
    final existing = await _db.collection('menu').limit(1).get();
    if (existing.docs.isNotEmpty) return;
    final batch = _db.batch();
    for (final item in _starterMenu) {
      final doc = _db.collection('menu').doc();
      batch.set(doc, {
        'name': item['name'],
        'description': item['description'],
        'price': item['price'],
        'category': item['category'],
        'isVeg': item['isVeg'],
        'imageUrl': '',
        'imageHint': item['imageHint'],
      });
    }
    await batch.commit();
  }

  // ── Firestore: Orders ─────────────────────────────────
  static Future<DocumentReference> placeOrder(Map<String, dynamic> data) =>
      _db.collection('orders').add(data);

  static Stream<QuerySnapshot> userOrdersStream(String uid) => _db
      .collection('orders')
      .where('userId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots();

  static Stream<QuerySnapshot> allOrdersStream() => _db
      .collection('orders')
      .orderBy('createdAt', descending: true)
      .snapshots();

  static Stream<QuerySnapshot> userNotificationsStream(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .snapshots();

  static Future<void> markNotificationRead(String uid, String notificationId) =>
      _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});

  static Future<void> markAllNotificationsRead(String uid) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  static Future<void> updateOrderStatus(String id, String status) async {
    final orderRef = _db.collection('orders').doc(id);
    final orderSnap = await orderRef.get();
    if (!orderSnap.exists) return;

    final order = OrderModel.fromMap(orderSnap.data()!, orderSnap.id);
    if (order.status == status) return;

    await orderRef.update({'status': status});

    final notificationRef = _db
        .collection('users')
        .doc(order.userId)
        .collection('notifications')
        .doc();

    try {
      await notificationRef.set({
        'orderId': order.id,
        'title': 'Order status updated',
        'message':
            'Your order #${order.id.substring(0, 8)} moved from ${order.status} to $status.',
        'status': status,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Notification write failed for order status update: $e');
    }
  }

  // ── Storage: Images ───────────────────────────────────
  static Future<String> uploadImage(File file, String path) async {
    final ref = _storage.ref().child(path);
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  // ── FCM token ─────────────────────────────────────────
  static Future<String?> getFcmToken() => _messaging.getToken();
}

Future<void> downloadInvoicePdf(BuildContext context, OrderModel order) async {
  try {
    final pdfFile = await PdfService.generateInvoice(order);
    await OpenFile.open(pdfFile.path);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Invoice PDF opened successfully.'),
      backgroundColor: AppColors.success,
    ));
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Failed to generate invoice: $e'),
      backgroundColor: AppColors.error,
    ));
  }
}

// ─────────────────────────────────────────────────────────
//  PDF GENERATOR
// ─────────────────────────────────────────────────────────
class PdfService {
  static pw.Font? _regularFont;
  static pw.Font? _boldFont;

  static Future<pw.Font> _loadRegularFont() async {
    if (_regularFont != null) return _regularFont!;
    final data = await rootBundle.load('assets/fonts/Lato-Regular.ttf');
    _regularFont = pw.Font.ttf(data);
    return _regularFont!;
  }

  static Future<pw.Font> _loadBoldFont() async {
    if (_boldFont != null) return _boldFont!;
    final data = await rootBundle.load('assets/fonts/Lato-Bold.ttf');
    _boldFont = pw.Font.ttf(data);
    return _boldFont!;
  }

  static Future<File> generateInvoice(OrderModel order) async {
    final regular = await _loadRegularFont();
    final bold = await _loadBoldFont();
    final pdf = pw.Document();
    const rupee = '\u20B9';
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('SPIT Campus Canteen',
                style: pw.TextStyle(
                    fontSize: 22, fontWeight: pw.FontWeight.bold, font: bold)),
            pw.Text('SPIT Pvt. Ltd.', style: const pw.TextStyle(fontSize: 12)),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text('Invoice / Order Receipt',
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold, font: bold)),
            pw.SizedBox(height: 8),
            pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Order ID: ${order.id.substring(0, 8)}'),
                  pw.Text(
                      'Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(
                                order.createdAt != null
                                    ? order.createdAt.toDate()
                                    : DateTime.now(),
                              )}'),
                ]),
            pw.SizedBox(height: 8),
            pw.Text('Customer: ${order.userName}'),
            pw.Text('Email: ${order.userEmail}'),
            if (order.ucid != null) pw.Text('UCID: ${order.ucid}'),
            pw.SizedBox(height: 12),
            pw.Divider(),
            pw.TableHelper.fromTextArray(
              headers: ['Item', 'Qty', 'Price', 'Subtotal'],
              data: order.items.map((i) => [
                    i['name'],
                    i['quantity'].toString(),
                    NumberFormat.currency(locale: 'en_IN', symbol: '₹')
                        .format((i['price'] as num).toDouble()),
                    NumberFormat.currency(locale: 'en_IN', symbol: '₹')
                        .format((i['price'] as num).toDouble() *
                            (i['quantity'] as num)),
                  ]).toList(),
            ),
            pw.Divider(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
  'Total: ${NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(order.total)}',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 12),
            pw.Text('Payment Mode: Pay at Pickup',
                style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 20),
            pw.Center(
                child: pw.Text('Thank you for your order!',
                    style: const pw.TextStyle(fontSize: 12))),
            pw.Center(
                child: pw.Text('SPIT Pvt. Ltd.',
                    style: const pw.TextStyle(fontSize: 11))),
          ],
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final invoiceDir = Directory('${dir.path}/invoices');
    if (!await invoiceDir.exists()) {
      await invoiceDir.create(recursive: true);
    }
    final file = File(
      '${invoiceDir.path}/invoice_${order.id.substring(0, 8)}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}

// ─────────────────────────────────────────────────────────
//  VALIDATORS
// ─────────────────────────────────────────────────────────
class Validators {
  static String? email(String? v) {
    if (v == null || v.isEmpty) return 'Email is required';
    if (!RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
        .hasMatch(v)) {
      return 'Enter a valid email';
    }
    return null;
  }

  static String? ucid(String? v) {
    if (v == null || v.isEmpty) return 'UCID is required';
    if (!RegExp(r'^\d{10}$').hasMatch(v))
      return 'UCID must be exactly 10 digits';
    return null;
  }

  static String? required(String? v, [String label = 'This field']) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    return null;
  }

  static PasswordStrength passwordStrength(String p) {
    int score = 0;
    if (p.length >= 8) score++;
    if (RegExp(r'[a-z]').hasMatch(p)) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'\d').hasMatch(p)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(p)) score++;
    if (score <= 2) return PasswordStrength.weak;
    if (score <= 3) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }
}

enum PasswordStrength { weak, medium, strong }

// ─────────────────────────────────────────────────────────
//  APP ROOT
// ─────────────────────────────────────────────────────────
class CanteenApp extends StatelessWidget {
  const CanteenApp({super.key});
  

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SPIT Canteen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
        fontFamily: 'Lato',
        scaffoldBackgroundColor: AppColors.bg,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(
                fontFamily: 'Lato', fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelStyle: AppTextStyles.labelSmall
              .copyWith(fontSize: 14, color: AppColors.textMuted),
        ),
      ),
      home: const AuthGateScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  AUTH GATE
// ─────────────────────────────────────────────────────────
class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});
  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final user = FirebaseService.currentUser;
    if (user != null) {
      await user.reload();
      if (user.emailVerified) {
        if (user.email == _adminEmail) {
          context.read<AuthProvider>().setAdmin();
          _go(const AdminShellScreen());
        } else {
          await context.read<AuthProvider>().loadUser(user.uid);
          _go(const UserShellScreen());
        }
      } else {
        _go(const VerifyEmailScreen());
      }
    } else {
      _go(const LandingScreen());
    }
  }

  void _go(Widget screen) => Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 72, color: Colors.white),
            SizedBox(height: 16),
            Text('SPIT Canteen',
                style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text('SPIT Pvt. Ltd.',
                style: TextStyle(
                    color: Colors.white70, fontSize: 14, fontFamily: 'Lato')),
            SizedBox(height: 32),
            CircularProgressIndicator(color: Colors.white),
          ],
        )),
      );
}

// ─────────────────────────────────────────────────────────
//  LANDING SCREEN
// ─────────────────────────────────────────────────────────
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.secondary]),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                const Icon(Icons.restaurant_menu,
                    size: 80, color: Colors.white),
                const SizedBox(height: 20),
                const Text('SPIT\nCanteen',
                    style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 52,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1)),
                const SizedBox(height: 12),
                Text('Order food. Skip the queue.',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 18,
                        fontFamily: 'Lato')),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary),
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: const Text('Student / Faculty Login'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen(adminOnly: true)),
                    ),
                    child: const Text('Admin Login',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen())),
                    child: const Text('Register',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 24),
                const Center(
                    child: Text('SPIT Pvt. Ltd.',
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontFamily: 'Lato'))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  LOGIN SCREEN
// ─────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  final bool adminOnly;

  const LoginScreen({super.key, this.adminOnly = false});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false, _showPass = false;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.adminOnly &&
          _emailCtrl.text.trim().toLowerCase() != _adminEmail) {
        setState(() {
          _error = 'Use the admin email for admin login.';
          _loading = false;
        });
        return;
      }
      final cred = await FirebaseService.loginWithEmail(
          _emailCtrl.text.trim(), _passwordCtrl.text);
      final user = cred.user!;
      await user.reload();
      if (!user.emailVerified) {
        setState(() {
          _error = 'Please verify your email before logging in.';
          _loading = false;
        });
        return;
      }
      if (user.email == _adminEmail) {
        context.read<AuthProvider>().setAdmin();
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AdminShellScreen()),
            (_) => false);
      } else {
        await context.read<AuthProvider>().loadUser(user.uid);
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const UserShellScreen()),
            (_) => false);
      }
    } on FirebaseAuthException catch (e) {

      setState(() {
        _error = _authError(e.code);
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_error!)),
      );
    }
  }

  String _authError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return 'Login failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.adminOnly ? 'Admin Login' : 'Login')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Text(widget.adminOnly ? 'Admin access' : 'Welcome back!',
                      style: AppTextStyles.displayLarge),
                  const SizedBox(height: 4),
                  Text(
                    widget.adminOnly
                        ? 'Login to manage orders and menu'
                        : 'Login to continue ordering',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 32),
                  if (_error != null) _ErrorBanner(_error!),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined)),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                      controller: _passwordCtrl,
                      obscureText: !_showPass,
                      decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                              icon: Icon(_showPass
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () =>
                                  setState(() => _showPass = !_showPass))),
                      validator: (v) => Validators.required(v, 'Password')),
                  const SizedBox(height: 8),
                  Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const ForgotPasswordScreen())),
                          child: const Text('Forgot Password?',
                              style: TextStyle(color: AppColors.primary)))),
                  const SizedBox(height: 16),
                  _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary))
                      : ElevatedButton(
                          onPressed: _login, child: const Text('Login')),
                  const SizedBox(height: 32),
                  const _Footer(),
                ]),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────
//  FORGOT PASSWORD SCREEN
// ─────────────────────────────────────────────────────────
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _sent = false, _loading = false;
  String? _error;

  Future<void> _send() async {
    if (_emailCtrl.text.isEmpty) {
      setState(() => _error = 'Enter your email');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await FirebaseService.sendPasswordReset(_emailCtrl.text.trim());
      setState(() {
        _sent = true;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Failed to send reset email.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Forgot Password')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: _sent
              ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.mark_email_read,
                      size: 80, color: AppColors.success),
                  const SizedBox(height: 16),
                  const Text('Reset link sent!',
                      style: AppTextStyles.titleLarge),
                  const SizedBox(height: 8),
                  Text('Check your inbox at ${_emailCtrl.text}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 24),
                  ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back to Login')),
                ])
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                      const SizedBox(height: 24),
                      Text('Reset Password', style: AppTextStyles.displayLarge),
                      const SizedBox(height: 8),
                      Text('Enter your registered email address',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textMuted)),
                      const SizedBox(height: 32),
                      if (_error != null) _ErrorBanner(_error!),
                      TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined))),
                      const SizedBox(height: 24),
                      _loading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary))
                          : ElevatedButton(
                              onPressed: _send,
                              child: const Text('Send Reset Link')),
                    ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────
//  REGISTER SCREEN
// ─────────────────────────────────────────────────────────
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String _userType = 'student';
  String? _gender, _branch, _classYear, _division;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _ucid = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _designation = TextEditingController();
  bool _showPass = false, _showConfirmPass = false, _loading = false;
  String? _error;

  List<String> get _classOptions => classOptionsForBranch(_branch);

  PasswordStrength get _strength => Validators.passwordStrength(_password.text);
  PasswordStrength get _confirmStrength =>
      Validators.passwordStrength(_confirmPassword.text);

  void _resetFormForUserType(String userType) {
    _formKey.currentState?.reset();
    _userType = userType;
    _gender = null;
    _branch = null;
    _classYear = null;
    _division = null;
    _error = null;
    _name.clear();
    _email.clear();
    _ucid.clear();
    _password.clear();
    _confirmPassword.clear();
    _designation.clear();
  }

  Future<void> _register() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    // Extra guard: confirm password match (belt-and-suspenders)
    if (_password.text != _confirmPassword.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    UserCredential? cred;
    try {
      // Step 1: Create Firebase Auth account
      cred = await FirebaseService.registerWithEmail(
        _email.text.trim(), _password.text);

      // Step 2: Send verification email (non-fatal if it fails)
      try {
        await FirebaseService.sendVerificationEmail();
      } catch (e) {
        debugPrint('Verification email failed (non-fatal): $e');
      }

      // Step 3: Get FCM token (non-fatal if it fails)
      String? token;
      try {
        token = await FirebaseService.getFcmToken()
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        token = null;
      }

      // Step 4: Save user document to Firestore
      final userModel = UserModel(
        uid: cred.user!.uid,
        fullName: _name.text.trim(),
        email: _email.text.trim(),
        gender: _gender!,
        branch: _branch!,
        role: _userType,
        ucid: _userType == 'student' ? _ucid.text.trim() : null,
        division: _userType == 'student' ? _division : null,
        classYear: _userType == 'student' ? _classYear : null,
        designation: _userType == 'faculty' ? _designation.text.trim() : null,
        fcmToken: token,
      );
      await FirebaseService.createUserDoc(userModel);

      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const VerifyEmailScreen()));

    } on FirebaseAuthException catch (e) {
      // If Firestore doc creation failed after auth, delete the orphan account
      if (cred != null) {
        try { await cred.user?.delete(); } catch (_) {}
      }
      if (!mounted) return;
      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'This email is already registered.';
          break;
        case 'invalid-email':
          msg = 'The email address is invalid.';
          break;
        case 'weak-password':
          msg = 'Password is too weak. Use at least 8 characters.';
          break;
        case 'network-request-failed':
          msg = 'No internet connection. Please try again.';
          break;
        default:
          msg = 'Registration failed (${e.code}). Please try again.';
      }
      setState(() => _error = msg);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));

    } catch (e) {
      // Firestore write or other error after auth account was created
      if (cred != null) {
        try { await cred.user?.delete(); } catch (_) {}
      }
      if (!mounted) return;
      final msg = 'Registration failed: ${e.toString().split(']').last.trim()}';
      setState(() => _error = msg);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));

    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _ucid.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _designation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Create Account')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User Type Toggle
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300)),
                    child: Row(
                        children: ['student', 'faculty']
                            .map((t) => Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() {
                                      if (_userType == t) return;
                                      _resetFormForUserType(t);
                                    }),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      decoration: BoxDecoration(
                                        color: _userType == t
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(11),
                                      ),
                                      child: Text(t.capitalize,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: _userType == t
                                                  ? Colors.white
                                                  : AppColors.textMuted,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'Lato')),
                                    ),
                                  ),
                                ))
                            .toList()),
                  ),
                  const SizedBox(height: 20),
                  if (_error != null) _ErrorBanner(_error!),

                  // Full Name
                  TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline)),
                      validator: (v) => Validators.required(v, 'Full Name')),
                  const SizedBox(height: 14),

                  // UCID (Student only)
                  if (_userType == 'student') ...[
                    TextFormField(
                        controller: _ucid,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10)
                        ],
                        decoration: const InputDecoration(
                            labelText: 'UCID (10 digits)',
                            prefixIcon: Icon(Icons.badge_outlined)),
                        validator: Validators.ucid),
                    const SizedBox(height: 14),
                  ],

                  // Email
                  TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined)),
                      validator: Validators.email),
                  const SizedBox(height: 14),

                  // Gender
                  _DropdownField<String>(
                      label: 'Gender',
                      prefixIcon: Icons.wc,
                      value: _gender,
                      items: _genderOptions,
                      onChanged: (v) => setState(() => _gender = v),
                      validator: (_) =>
                          _gender == null ? 'Select gender' : null),
                  const SizedBox(height: 14),

                  // Branch
                  _DropdownField<String>(
                      label: 'Branch',
                      prefixIcon: Icons.school_outlined,
                      value: _branch,
                      items: _branchOptions,
                      onChanged: (v) => setState(() {
                            _branch = v;
                            _classYear = null;
                          }),
                      validator: (_) =>
                          _branch == null ? 'Select branch' : null),
                  const SizedBox(height: 14),

                  // Class (Student only)
                  if (_userType == 'student') ...[
                    _DropdownField<String>(
                        label: 'Class / Year',
                        prefixIcon: Icons.class_outlined,
                        value: _classYear,
                        items: _classOptions,
                        onChanged: (v) => setState(() => _classYear = v),
                        validator: (_) =>
                            _classYear == null ? 'Select class' : null),
                    const SizedBox(height: 14),
                    _DropdownField<String>(
                        label: 'Division',
                        prefixIcon: Icons.group_outlined,
                        value: _division,
                        items: _divisionOptions,
                        onChanged: (v) => setState(() => _division = v),
                        validator: (_) =>
                            _division == null ? 'Select division' : null),
                    const Padding(
                      padding: EdgeInsets.only(left: 4, top: 4),
                      child: Text('ℹ️ Select A if you are in the only division',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Designation (Faculty only)
                  if (_userType == 'faculty') ...[
                    TextFormField(
                        controller: _designation,
                        decoration: const InputDecoration(
                            labelText: 'Designation',
                            prefixIcon: Icon(Icons.work_outline)),
                        validator: (v) =>
                            Validators.required(v, 'Designation')),
                    const SizedBox(height: 14),
                  ],

                  // Password
                  TextFormField(
                      controller: _password,
                      obscureText: !_showPass,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                              icon: Icon(_showPass
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () =>
                                  setState(() => _showPass = !_showPass))),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Password is required';
                        if (v.length < 8) return 'Minimum 8 characters';
                        if (Validators.passwordStrength(v) ==
                            PasswordStrength.weak)
                          return 'Password is too weak';
                        return null;
                      }),
                  const SizedBox(height: 8),
                  _PasswordStrengthBar(
                      strength: _strength, password: _password.text),
                  const SizedBox(height: 14),

                  TextFormField(
                      controller: _confirmPassword,
                      obscureText: !_showConfirmPass,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                              icon: Icon(_showConfirmPass
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(() =>
                                  _showConfirmPass = !_showConfirmPass))),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Confirm password is required';
                        if (v.length < 8) return 'Minimum 8 characters';
                        if (Validators.passwordStrength(v) ==
                            PasswordStrength.weak)
                          return 'Password is too weak';
                        if (v != _password.text) return 'Passwords do not match';
                        return null;
                      }),
                  const SizedBox(height: 8),
                  _PasswordStrengthBar(
                      strength: _confirmStrength,
                      password: _confirmPassword.text),
                  const SizedBox(height: 24),

                  _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary))
                      : ElevatedButton(
                          onPressed: _register,
                          child: const Text('Create Account')),
                  const SizedBox(height: 32),
                  const _Footer(),
                ]),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────
//  EMAIL VERIFICATION SCREEN
// ─────────────────────────────────────────────────────────
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});
  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _checking = false;

  Future<void> _checkVerified() async {
    setState(() => _checking = true);
    await FirebaseService.currentUser?.reload();
    if (FirebaseService.currentUser?.emailVerified == true) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const UserShellScreen()),
          (_) => false);
    } else {
      setState(() => _checking = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Email not yet verified. Please check your inbox.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.mark_email_unread_outlined,
                size: 90, color: AppColors.primary),
            const SizedBox(height: 24),
            Text('Verify your Email', style: AppTextStyles.displayLarge),
            const SizedBox(height: 12),
            Text(
                'A verification email was sent to ${FirebaseService.currentUser?.email ?? ''}.\nPlease verify to continue.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 32),
            _checking
                ? const CircularProgressIndicator(color: AppColors.primary)
                : ElevatedButton(
                    onPressed: _checkVerified,
                    child: const Text("I've Verified My Email")),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                await FirebaseService.sendVerificationEmail();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Verification email resent!')));
              },
              child: const Text('Resend Email',
                  style: TextStyle(color: AppColors.primary)),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                FirebaseService.logout();
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LandingScreen()),
                    (_) => false);
              },
              child: const Text('Back to Login',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────
//  USER SHELL (Bottom Nav + Drawer)
//  Single Scaffold hosts the drawer. Child pages are NOT
//  Scaffolds — they return plain body widgets so that
//  Scaffold.of(context).openDrawer() always finds THIS one.
// ─────────────────────────────────────────────────────────
class UserShellScreen extends StatefulWidget {
  const UserShellScreen({super.key});
  @override
  State<UserShellScreen> createState() => _UserShellScreenState();
}

class _UserShellScreenState extends State<UserShellScreen> {
  int _tab = 0;
  StreamSubscription<QuerySnapshot>? _orderStatusSubscription;
  final Set<String> _knownNotificationIds = {};
  bool _notificationFeedPrimed = false;

  static const _titles = ['SPIT Canteen', 'Menu', 'Cart'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = context.read<AuthProvider>().user?.uid;
    if (userId == null || _orderStatusSubscription != null) return;
    _orderStatusSubscription =
        FirebaseService.userNotificationsStream(userId).listen((snapshot) {
      for (final doc in snapshot.docs) {
        final notification = UserNotification.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        if (_notificationFeedPrimed &&
            !_knownNotificationIds.contains(notification.id) &&
            mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(notification.message),
              backgroundColor: AppColors.primary,
            ),
          );
        }
        _knownNotificationIds.add(notification.id);
      }
      _notificationFeedPrimed = true;
    });
  }

  @override
  void dispose() {
    _orderStatusSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final cart = context.watch<CartProvider>();
    final localPhotoPath = context.watch<AuthProvider>().localPhotoPath;
    return Scaffold(
      // ── The ONE drawer for the whole user app ──
      drawer: _AppDrawer(user: user),
      appBar: AppBar(
        title: Text(_titles[_tab]),
        actions: [
          if (user != null)
            _NotificationBell(userId: user.uid),
        ],
        leading: Builder(
          builder: (ctx) => Padding(
            padding: const EdgeInsets.all(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => Scaffold.of(ctx).openDrawer(),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: localPhotoPath != null
                    ? FileImage(File(localPhotoPath)) as ImageProvider<Object>
                    : user?.photoUrl != null
                        ? NetworkImage(user!.photoUrl!) as ImageProvider<Object>
                        : null,
                child: localPhotoPath == null && user?.photoUrl == null
                    ? const Icon(Icons.person, color: AppColors.primary)
                    : null,
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _tab,
        children: const [
          _UserHomeBody(),
          _MenuBody(),
          _CartBody(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withOpacity(0.15),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppColors.primary),
              label: 'Home'),
          const NavigationDestination(
              icon: Icon(Icons.restaurant_menu_outlined),
              selectedIcon:
                  Icon(Icons.restaurant_menu, color: AppColors.primary),
              label: 'Menu'),
          NavigationDestination(
              icon: Badge(
                  isLabelVisible: cart.itemCount > 0,
                  label: Text('${cart.itemCount}'),
                  child: const Icon(Icons.shopping_cart_outlined)),
              selectedIcon: Badge(
                  isLabelVisible: cart.itemCount > 0,
                  label: Text('${cart.itemCount}'),
                  child: const Icon(Icons.shopping_cart,
                      color: AppColors.primary)),
              label: 'Cart'),
        ],
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final UserModel? user;
  const _AppDrawer({this.user});
  @override
  Widget build(BuildContext context) {
    final localPhotoPath = context.watch<AuthProvider>().localPhotoPath;
    return Drawer(
      child: SafeArea(
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.primary,
            child: Row(children: [
              CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  backgroundImage: localPhotoPath != null
                      ? FileImage(File(localPhotoPath)) as ImageProvider<Object>
                      : user?.photoUrl != null
                          ? NetworkImage(user!.photoUrl!)
                              as ImageProvider<Object>
                          : null,
                  child: localPhotoPath == null && user?.photoUrl == null
                      ? const Icon(Icons.person,
                          color: AppColors.primary, size: 32)
                      : null),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(user?.fullName ?? 'Guest',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            fontFamily: 'Playfair Display')),
                    Text(user?.email ?? '',
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontFamily: 'Lato'),
                        overflow: TextOverflow.ellipsis),
                  ])),
            ]),
          ),
          ListTile(
              leading:
                  const Icon(Icons.person_outline, color: AppColors.primary),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()));
              }),
          ListTile(
              leading: const Icon(Icons.history, color: AppColors.primary),
              title: const Text('Order History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const OrderHistoryScreen()));
              }),
          ListTile(
              leading: const Icon(Icons.notifications_none,
                  color: AppColors.primary),
              title: const Text('Notifications'),
              onTap: () {
                final userId = user?.uid;
                Navigator.pop(context);
                if (userId == null) return;
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => NotificationScreen(userId: userId)));
              }),
          const Spacer(),
          const Divider(),
          ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text('Logout',
                  style: TextStyle(color: AppColors.error)),
              onTap: () async {
                await FirebaseService.logout();
                context.read<AuthProvider>().logout();
                context.read<CartProvider>().clearCart();
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LandingScreen()),
                    (_) => false);
              }),
          const _Footer(),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  USER HOME BODY  (no Scaffold — lives inside UserShellScreen)
// ─────────────────────────────────────────────────────────
class _UserHomeBody extends StatelessWidget {
  const _UserHomeBody();
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final menuItems = context.watch<MenuProvider>().items;
    final specials =
        (menuItems.isNotEmpty ? menuItems : _defaultMenuItems).take(5).toList();
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
            child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            gradient:
                LinearGradient(colors: [AppColors.primary, Color(0xFFFF6B35)]),
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hello, ${user?.fullName.split(' ').first ?? 'there'} 👋',
                style: const TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 4),
            const Text("What would you like to eat today?",
                style: TextStyle(
                    color: Colors.white70, fontFamily: 'Lato', fontSize: 14)),
          ]),
        )),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverToBoxAdapter(
              child: Text("Today's Specials", style: AppTextStyles.titleLarge)),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _AnimatedSpecialsCarousel(items: specials),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
        const SliverToBoxAdapter(child: _Footer()),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
//  MENU SCREEN
// ─────────────────────────────────────────────────────────
class _MenuBody extends StatefulWidget {
  const _MenuBody();

  @override
  State<_MenuBody> createState() => _MenuBodyState();
}

class _MenuBodyState extends State<_MenuBody> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
                children: [
              'All',
              'Breakfast',
              'Snacks',
              'Meals',
              'Drinks',
              'Desserts'
            ]
                    .map((c) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(c),
                            selected: _filter == c,
                            onSelected: (_) => setState(() => _filter = c),
                            selectedColor: AppColors.primary.withOpacity(0.18),
                            labelStyle: TextStyle(
                              color: _filter == c
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Lato',
                            ),
                          ),
                        ))
                    .toList()),
          ),
        ),
        Expanded(
          child: _MenuListView(filter: _filter),
        ),
      ]);
}

class _CartBody extends StatelessWidget {
  const _CartBody();

  Future<void> _placeOrder(BuildContext context) async {
    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();
    final user = auth.user!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Order', style: AppTextStyles.titleLarge),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total: Rs. ${cart.total.toStringAsFixed(2)}',
                  style: AppTextStyles.priceLarge),
              const SizedBox(height: 8),
              const Text('Payment: Pay at Pickup',
                  style: AppTextStyles.bodyMedium),
              const SizedBox(height: 4),
              const Text('Place this order?', style: AppTextStyles.bodyMedium),
            ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm')),
        ],
      ),
    );

    if (confirmed != true) return;

    final orderData = {
      'userId': user.uid,
      'userName': user.fullName,
      'userEmail': user.email,
      'ucid': user.ucid,
      'status': 'Received',
      'items': cart.items.values
          .map((ci) => {
                'id': ci.item.id,
                'name': ci.item.name,
                'price': ci.item.price,
                'quantity': ci.quantity,
              })
          .toList(),
      'total': cart.total,
      'paymentMode': 'Pay at Pickup',
      'createdAt': FieldValue.serverTimestamp(),
    };

    final docRef = await FirebaseService.placeOrder(orderData);
    cart.clearCart();
    final doc = await docRef.get();
    final order =
        OrderModel.fromMap(doc.data() as Map<String, dynamic>, docRef.id);
    final pdfFile = await PdfService.generateInvoice(order);
    await OpenFile.open(pdfFile.path);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Order placed successfully. Invoice opened.'),
      backgroundColor: AppColors.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    if (cart.items.isEmpty) {
      return const Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
        SizedBox(height: 16),
        Text('Your cart is empty',
            style: TextStyle(
                fontSize: 18, color: AppColors.textMuted, fontFamily: 'Lato')),
      ]));
    }

    return Column(children: [
      Expanded(
          child: ListView(
        padding: const EdgeInsets.all(16),
        children: cart.items.values
            .map((ci) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _MenuImage(
                            imagePath: ci.item.imageUrl,
                            width: 56,
                            height: 56)),
                    title: Text(ci.item.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontFamily: 'Lato')),
                    subtitle: Text(
                        'Rs. ${ci.item.price.toStringAsFixed(0)} x ${ci.quantity}',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.primary)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      _QtyBtn(
                          Icons.remove,
                          () => context
                              .read<CartProvider>()
                              .removeItem(ci.item.id)),
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('${ci.quantity}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16))),
                      _QtyBtn(
                          Icons.add,
                          ci.quantity < 6
                              ? () =>
                                  context.read<CartProvider>().addItem(ci.item)
                              : null),
                    ]),
                  ),
                ))
            .toList(),
      )),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ]),
        child: SafeArea(
          top: false,
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Total', style: AppTextStyles.titleLarge),
              Text('Rs. ${cart.total.toStringAsFixed(2)}',
                  style: AppTextStyles.priceLarge),
            ]),
            const SizedBox(height: 4),
            const Row(children: [
              Icon(Icons.info_outline, size: 14, color: AppColors.textMuted),
              SizedBox(width: 4),
              Text('Payment: Pay at Pickup', style: AppTextStyles.labelSmall),
            ]),
            const SizedBox(height: 16),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _placeOrder(context),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Place Order'),
                )),
          ]),
        ),
      ),
    ]);
  }
}

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: const Text('Menu'),
            leading: Builder(
                builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(ctx).openDrawer()))),
        body: Column(children: [
          // Category filter chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                  children: [
                'All',
                'Breakfast',
                'Snacks',
                'Meals',
                'Drinks',
                'Desserts'
              ]
                      .map((c) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(c),
                              selected: _filter == c,
                              onSelected: (_) => setState(() => _filter = c),
                              selectedColor:
                                  AppColors.primary.withOpacity(0.15),
                              checkmarkColor: AppColors.primary,
                              labelStyle: TextStyle(
                                  color: _filter == c
                                      ? AppColors.primary
                                      : AppColors.textMuted,
                                  fontWeight: FontWeight.w600),
                            ),
                          ))
                      .toList()),
            ),
          ),
          Expanded(
            child: _MenuListView(filter: _filter),
          ),
        ]),
      );
}

class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  const _MenuItemCard({required this.item});
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final qty = cart.items[item.id]?.quantity ?? 0;
    return Container(
      decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: _MenuImage(
              imagePath: item.imageUrl, height: 110, width: double.infinity),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.isVeg ? AppColors.success : AppColors.error,
                      border: Border.all(
                          color: item.isVeg
                              ? AppColors.success
                              : AppColors.error))),
              const SizedBox(width: 4),
              Expanded(
                  child: Text(item.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          fontFamily: 'Lato'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 2),
            Text(item.description,
                style: AppTextStyles.labelSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('₹${item.price.toStringAsFixed(0)}',
                  style: AppTextStyles.priceLarge.copyWith(fontSize: 15)),
              qty == 0
                  ? GestureDetector(
                      onTap: () => context.read<CartProvider>().addItem(item),
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8)),
                          child: const Text('Add',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  fontFamily: 'Lato'))))
                  : Row(children: [
                      _QtyBtn(
                          Icons.remove,
                          () =>
                              context.read<CartProvider>().removeItem(item.id)),
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text('$qty',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700))),
                      _QtyBtn(
                          Icons.add,
                          qty < 6
                              ? () => context.read<CartProvider>().addItem(item)
                              : null),
                    ]),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _MenuListView extends StatelessWidget {
  final String filter;

  const _MenuListView({required this.filter});

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
    final sourceItems = menuProvider.items.isNotEmpty ? menuProvider.items : _defaultMenuItems;
    final items = sourceItems
        .where((item) => filter == 'All' || item.category == filter)
        .toList();
    if (items.isEmpty) {
      return const Center(
          child: Text('No items in this category',
              style: AppTextStyles.bodyMedium));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _MenuListItemCard(item: items[i]),
    );
  }
}

class _MenuListItemCard extends StatelessWidget {
  final MenuItem item;

  const _MenuListItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final qty = cart.items[item.id]?.quantity ?? 0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(20)),
            child:
                _MenuImage(imagePath: item.imageUrl, height: 138, width: 132),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              item.isVeg ? AppColors.success : AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(item.name,
                            style: AppTextStyles.titleLarge
                                .copyWith(fontSize: 18)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(item.category,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.primary)),
                  const SizedBox(height: 8),
                  Text(item.description,
                      style: AppTextStyles.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Rs. ${item.price.toStringAsFixed(0)}',
                          style: AppTextStyles.priceLarge),
                      qty == 0
                          ? ElevatedButton(
                              onPressed: () =>
                                  context.read<CartProvider>().addItem(item),
                              child: const Text('Add'),
                            )
                          : Row(children: [
                              _QtyBtn(
                                  Icons.remove,
                                  () => context
                                      .read<CartProvider>()
                                      .removeItem(item.id)),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Text('$qty',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                              ),
                              _QtyBtn(
                                  Icons.add,
                                  qty < 6
                                      ? () => context
                                          .read<CartProvider>()
                                          .addItem(item)
                                      : null),
                            ]),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuImage extends StatelessWidget {
  final String imagePath;
  final double height;
  final double width;

  const _MenuImage({
    required this.imagePath,
    required this.height,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imageFallback(height, width),
      );
    }
    if (!imagePath.startsWith('http')) {
      return Image.file(
        File(imagePath),
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imageFallback(height, width),
      );
    }
    return CachedNetworkImage(
      imageUrl: imagePath,
      height: height,
      width: width,
      fit: BoxFit.cover,
      placeholder: (_, __) => _imageFallback(height, width),
      errorWidget: (_, __, ___) => _imageFallback(height, width),
    );
  }

  Widget _imageFallback(double height, double width) => Container(
        height: height,
        width: width,
        color: Colors.grey.shade100,
        child: const Icon(Icons.restaurant, color: Colors.grey),
      );
}

class _AnimatedSpecialsCarousel extends StatefulWidget {
  final List<MenuItem> items;

  const _AnimatedSpecialsCarousel({required this.items});

  @override
  State<_AnimatedSpecialsCarousel> createState() =>
      _AnimatedSpecialsCarouselState();
}

class _AnimatedSpecialsCarouselState extends State<_AnimatedSpecialsCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.88);
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_controller.hasClients || widget.items.isEmpty) return;
      _index = (_index + 1) % widget.items.length;
      _controller.animateToPage(
        _index,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.items.length,
        itemBuilder: (_, i) {
          final item = widget.items[i];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFFF8F1E8), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 6))
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(24)),
                    child: _MenuImage(
                        imagePath: item.imageUrl, height: 220, width: 148),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(item.category,
                              style: AppTextStyles.labelSmall
                                  .copyWith(color: AppColors.primary)),
                          const SizedBox(height: 8),
                          Text(item.name, style: AppTextStyles.titleLarge),
                          const SizedBox(height: 8),
                          Text(item.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMedium),
                          const SizedBox(height: 14),
                          Text('Rs. ${item.price.toStringAsFixed(0)}',
                              style: AppTextStyles.priceLarge),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyBtn(this.icon, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: onTap != null ? AppColors.primary : Colors.grey.shade300,
                shape: BoxShape.circle),
            child: Icon(icon, size: 14, color: Colors.white)),
      );
}

// ─────────────────────────────────────────────────────────
//  CART SCREEN
// ─────────────────────────────────────────────────────────
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Future<void> _placeOrder(BuildContext context) async {
    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();
    final user = auth.user!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Order', style: AppTextStyles.titleLarge),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total: ₹${cart.total.toStringAsFixed(2)}',
                  style: AppTextStyles.priceLarge),
              const SizedBox(height: 8),
              const Text('Payment: Pay at Pickup',
                  style: AppTextStyles.bodyMedium),
              const SizedBox(height: 4),
              const Text('Place this order?', style: AppTextStyles.bodyMedium),
            ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm')),
        ],
      ),
    );

    if (confirmed != true) return;

    final orderData = {
      'userId': user.uid,
      'userName': user.fullName,
      'userEmail': user.email,
      'ucid': user.ucid,
      'status': 'Received',
      'items': cart.items.values
          .map((ci) => {
                'id': ci.item.id,
                'name': ci.item.name,
                'price': ci.item.price,
                'quantity': ci.quantity,
              })
          .toList(),
      'total': cart.total,
      'paymentMode': 'Pay at Pickup',
      'createdAt': FieldValue.serverTimestamp(),
    };

    final docRef = await FirebaseService.placeOrder(orderData);
    cart.clearCart();

    // Generate PDF invoice
    final doc = await docRef.get();
    final order =
        OrderModel.fromMap(doc.data() as Map<String, dynamic>, docRef.id);
    final pdfFile = await PdfService.generateInvoice(order);
    await OpenFile.open(pdfFile.path);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('🎉 Order placed! Invoice downloaded.'),
        backgroundColor: AppColors.success));
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(
          title: const Text('Your Cart'),
          leading: Builder(
              builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(ctx).openDrawer()))),
      body: cart.items.isEmpty
          ? const Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Your cart is empty',
                      style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textMuted,
                          fontFamily: 'Lato')),
                ]))
          : Column(children: [
              Expanded(
                  child: ListView(
                padding: const EdgeInsets.all(16),
                children: cart.items.values
                    .map((ci) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                    imageUrl: ci.item.imageUrl,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) =>
                                        const Icon(Icons.restaurant))),
                            title: Text(ci.item.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Lato')),
                            subtitle: Text(
                                '₹${ci.item.price.toStringAsFixed(0)} × ${ci.quantity}',
                                style: AppTextStyles.labelSmall
                                    .copyWith(color: AppColors.primary)),
                            trailing:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              _QtyBtn(
                                  Icons.remove,
                                  () => context
                                      .read<CartProvider>()
                                      .removeItem(ci.item.id)),
                              Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('${ci.quantity}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16))),
                              _QtyBtn(
                                  Icons.add,
                                  ci.quantity < 6
                                      ? () => context
                                          .read<CartProvider>()
                                          .addItem(ci.item)
                                      : null),
                            ]),
                          ),
                        ))
                    .toList(),
              )),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4))
                ]),
                child: SafeArea(
                  child: Column(children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total', style: AppTextStyles.titleLarge),
                          Text('₹${cart.total.toStringAsFixed(2)}',
                              style: AppTextStyles.priceLarge),
                        ]),
                    const SizedBox(height: 4),
                    const Row(children: [
                      Icon(Icons.info_outline,
                          size: 14, color: AppColors.textMuted),
                      SizedBox(width: 4),
                      Text('Payment: Pay at Pickup',
                          style: AppTextStyles.labelSmall)
                    ]),
                    const SizedBox(height: 16),
                    SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _placeOrder(context),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Place Order'),
                        )),
                  ]),
                ),
              ),
            ]),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  ORDER HISTORY SCREEN
// ─────────────────────────────────────────────────────────
class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().user!.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Order History')),
      body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseService.userOrdersStream(uid),
          builder: (ctx, snap) {
            if (!snap.hasData)
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary));
            if (snap.data!.docs.isEmpty)
              return const Center(
                  child:
                      Text('No orders yet', style: AppTextStyles.bodyMedium));
            return ListView(
              padding: const EdgeInsets.all(16),
              children: snap.data!.docs.map((d) {
                final order =
                    OrderModel.fromMap(d.data() as Map<String, dynamic>, d.id);
                return _OrderCard(order: order);
              }).toList(),
            );
          }),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final String userId;
  const _NotificationBell({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.userNotificationsStream(userId),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final unread = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['read'] != true;
        }).length;
        return IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NotificationScreen(userId: userId),
              ),
            );
          },
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text('$unread'),
            child: const Icon(Icons.notifications_none),
          ),
        );
      },
    );
  }
}

class NotificationScreen extends StatelessWidget {
  final String userId;
  const NotificationScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => FirebaseService.markAllNotificationsRead(userId),
            child: const Text(
              'Mark all read',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService.userNotificationsStream(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet',
                style: AppTextStyles.bodyMedium,
              ),
            );
          }

          final notifications = snapshot.data!.docs
              .map((doc) => UserNotification.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ))
              .toList();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final createdAt = notification.createdAt?.toDate();
              return Card(
                color:
                    notification.read ? Colors.white : AppColors.bg,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: const Icon(
                      Icons.notifications_active_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    notification.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Lato',
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(notification.message, style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 8),
                      Text(
                        createdAt == null
                            ? 'Just now'
                            : DateFormat('dd MMM yyyy, hh:mm a')
                                .format(createdAt),
                        style: AppTextStyles.labelSmall,
                      ),
                    ],
                  ),
                  trailing: notification.read
                      ? null
                      : const Icon(Icons.fiber_manual_record,
                          size: 12, color: AppColors.primary),
                  onTap: () =>
                      FirebaseService.markNotificationRead(userId, notification.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  Color _statusColor(String s) {
    switch (s) {
      case 'Received':
        return AppColors.accent;
      case 'Preparing':
        return AppColors.primary;
      case 'Ready to Pick Up':
        return AppColors.success;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Order #${order.id.substring(0, 8)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontFamily: 'Lato')),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: _statusColor(order.status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(order.status,
                      style: TextStyle(
                          color: _statusColor(order.status),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          fontFamily: 'Lato'))),
            ]),
            const SizedBox(height: 8),
            ...order.items.map((i) => Text('• ${i['name']} × ${i['quantity']}',
                style: AppTextStyles.bodyMedium)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('₹${order.total.toStringAsFixed(2)}',
                  style: AppTextStyles.priceLarge),
              Text(
                  DateFormat('dd MMM, hh:mm a')
                      .format(order.createdAt.toDate()),
                  style: AppTextStyles.labelSmall),
            ]),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => downloadInvoicePdf(context, order),
                icon: const Icon(Icons.download_outlined),
                label: const Text('Download Invoice'),
              ),
            ),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────
//  PROFILE SCREEN
// ─────────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _uploading = false;
  File? _localPhotoFile;

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final xfile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (xfile == null) return;
    final file = File(xfile.path);
    setState(() { _uploading = true; _localPhotoFile = file; });
    try {
      final uid = context.read<AuthProvider>().user!.uid;
      final savedPath = await LocalProfilePhotoStore.savePhoto(uid, file);
      await context.read<AuthProvider>().setLocalPhotoPath(uid, savedPath);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Profile photo updated.'),
        backgroundColor: AppColors.success,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Profile upload failed: $e'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removePhoto() async {
    final uid = context.read<AuthProvider>().user!.uid;
    setState(() => _uploading = true);
    try {
      await LocalProfilePhotoStore.clear(uid);
      // Also clear from Firestore if there was a remote URL stored
      await FirebaseService.updateUserDoc(uid, {'photoUrl': null});
      await context.read<AuthProvider>().setLocalPhotoPath(uid, null);
      if (!mounted) return;
      setState(() => _localPhotoFile = null);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Profile photo removed.'),
        backgroundColor: AppColors.success,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to remove photo: $e'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showPhotoOptions() {
    final localPhotoPath = context.read<AuthProvider>().localPhotoPath;
    final hasPhoto = _localPhotoFile != null ||
        localPhotoPath != null ||
        context.read<AuthProvider>().user?.photoUrl != null;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          const Text('Profile Photo',
              style: TextStyle(fontFamily: 'Playfair Display',
                  fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
            ),
            title: Text(hasPhoto ? 'Change Photo' : 'Upload Photo',
                style: const TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.w600)),
            subtitle: const Text('Choose from your gallery',
                style: TextStyle(fontFamily: 'Lato')),
            onTap: () {
              Navigator.pop(context);
              _pickAndUploadPhoto();
            },
          ),
          if (hasPhoto)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.delete_outline, color: AppColors.error),
              ),
              title: const Text('Remove Photo',
                  style: TextStyle(fontFamily: 'Lato',
                      fontWeight: FontWeight.w600, color: AppColors.error)),
              subtitle: const Text('Revert to default avatar',
                  style: TextStyle(fontFamily: 'Lato')),
              onTap: () async {
                Navigator.pop(context);
                // Ask for confirmation before removing
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Remove Photo'),
                    content: const Text(
                        'Are you sure you want to remove your profile photo?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel')),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Remove')),
                    ],
                  ),
                );
                if (confirmed == true) _removePhoto();
              },
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted, fontFamily: 'Lato')),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final localPhotoPath = context.watch<AuthProvider>().localPhotoPath;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: user == null
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => EditProfileScreen(user: user)),
                    ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          GestureDetector(
            onTap: _uploading ? null : _showPhotoOptions,
            child: Stack(children: [
              CircleAvatar(
                  radius: 56,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: _localPhotoFile != null
                      ? FileImage(_localPhotoFile!) as ImageProvider
                      : localPhotoPath != null
                          ? FileImage(File(localPhotoPath)) as ImageProvider
                          : user?.photoUrl != null
                              ? NetworkImage(user!.photoUrl!) as ImageProvider
                              : null,
                  child: _localPhotoFile == null &&
                          localPhotoPath == null &&
                          user?.photoUrl == null
                      ? const Icon(Icons.person,
                          size: 56, color: AppColors.primary)
                      : null),
              Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: _uploading
                              ? Colors.grey
                              : AppColors.primary,
                          shape: BoxShape.circle),
                      child: _uploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.edit,
                              size: 16, color: Colors.white))),
            ]),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap to change or remove photo',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          _ProfileRow('Name', user?.fullName ?? '—'),
          _ProfileRow('Email', user?.email ?? '—'),
          if (user?.ucid != null) _ProfileRow('UCID', user!.ucid!),
          _ProfileRow('Gender', user?.gender ?? '—'),
          _ProfileRow('Branch', user?.branch ?? '—'),
          if (user?.classYear != null) _ProfileRow('Class', user!.classYear!),
          if (user?.division != null) _ProfileRow('Division', user!.division!),
          if (user?.designation != null)
            _ProfileRow('Designation', user!.designation!),
          const SizedBox(height: 32),
          const _Footer(),
        ]),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label, value;
  const _ProfileRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200)),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: AppTextStyles.labelSmall.copyWith(fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  fontFamily: 'Lato')),
        ]),
      );
}

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _designationCtrl;
  String? _gender;
  String? _branch;
  String? _classYear;
  String? _division;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.fullName);
    _designationCtrl =
        TextEditingController(text: widget.user.designation ?? '');
    _gender = widget.user.gender;
    _branch = widget.user.branch;
    _classYear = widget.user.classYear;
    _division = widget.user.division;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _designationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = <String, dynamic>{
      'fullName': _nameCtrl.text.trim(),
      'gender': _gender,
      'branch': _branch,
      'classYear': widget.user.role == 'student' ? _classYear : null,
      'division': widget.user.role == 'student' ? _division : null,
      'designation':
          widget.user.role == 'faculty' ? _designationCtrl.text.trim() : null,
    };
    await FirebaseService.updateUserDoc(widget.user.uid, data);
    await context.read<AuthProvider>().loadUser(widget.user.uid);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline)),
                    validator: (v) => Validators.required(v, 'Full Name'),
                  ),
                  const SizedBox(height: 14),
                  _DropdownField<String>(
                    label: 'Gender',
                    prefixIcon: Icons.wc,
                    value: _gender,
                    items: _genderOptions,
                    onChanged: (v) => setState(() => _gender = v),
                    validator: (_) => _gender == null ? 'Select gender' : null,
                  ),
                  const SizedBox(height: 14),
                  _DropdownField<String>(
                    label: 'Branch',
                    prefixIcon: Icons.school_outlined,
                    value: _branch,
                    items: _branchOptions,
                    onChanged: (v) => setState(() {
                      _branch = v;
                      if (widget.user.role == 'student' &&
                          !classOptionsForBranch(_branch)
                              .contains(_classYear)) {
                        _classYear = null;
                      }
                    }),
                    validator: (_) => _branch == null ? 'Select branch' : null,
                  ),
                  if (widget.user.role == 'student') ...[
                    const SizedBox(height: 14),
                    _DropdownField<String>(
                      label: 'Class / Year',
                      prefixIcon: Icons.class_outlined,
                      value: _classYear,
                      items: classOptionsForBranch(_branch),
                      onChanged: (v) => setState(() => _classYear = v),
                      validator: (_) =>
                          _classYear == null ? 'Select class' : null,
                    ),
                    const SizedBox(height: 14),
                    _DropdownField<String>(
                      label: 'Division',
                      prefixIcon: Icons.group_outlined,
                      value: _division,
                      items: _divisionOptions,
                      onChanged: (v) => setState(() => _division = v),
                      validator: (_) =>
                          _division == null ? 'Select division' : null,
                    ),
                    const SizedBox(height: 4),
                    const Text('Select A if you are in the only division.',
                        style: AppTextStyles.labelSmall),
                  ],
                  if (widget.user.role == 'faculty') ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _designationCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Designation',
                          prefixIcon: Icon(Icons.work_outline)),
                      validator: (v) => Validators.required(v, 'Designation'),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _saving
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary))
                      : ElevatedButton(
                          onPressed: _save, child: const Text('Save Changes')),
                ]),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────
//  ADMIN SHELL
// ─────────────────────────────────────────────────────────
class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});
  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  int _tab = 0;
  final _pages = const [AdminOrdersScreen(), AdminMenuScreen()];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          actions: [
            IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await FirebaseService.logout();
                  context.read<AuthProvider>().logout();
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LandingScreen()),
                      (_) => false);
                }),
          ],
        ),
        body: _pages[_tab],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon:
                    Icon(Icons.receipt_long, color: AppColors.primary),
                label: 'Orders'),
            NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book, color: AppColors.primary),
                label: 'Menu'),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────
//  ADMIN ORDERS SCREEN
// ─────────────────────────────────────────────────────────
class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 3,
        child: Column(children: [
          const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Received'),
              Tab(text: 'Preparing'),
              Tab(text: 'Ready')
            ],
          ),
          Expanded(
              child: TabBarView(children: [
            _OrdersList('Received'),
            _OrdersList('Preparing'),
            _OrdersList('Ready to Pick Up'),
          ])),
        ]),
      );
}

class _OrdersList extends StatelessWidget {
  final String status;
  const _OrdersList(this.status);

  String? _nextStatus(String s) {
    if (s == 'Received') return 'Preparing';
    if (s == 'Preparing') return 'Ready to Pick Up';
    return null;
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData)
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        if (snap.data!.docs.isEmpty)
          return Center(
              child:
                  Text('No $status orders', style: AppTextStyles.bodyMedium));
        return ListView(
          padding: const EdgeInsets.all(16),
          children: snap.data!.docs.map((d) {
            final order =
                OrderModel.fromMap(d.data() as Map<String, dynamic>, d.id);
            final next = _nextStatus(order.status);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Order #${order.id.substring(0, 8)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Lato')),
                            Text(
                                DateFormat('hh:mm a')
                                    .format(order.createdAt.toDate()),
                                style: AppTextStyles.labelSmall),
                          ]),
                      Text(
                          '${order.userName} ${order.ucid != null ? "(${order.ucid})" : ""}',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textMuted)),
                      const Divider(),
                      ...order.items.map((i) => Text(
                          '• ${i['name']} × ${i['quantity']}',
                          style: AppTextStyles.bodyMedium)),
                      const SizedBox(height: 8),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('₹${order.total.toStringAsFixed(2)}',
                                style: AppTextStyles.priceLarge),
                            if (next != null)
                              ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8)),
                                  onPressed: () async {
                                    try {
                                      await FirebaseService.updateOrderStatus(
                                          order.id, next);
                                    } catch (_) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                        content: Text(
                                            'Failed to update order status. Please try again.'),
                                      ));
                                    }
                                  },
                                  child: Text('Mark $next',
                                      style: const TextStyle(fontSize: 12))),
                          ]),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () => downloadInvoicePdf(context, order),
                          icon: const Icon(Icons.download_outlined),
                          label: const Text('Download Invoice'),
                        ),
                      ),
                    ]),
              ),
            );
          }).toList(),
        );
      });
}

// ─────────────────────────────────────────────────────────
//  ADMIN MENU MANAGEMENT
// ─────────────────────────────────────────────────────────
class AdminMenuScreen extends StatelessWidget {
  const AdminMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
    final items = menuProvider.items;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MenuItemFormScreen()),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Item',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Lato',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: !menuProvider.initialized
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('No menu items yet', style: AppTextStyles.titleLarge),
                        const SizedBox(height: 8),
                        const Text(
                          'Seed the default menu into local SharedPreferences storage.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await context.read<MenuProvider>().seedDefaultsIfEmpty();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Starter menu created in local storage.'),
                            ));
                          },
                          icon: const Icon(Icons.restaurant_menu),
                          label: const Text('Seed Starter Menu'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: items.map((item) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _MenuImage(imagePath: item.imageUrl, width: 56, height: 56),
                        ),
                        title: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Lato'),
                        ),
                        subtitle: Text(
                          'Rs. ${item.price.toStringAsFixed(0)} · ${item.category}\nImage: ${item.imageUrl}',
                          style: AppTextStyles.labelSmall,
                        ),
                        isThreeLine: true,
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: AppColors.primary),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => MenuItemFormScreen(existing: item)),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: AppColors.error),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Delete Item'),
                                  content: Text('Delete "${item.name}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await context.read<MenuProvider>().deleteItem(item.id);
                              }
                            },
                          ),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}

//  MENU ITEM FORM (Add / Edit)
// ─────────────────────────────────────────────────────────
class MenuItemFormScreen extends StatefulWidget {
  final MenuItem? existing;
  const MenuItemFormScreen({super.key, this.existing});
  @override
  State<MenuItemFormScreen> createState() => _MenuItemFormScreenState();
}

class _MenuItemFormScreenState extends State<MenuItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  String? _category;
  bool _isVeg = true, _loading = false;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _nameCtrl.text = e.name;
      _priceCtrl.text = e.price.toString();
      _descCtrl.text = e.description;
      _imageCtrl.text = e.imageUrl;
      _category = e.category;
      _isVeg = e.isVeg;
    }
  }

  Future<void> _pickImage() async {
    final xfile = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xfile != null) setState(() => _imageFile = File(xfile.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      String imageUrl = _imageCtrl.text.trim();
      if (_imageFile != null) {
        imageUrl = await LocalMenuImageStore.saveImage(_imageFile!);
      }
      final item = MenuItem(
        id: widget.existing?.id ?? 'local_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        imageUrl: imageUrl,
        category: _category!,
        price: double.parse(_priceCtrl.text.trim()),
        isVeg: _isVeg,
      );
      if (widget.existing != null) {
        await context.read<MenuProvider>().updateItem(widget.existing!.id, item);
      } else {
        await context.read<MenuProvider>().addItem(item);
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(widget.existing != null ? 'Edit Item' : 'Add Item')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image preview/upload
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300)),
                      child: _imageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.file(_imageFile!, fit: BoxFit.cover))
                          : widget.existing?.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: _MenuImage(
                                    imagePath: widget.existing!.imageUrl,
                                    height: 180,
                                    width: double.infinity,
                                  ))
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                      Icon(Icons.add_photo_alternate_outlined,
                                          size: 48, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('Tap to upload image',
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontFamily: 'Lato')),
                                    ]),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                      controller: _imageCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Or paste image URL',
                          prefixIcon: Icon(Icons.link))),
                  const SizedBox(height: 16),
                  TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Item Name',
                          prefixIcon: Icon(Icons.fastfood_outlined)),
                      validator: (v) => Validators.required(v, 'Name')),
                  const SizedBox(height: 14),
                  TextFormField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Price (₹)',
                          prefixIcon: Icon(Icons.currency_rupee)),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Price required';
                        if (double.tryParse(v) == null)
                          return 'Enter valid price';
                        return null;
                      }),
                  const SizedBox(height: 14),
                  TextFormField(
                      controller: _descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                          labelText: 'Description',
                          prefixIcon: Icon(Icons.description_outlined)),
                      validator: (v) => Validators.required(v, 'Description')),
                  const SizedBox(height: 14),
                  _DropdownField<String>(
                      label: 'Category',
                      prefixIcon: Icons.category_outlined,
                      value: _category,
                      items: [
                        'Breakfast',
                        'Snacks',
                        'Meals',
                        'Drinks',
                        'Desserts'
                      ],
                      onChanged: (v) => setState(() => _category = v),
                      validator: (_) =>
                          _category == null ? 'Select category' : null),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    value: _isVeg,
                    onChanged: (v) => setState(() => _isVeg = v),
                    title: const Text('Vegetarian',
                        style: TextStyle(
                            fontFamily: 'Lato', fontWeight: FontWeight.w600)),
                    secondary: Icon(Icons.eco,
                        color: _isVeg ? AppColors.success : AppColors.error),
                    activeColor: AppColors.success,
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  const SizedBox(height: 24),
                  _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary))
                      : ElevatedButton(
                          onPressed: _save,
                          child: Text(widget.existing != null
                              ? 'Save Changes'
                              : 'Add to Menu')),
                ]),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────
//  SHARED WIDGETS
// ─────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.error.withOpacity(0.3))),
        child: Row(children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                      fontFamily: 'Lato'))),
        ]),
      );
}

class _Footer extends StatelessWidget {
  const _Footer();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('SPIT Pvt. Ltd.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontFamily: 'Lato',
                letterSpacing: 0.8)),
      );
}

class _PasswordStrengthBar extends StatelessWidget {
  final PasswordStrength strength;
  final String password;
  const _PasswordStrengthBar({required this.strength, required this.password});

  Color get _color {
    switch (strength) {
      case PasswordStrength.weak:
        return AppColors.error;
      case PasswordStrength.medium:
        return AppColors.accent;
      case PasswordStrength.strong:
        return AppColors.success;
    }
  }

  String get _label {
    switch (strength) {
      case PasswordStrength.weak:
        return 'Weak — add uppercase, numbers, symbols';
      case PasswordStrength.medium:
        return 'Medium — getting there!';
      case PasswordStrength.strong:
        return 'Strong ✓';
    }
  }

  double get _fraction {
    switch (strength) {
      case PasswordStrength.weak:
        return 0.33;
      case PasswordStrength.medium:
        return 0.66;
      case PasswordStrength.strong:
        return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
              value: _fraction,
              backgroundColor: Colors.grey.shade200,
              color: _color,
              minHeight: 6)),
      const SizedBox(height: 4),
      Text(_label,
          style: TextStyle(fontSize: 12, color: _color, fontFamily: 'Lato')),
    ]);
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final IconData prefixIcon;
  final T? value;
  final List<T> items;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;

  const _DropdownField({
    required this.label,
    required this.prefixIcon,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
        value: value,
        decoration:
            InputDecoration(labelText: label, prefixIcon: Icon(prefixIcon)),
        items: items
            .map((i) => DropdownMenuItem(value: i, child: Text(i.toString())))
            .toList(),
        onChanged: onChanged,
        validator: validator,
      );
}

// ─────────────────────────────────────────────────────────
//  STRING EXTENSION
// ─────────────────────────────────────────────────────────
extension StringX on String {
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
