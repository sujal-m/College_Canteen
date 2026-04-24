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

part 'screens/auth_screens.dart';
part 'screens/user_shell_screen.dart';
part 'screens/menu_screen.dart';
part 'screens/cart_screen.dart';
part 'screens/order_history_screen.dart';
part 'screens/notification_screen.dart';
part 'screens/profile_screens.dart';
part 'screens/admin_screens.dart';
part 'widgets/shared_widgets.dart';

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
    final raw = jsonEncode(
        items.map((item) => {'id': item.id, ...item.toMap()}).toList());
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
    final target =
        File('${dir.path}/menu_${DateTime.now().millisecondsSinceEpoch}.jpg');
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
    final cleaned =
        data.map((k, v) => MapEntry(k, v == null ? FieldValue.delete() : v));
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
                  pw.Text('Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(
                    order.createdAt.toDate(),
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
              data: order.items
                  .map((i) => [
                        i['name'],
                        i['quantity'].toString(),
                        NumberFormat.currency(locale: 'en_IN', symbol: '₹')
                            .format((i['price'] as num).toDouble()),
                        NumberFormat.currency(locale: 'en_IN', symbol: '₹')
                            .format((i['price'] as num).toDouble() *
                                (i['quantity'] as num)),
                      ])
                  .toList(),
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

// ─────────────────────────────────────────────────────────
//  LANDING SCREEN
// ─────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────
//  LOGIN SCREEN
// ─────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────
//  FORGOT PASSWORD SCREEN
// ─────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────
//  REGISTER SCREEN
// ─────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────
//  EMAIL VERIFICATION SCREEN
// ─────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────
//  USER SHELL (Bottom Nav + Drawer)
//  Single Scaffold hosts the drawer. Child pages are NOT
//  Scaffolds — they return plain body widgets so that
//  Scaffold.of(context).openDrawer() always finds THIS one.
// ─────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────
//  USER HOME BODY  (no Scaffold — lives inside UserShellScreen)
// ─────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────
//  MENU SCREEN
// ─────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────
//  CART SCREEN
// ─────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────
//  ORDER HISTORY SCREEN
// ─────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────
//  PROFILE SCREEN
// ─────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────
//  ADMIN SHELL
// ─────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────
//  ADMIN ORDERS SCREEN
// ─────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────
//  ADMIN MENU MANAGEMENT
// ─────────────────────────────────────────────────────────

//  MENU ITEM FORM (Add / Edit)
// ─────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────
//  SHARED WIDGETS
// ─────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────
//  STRING EXTENSION
// ─────────────────────────────────────────────────────────
