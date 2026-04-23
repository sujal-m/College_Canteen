// ============================================================
// SPIT Campus Canteen App — main.dart
// Place this file inside your Flutter project's /lib folder.
// ============================================================

import 'firebase_options.dart';
import 'dart:io';
import 'dart:typed_data';
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
  print('Background message: ${message.messageId}');
}

// ─────────────────────────────────────────────────────────
//  ENTRY POINT
// ─────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseMessaging.instance.requestPermission();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
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
  static const primary    = Color(0xFFD64000);   // deep saffron-orange
  static const secondary  = Color(0xFF1A1A2E);   // dark navy
  static const accent     = Color(0xFFFFB703);   // golden yellow
  static const bg         = Color(0xFFF5F0EB);   // warm off-white
  static const cardBg     = Color(0xFFFFFFFF);
  static const textDark   = Color(0xFF1A1A2E);
  static const textMuted  = Color(0xFF6B7280);
  static const success    = Color(0xFF22C55E);
  static const error      = Color(0xFFEF4444);
}

class AppTextStyles {
  static const displayLarge = TextStyle(
    fontFamily: 'Playfair Display', fontSize: 32,
    fontWeight: FontWeight.w700, color: AppColors.textDark, height: 1.15,
  );
  static const titleLarge = TextStyle(
    fontFamily: 'Playfair Display', fontSize: 22,
    fontWeight: FontWeight.w600, color: AppColors.textDark,
  );
  static const bodyMedium = TextStyle(
    fontFamily: 'Lato', fontSize: 14,
    color: AppColors.textDark, height: 1.5,
  );
  static const labelSmall = TextStyle(
    fontFamily: 'Lato', fontSize: 12,
    color: AppColors.textMuted, letterSpacing: 0.4,
  );
  static const priceLarge = TextStyle(
    fontFamily: 'Lato', fontSize: 18,
    fontWeight: FontWeight.w800, color: AppColors.primary,
  );
}

// ─────────────────────────────────────────────────────────
//  ADMIN CREDENTIALS (hardcoded, obfuscated at build time)
// ─────────────────────────────────────────────────────────
const _adminEmail    = 'sujalmeshram612@gmail.com';
const _adminPassword = '#PASSword12!';

// ─────────────────────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────────────────────
class UserModel {
  final String uid, fullName, email, gender, branch, role;
  final String? ucid, division, classYear, designation, photoUrl, fcmToken;

  UserModel({
    required this.uid, required this.fullName, required this.email,
    required this.gender, required this.branch, required this.role,
    this.ucid, this.division, this.classYear, this.designation,
    this.photoUrl, this.fcmToken,
  });

  factory UserModel.fromMap(Map<String, dynamic> m, String uid) => UserModel(
    uid: uid, fullName: m['fullName'], email: m['email'],
    gender: m['gender'], branch: m['branch'], role: m['role'],
    ucid: m['ucid'], division: m['division'], classYear: m['classYear'],
    designation: m['designation'], photoUrl: m['photoUrl'], fcmToken: m['fcmToken'],
  );

  Map<String, dynamic> toMap() => {
    'fullName': fullName, 'email': email, 'gender': gender,
    'branch': branch, 'role': role, 'ucid': ucid, 'division': division,
    'classYear': classYear, 'designation': designation,
    'photoUrl': photoUrl, 'fcmToken': fcmToken,
  };
}

class MenuItem {
  final String id, name, description, imageUrl, category;
  final double price;
  final bool isVeg;

  MenuItem({
    required this.id, required this.name, required this.description,
    required this.imageUrl, required this.category,
    required this.price, required this.isVeg,
  });

  factory MenuItem.fromMap(Map<String, dynamic> m, String id) => MenuItem(
    id: id, name: m['name'], description: m['description'],
    imageUrl: m['imageUrl'], category: m['category'],
    price: (m['price'] as num).toDouble(), isVeg: m['isVeg'] ?? true,
  );

  Map<String, dynamic> toMap() => {
    'name': name, 'description': description, 'imageUrl': imageUrl,
    'category': category, 'price': price, 'isVeg': isVeg,
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
    required this.id, required this.userId, required this.userName,
    required this.userEmail, required this.status, required this.items,
    required this.total, required this.createdAt, this.ucid,
  });

  factory OrderModel.fromMap(Map<String, dynamic> m, String id) => OrderModel(
    id: id, userId: m['userId'], userName: m['userName'],
    userEmail: m['userEmail'], status: m['status'],
    items: List<Map<String, dynamic>>.from(m['items']),
    total: (m['total'] as num).toDouble(),
    createdAt: m['createdAt'], ucid: m['ucid'],
  );
}

// ─────────────────────────────────────────────────────────
//  PROVIDERS
// ─────────────────────────────────────────────────────────
class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => _items;
  int get itemCount => _items.values.fold(0, (s, e) => s + e.quantity);
  double get total => _items.values.fold(0.0, (s, e) => s + e.item.price * e.quantity);

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

  void clearCart() { _items.clear(); notifyListeners(); }
}

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isAdmin = false;

  UserModel? get user => _user;
  bool get isAdmin => _isAdmin;
  bool get isLoggedIn => _user != null || _isAdmin;

  Future<void> loadUser(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      _user = UserModel.fromMap(doc.data()!, uid);
      _isAdmin = _user!.role == 'admin';
      notifyListeners();
    }
  }

  void setAdmin() { _isAdmin = true; _user = null; notifyListeners(); }
  void logout()   { _user = null; _isAdmin = false; notifyListeners(); }
}

// ─────────────────────────────────────────────────────────
//  FIREBASE SERVICE LAYER
// ─────────────────────────────────────────────────────────
class FirebaseService {
  static final _auth      = FirebaseAuth.instance;
  static final _db        = FirebaseFirestore.instance;
  static final _storage   = FirebaseStorage.instance;
  static final _messaging = FirebaseMessaging.instance;

  // ── Auth ──────────────────────────────────────────────
  static Future<UserCredential> registerWithEmail(String email, String password) =>
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
      _db.collection('users').doc(user.uid).set(user.toMap());

  static Future<void> updateUserDoc(String uid, Map<String, dynamic> data) =>
      _db.collection('users').doc(uid).update(data);

  // ── Firestore: Menu ───────────────────────────────────
  static Stream<QuerySnapshot> menuStream() =>
      _db.collection('menu').orderBy('category').snapshots();

  static Future<void> addMenuItem(MenuItem item) =>
      _db.collection('menu').add(item.toMap());

  static Future<void> updateMenuItem(String id, Map<String, dynamic> data) =>
      _db.collection('menu').doc(id).update(data);

  static Future<void> deleteMenuItem(String id) =>
      _db.collection('menu').doc(id).delete();

  // ── Firestore: Orders ─────────────────────────────────
  static Future<DocumentReference> placeOrder(Map<String, dynamic> data) =>
      _db.collection('orders').add(data);

  static Stream<QuerySnapshot> userOrdersStream(String uid) =>
      _db.collection('orders').where('userId', isEqualTo: uid)
         .orderBy('createdAt', descending: true).snapshots();

  static Stream<QuerySnapshot> allOrdersStream() =>
      _db.collection('orders').orderBy('createdAt', descending: true).snapshots();

  static Future<void> updateOrderStatus(String id, String status) =>
      _db.collection('orders').doc(id).update({'status': status});

  // ── Storage: Images ───────────────────────────────────
  static Future<String> uploadImage(File file, String path) async {
    final ref = _storage.ref().child(path);
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  // ── FCM token ─────────────────────────────────────────
  static Future<String?> getFcmToken() => _messaging.getToken();
}

// ─────────────────────────────────────────────────────────
//  PDF GENERATOR
// ─────────────────────────────────────────────────────────
class PdfService {
  static Future<File> generateInvoice(OrderModel order) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('SPIT Campus Canteen', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.Text('SPIT Pvt. Ltd.', style: const pw.TextStyle(fontSize: 12)),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text('Invoice / Order Receipt', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('Order ID: ${order.id.substring(0, 8)}'),
              pw.Text('Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt.toDate())}'),
            ]),
            pw.SizedBox(height: 8),
            pw.Text('Customer: ${order.userName}'),
            pw.Text('Email: ${order.userEmail}'),
            if (order.ucid != null) pw.Text('UCID: ${order.ucid}'),
            pw.SizedBox(height: 12),
            pw.Divider(),
            pw.Table.fromTextArray(
              headers: ['Item', 'Qty', 'Price', 'Subtotal'],
              data: order.items.map((i) => [
                i['name'], i['quantity'].toString(),
                '₹${i['price'].toStringAsFixed(2)}',
                '₹${(i['price'] * i['quantity']).toStringAsFixed(2)}',
              ]).toList(),
            ),
            pw.Divider(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('Total: ₹${order.total.toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 12),
            pw.Text('Payment Mode: Pay at Pickup', style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 20),
            pw.Center(child: pw.Text('Thank you for your order! 🙏', style: const pw.TextStyle(fontSize: 12))),
            pw.Center(child: pw.Text('— SPIT Pvt. Ltd. —', style: const pw.TextStyle(fontSize: 11))),
          ],
        ),
      ),
    );

    final dir  = await getTemporaryDirectory();
    final file = File('${dir.path}/invoice_${order.id.substring(0,8)}.pdf');
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
    if (!RegExp(r'^[\w\-.]+@[\w\-]+\.\w{2,}$').hasMatch(v)) return 'Enter a valid email';
    return null;
  }
  static String? ucid(String? v) {
    if (v == null || v.isEmpty) return 'UCID is required';
    if (!RegExp(r'^\d{10}$').hasMatch(v)) return 'UCID must be exactly 10 digits';
    return null;
  }
  static String? required(String? v, [String label = 'This field']) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    return null;
  }
  static PasswordStrength passwordStrength(String p) {
    int score = 0;
    if (p.length >= 8)                            score++;
    if (RegExp(r'[a-z]').hasMatch(p))             score++;
    if (RegExp(r'[A-Z]').hasMatch(p))             score++;
    if (RegExp(r'\d').hasMatch(p))                score++;
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
          titleTextStyle: TextStyle(fontFamily: 'Playfair Display', fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelStyle: AppTextStyles.labelSmall.copyWith(fontSize: 14, color: AppColors.textMuted),
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
  @override State<AuthGateScreen> createState() => _AuthGateScreenState();
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

  void _go(Widget screen) => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: AppColors.primary,
    body: Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.restaurant_menu, size: 72, color: Colors.white),
        SizedBox(height: 16),
        Text('SPIT Canteen', style: TextStyle(fontFamily: 'Playfair Display', fontSize: 32, color: Colors.white, fontWeight: FontWeight.w700)),
        SizedBox(height: 8),
        Text('SPIT Pvt. Ltd.', style: TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'Lato')),
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
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.secondary]),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                const Icon(Icons.restaurant_menu, size: 80, color: Colors.white),
                const SizedBox(height: 20),
                const Text('SPIT\nCanteen', style: TextStyle(fontFamily: 'Playfair Display',
                    fontSize: 52, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1)),
                const SizedBox(height: 12),
                Text('Order food. Skip the queue.', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 18, fontFamily: 'Lato')),
                const Spacer(),
                SizedBox(width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: const Text('Login'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white), padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: const Text('Register', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 24),
                const Center(child: Text('SPIT Pvt. Ltd.', style: TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'Lato'))),
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
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false, _showPass = false;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final cred = await FirebaseService.loginWithEmail(_emailCtrl.text.trim(), _passwordCtrl.text);
      final user = cred.user!;
      await user.reload();
      if (!user.emailVerified) {
        setState(() { _error = 'Please verify your email before logging in.'; _loading = false; });
        return;
      }
      if (user.email == _adminEmail) {
        context.read<AuthProvider>().setAdmin();
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AdminShellScreen()), (_) => false);
      } else {
        await context.read<AuthProvider>().loadUser(user.uid);
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const UserShellScreen()), (_) => false);
      }
    } on FirebaseAuthException catch (e) {
      setState(() { _error = _authError(e.code); _loading = false; });
    }
  }

  String _authError(String code) {
    switch (code) {
      case 'user-not-found': return 'No account found with this email.';
      case 'wrong-password': return 'Incorrect password.';
      case 'too-many-requests': return 'Too many attempts. Try again later.';
      default: return 'Login failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Login')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 16),
          Text('Welcome back!', style: AppTextStyles.displayLarge),
          const SizedBox(height: 4),
          Text('Login to continue ordering', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 32),
          if (_error != null) _ErrorBanner(_error!),
          TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
            validator: Validators.email),
          const SizedBox(height: 16),
          TextFormField(controller: _passwordCtrl, obscureText: !_showPass,
            decoration: InputDecoration(
              labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _showPass = !_showPass))),
            validator: (v) => Validators.required(v, 'Password')),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerRight,
            child: TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
              child: const Text('Forgot Password?', style: TextStyle(color: AppColors.primary)))),
          const SizedBox(height: 16),
          _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : ElevatedButton(onPressed: _login, child: const Text('Login')),
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
  @override State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _sent = false, _loading = false;
  String? _error;

  Future<void> _send() async {
    if (_emailCtrl.text.isEmpty) { setState(() => _error = 'Enter your email'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      await FirebaseService.sendPasswordReset(_emailCtrl.text.trim());
      setState(() { _sent = true; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Failed to send reset email.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Forgot Password')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: _sent
          ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.mark_email_read, size: 80, color: AppColors.success),
              const SizedBox(height: 16),
              const Text('Reset link sent!', style: AppTextStyles.titleLarge),
              const SizedBox(height: 8),
              Text('Check your inbox at ${_emailCtrl.text}', textAlign: TextAlign.center, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Back to Login')),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SizedBox(height: 24),
              Text('Reset Password', style: AppTextStyles.displayLarge),
              const SizedBox(height: 8),
              Text('Enter your registered email address', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 32),
              if (_error != null) _ErrorBanner(_error!),
              TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
              const SizedBox(height: 24),
              _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : ElevatedButton(onPressed: _send, child: const Text('Send Reset Link')),
            ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────
//  REGISTER SCREEN
// ─────────────────────────────────────────────────────────
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String _userType = 'student';
  String? _gender, _branch, _classYear, _division;
  final _name        = TextEditingController();
  final _email       = TextEditingController();
  final _ucid        = TextEditingController();
  final _password    = TextEditingController();
  final _designation = TextEditingController();
  bool _showPass = false, _loading = false;
  String? _error;

  static const _genders    = ['Male', 'Female', 'Prefer not to say'];
  static const _branches   = ['CSE', 'EXTC', 'COMS'];
  static const _divisions  = ['A', 'B', 'C', 'D'];

  List<String> get _classOptions {
    const base = ['1st Year', '2nd Year', '3rd Year', '4th Year', 'FYMTech', 'SYMTech'];
    if (_branch == 'CSE') return [...base, 'FYMCA', 'SYMCA'];
    return base;
  }

  PasswordStrength get _strength => Validators.passwordStrength(_password.text);

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final cred = await FirebaseService.registerWithEmail(_email.text.trim(), _password.text);
      await FirebaseService.sendVerificationEmail();
      final token = await FirebaseService.getFcmToken();
      final user = UserModel(
        uid: cred.user!.uid, fullName: _name.text.trim(),
        email: _email.text.trim(), gender: _gender!, branch: _branch!,
        role: _userType,
        ucid: _userType == 'student' ? _ucid.text.trim() : null,
        division: _userType == 'student' ? _division : null,
        classYear: _userType == 'student' ? _classYear : null,
        designation: _userType == 'faculty' ? _designation.text.trim() : null,
        fcmToken: token,
      );
      await FirebaseService.createUserDoc(user);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const VerifyEmailScreen()));
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.code == 'email-already-in-use' ? 'This email is already registered.' : 'Registration failed. Try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create Account')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // User Type Toggle
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300)),
            child: Row(children: ['student', 'faculty'].map((t) => Expanded(
              child: GestureDetector(
                onTap: () => setState(() { _userType = t; _classYear = null; }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _userType == t ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(t.capitalize, textAlign: TextAlign.center,
                    style: TextStyle(color: _userType == t ? Colors.white : AppColors.textMuted,
                      fontWeight: FontWeight.w700, fontFamily: 'Lato')),
                ),
              ),
            )).toList()),
          ),
          const SizedBox(height: 20),
          if (_error != null) _ErrorBanner(_error!),

          // Full Name
          TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => Validators.required(v, 'Full Name')),
          const SizedBox(height: 14),

          // UCID (Student only)
          if (_userType == 'student') ...[
            TextFormField(controller: _ucid, keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                decoration: const InputDecoration(labelText: 'UCID (10 digits)', prefixIcon: Icon(Icons.badge_outlined)),
                validator: Validators.ucid),
            const SizedBox(height: 14),
          ],

          // Email
          TextFormField(controller: _email, keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
              validator: Validators.email),
          const SizedBox(height: 14),

          // Gender
          _DropdownField<String>(label: 'Gender', prefixIcon: Icons.wc,
            value: _gender, items: _genders,
            onChanged: (v) => setState(() => _gender = v),
            validator: (_) => _gender == null ? 'Select gender' : null),
          const SizedBox(height: 14),

          // Branch
          _DropdownField<String>(label: 'Branch', prefixIcon: Icons.school_outlined,
            value: _branch, items: _branches,
            onChanged: (v) => setState(() { _branch = v; _classYear = null; }),
            validator: (_) => _branch == null ? 'Select branch' : null),
          const SizedBox(height: 14),

          // Class (Student only)
          if (_userType == 'student') ...[
            _DropdownField<String>(label: 'Class / Year', prefixIcon: Icons.class_outlined,
              value: _classYear, items: _classOptions,
              onChanged: (v) => setState(() => _classYear = v),
              validator: (_) => _classYear == null ? 'Select class' : null),
            const SizedBox(height: 14),

            _DropdownField<String>(label: 'Division', prefixIcon: Icons.group_outlined,
              value: _division, items: _divisions,
              onChanged: (v) => setState(() => _division = v),
              validator: (_) => _division == null ? 'Select division' : null),
            const Padding(
              padding: EdgeInsets.only(left: 4, top: 4),
              child: Text('ℹ️ Select A if you are in the only division', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ),
            const SizedBox(height: 14),
          ],

          // Designation (Faculty only)
          if (_userType == 'faculty') ...[
            TextFormField(controller: _designation,
                decoration: const InputDecoration(labelText: 'Designation', prefixIcon: Icon(Icons.work_outline)),
                validator: (v) => Validators.required(v, 'Designation')),
            const SizedBox(height: 14),
          ],

          // Password
          TextFormField(
            controller: _password, obscureText: !_showPass,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _showPass = !_showPass))),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 8) return 'Minimum 8 characters';
              if (Validators.passwordStrength(v) == PasswordStrength.weak) return 'Password is too weak';
              return null;
            }),
          const SizedBox(height: 8),
          _PasswordStrengthBar(strength: _strength, password: _password.text),
          const SizedBox(height: 24),

          _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : ElevatedButton(onPressed: _register, child: const Text('Create Account')),
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
  @override State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _checking = false;

  Future<void> _checkVerified() async {
    setState(() => _checking = true);
    await FirebaseService.currentUser?.reload();
    if (FirebaseService.currentUser?.emailVerified == true) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const UserShellScreen()), (_) => false);
    } else {
      setState(() => _checking = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email not yet verified. Please check your inbox.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.mark_email_unread_outlined, size: 90, color: AppColors.primary),
        const SizedBox(height: 24),
        Text('Verify your Email', style: AppTextStyles.displayLarge),
        const SizedBox(height: 12),
        Text('A verification email was sent to ${FirebaseService.currentUser?.email ?? ''}.\nPlease verify to continue.',
            textAlign: TextAlign.center, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 32),
        _checking
            ? const CircularProgressIndicator(color: AppColors.primary)
            : ElevatedButton(onPressed: _checkVerified, child: const Text("I've Verified My Email")),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () async { await FirebaseService.sendVerificationEmail();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification email resent!'))); },
          child: const Text('Resend Email', style: TextStyle(color: AppColors.primary)),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () { FirebaseService.logout(); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LandingScreen()), (_) => false); },
          child: const Text('Back to Login', style: TextStyle(color: AppColors.textMuted)),
        ),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────
//  USER SHELL (Bottom Nav + Drawer)
// ─────────────────────────────────────────────────────────
class UserShellScreen extends StatefulWidget {
  const UserShellScreen({super.key});
  @override State<UserShellScreen> createState() => _UserShellScreenState();
}

class _UserShellScreenState extends State<UserShellScreen> {
  int _tab = 0;
  final _pages = const [UserHomeScreen(), MenuScreen(), CartScreen()];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final cart = context.watch<CartProvider>();
    return Scaffold(
      drawer: _AppDrawer(user: user),
      body: _pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withOpacity(0.15),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: AppColors.primary), label: 'Home'),
          const NavigationDestination(icon: Icon(Icons.restaurant_menu_outlined), selectedIcon: Icon(Icons.restaurant_menu, color: AppColors.primary), label: 'Menu'),
          NavigationDestination(
            icon: Badge(isLabelVisible: cart.itemCount > 0, label: Text('${cart.itemCount}'), child: const Icon(Icons.shopping_cart_outlined)),
            selectedIcon: Badge(isLabelVisible: cart.itemCount > 0, label: Text('${cart.itemCount}'), child: const Icon(Icons.shopping_cart, color: AppColors.primary)),
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
  Widget build(BuildContext context) => Drawer(
    child: SafeArea(
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(20),
          color: AppColors.primary,
          child: Row(children: [
            CircleAvatar(radius: 28, backgroundColor: Colors.white,
              backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
              child: user?.photoUrl == null ? const Icon(Icons.person, color: AppColors.primary, size: 32) : null),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user?.fullName ?? 'Guest', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16, fontFamily: 'Playfair Display')),
              Text(user?.email ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Lato'), overflow: TextOverflow.ellipsis),
            ])),
          ]),
        ),
        ListTile(leading: const Icon(Icons.person_outline, color: AppColors.primary), title: const Text('Profile'),
          onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())); }),
        ListTile(leading: const Icon(Icons.history, color: AppColors.primary), title: const Text('Order History'),
          onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen())); }),
        const Spacer(),
        const Divider(),
        ListTile(leading: const Icon(Icons.logout, color: AppColors.error), title: const Text('Logout', style: TextStyle(color: AppColors.error)),
          onTap: () async {
            await FirebaseService.logout();
            context.read<AuthProvider>().logout();
            context.read<CartProvider>().clearCart();
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LandingScreen()), (_) => false);
          }),
        const _Footer(),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────
//  USER HOME SCREEN
// ─────────────────────────────────────────────────────────
class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(title: const Text('SPIT Canteen'), leading: Builder(
        builder: (ctx) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(ctx).openDrawer()))),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, Color(0xFFFF6B35)]),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Hello, ${user?.fullName.split(' ').first ?? 'there'} 👋',
                style: const TextStyle(fontFamily: 'Playfair Display', fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 4),
              const Text("What would you like to eat today?", style: TextStyle(color: Colors.white70, fontFamily: 'Lato', fontSize: 14)),
            ]),
          )),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Today\'s Specials', style: AppTextStyles.titleLarge),
              const SizedBox(height: 16),
            ])),
          ),
          // Featured items stream
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseService.menuStream(),
            builder: (context, snap) {
              if (!snap.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
              final items = snap.data!.docs.take(4).map((d) => MenuItem.fromMap(d.data() as Map<String,dynamic>, d.id)).toList();
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.78),
                  delegate: SliverChildBuilderDelegate((ctx, i) => _MenuItemCard(item: items[i]), childCount: items.length),
                ),
              );
            }),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
          const SliverToBoxAdapter(child: _Footer()),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  MENU SCREEN
// ─────────────────────────────────────────────────────────
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Menu'), leading: Builder(
      builder: (ctx) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(ctx).openDrawer()))),
    body: Column(children: [
      // Category filter chips
      Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: ['All','Breakfast','Snacks','Meals','Drinks','Desserts']
            .map((c) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(c), selected: _filter == c,
                onSelected: (_) => setState(() => _filter = c),
                selectedColor: AppColors.primary.withOpacity(0.15),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(color: _filter == c ? AppColors.primary : AppColors.textMuted, fontWeight: FontWeight.w600),
              ),
            )).toList()),
        ),
      ),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseService.menuStream(),
          builder: (ctx, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            var items = snap.data!.docs.map((d) => MenuItem.fromMap(d.data() as Map<String,dynamic>, d.id)).toList();
            if (_filter != 'All') items = items.where((i) => i.category == _filter).toList();
            if (items.isEmpty) return const Center(child: Text('No items in this category'));
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.78),
              itemCount: items.length,
              itemBuilder: (_, i) => _MenuItemCard(item: items[i]),
            );
          }),
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
    final qty  = cart.items[item.id]?.quantity ?? 0;
    return Container(
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0,2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: CachedNetworkImage(imageUrl: item.imageUrl, height: 110, width: double.infinity, fit: BoxFit.cover,
            placeholder: (_, __) => Container(height: 110, color: Colors.grey.shade200, child: const Icon(Icons.restaurant, color: Colors.grey)),
            errorWidget: (_, __, ___) => Container(height: 110, color: Colors.grey.shade100, child: const Icon(Icons.broken_image, color: Colors.grey))),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(
                  shape: BoxShape.circle, color: item.isVeg ? AppColors.success : AppColors.error,
                  border: Border.all(color: item.isVeg ? AppColors.success : AppColors.error))),
              const SizedBox(width: 4),
              Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Lato'), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 2),
            Text(item.description, style: AppTextStyles.labelSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('₹${item.price.toStringAsFixed(0)}', style: AppTextStyles.priceLarge.copyWith(fontSize: 15)),
              qty == 0
                  ? GestureDetector(
                      onTap: () => context.read<CartProvider>().addItem(item),
                      child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                        child: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12, fontFamily: 'Lato'))))
                  : Row(children: [
                      _QtyBtn(Icons.remove, () => context.read<CartProvider>().removeItem(item.id)),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.w700))),
                      _QtyBtn(Icons.add, qty < 6 ? () => context.read<CartProvider>().addItem(item) : null),
                    ]),
            ]),
          ]),
        ),
      ]),
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
    child: Container(padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: onTap != null ? AppColors.primary : Colors.grey.shade300, shape: BoxShape.circle),
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
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Total: ₹${cart.total.toStringAsFixed(2)}', style: AppTextStyles.priceLarge),
          const SizedBox(height: 8),
          const Text('Payment: Pay at Pickup', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 4),
          const Text('Place this order?', style: AppTextStyles.bodyMedium),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
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
      'items': cart.items.values.map((ci) => {
        'id': ci.item.id, 'name': ci.item.name,
        'price': ci.item.price, 'quantity': ci.quantity,
      }).toList(),
      'total': cart.total,
      'paymentMode': 'Pay at Pickup',
      'createdAt': FieldValue.serverTimestamp(),
    };

    final docRef = await FirebaseService.placeOrder(orderData);
    cart.clearCart();

    // Generate PDF invoice
    final doc = await docRef.get();
    final order = OrderModel.fromMap(doc.data() as Map<String, dynamic>, docRef.id);
    final pdfFile = await PdfService.generateInvoice(order);
    await OpenFile.open(pdfFile.path);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🎉 Order placed! Invoice downloaded.'), backgroundColor: AppColors.success));
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart'), leading: Builder(
        builder: (ctx) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(ctx).openDrawer()))),
      body: cart.items.isEmpty
          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text('Your cart is empty', style: TextStyle(fontSize: 18, color: AppColors.textMuted, fontFamily: 'Lato')),
            ]))
          : Column(children: [
              Expanded(child: ListView(
                padding: const EdgeInsets.all(16),
                children: cart.items.values.map((ci) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: ClipRRect(borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(imageUrl: ci.item.imageUrl, width: 56, height: 56, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Icon(Icons.restaurant))),
                    title: Text(ci.item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Lato')),
                    subtitle: Text('₹${ci.item.price.toStringAsFixed(0)} × ${ci.quantity}', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      _QtyBtn(Icons.remove, () => context.read<CartProvider>().removeItem(ci.item.id)),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('${ci.quantity}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
                      _QtyBtn(Icons.add, ci.quantity < 6 ? () => context.read<CartProvider>().addItem(ci.item) : null),
                    ]),
                  ),
                )).toList(),
              )),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0,-4))]),
                child: SafeArea(
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Total', style: AppTextStyles.titleLarge),
                      Text('₹${cart.total.toStringAsFixed(2)}', style: AppTextStyles.priceLarge),
                    ]),
                    const SizedBox(height: 4),
                    const Row(children: [Icon(Icons.info_outline, size: 14, color: AppColors.textMuted), SizedBox(width: 4), Text('Payment: Pay at Pickup', style: AppTextStyles.labelSmall)]),
                    const SizedBox(height: 16),
                    SizedBox(width: double.infinity,
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
          if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          if (snap.data!.docs.isEmpty) return const Center(child: Text('No orders yet', style: AppTextStyles.bodyMedium));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: snap.data!.docs.map((d) {
              final order = OrderModel.fromMap(d.data() as Map<String,dynamic>, d.id);
              return _OrderCard(order: order);
            }).toList(),
          );
        }),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  Color _statusColor(String s) {
    switch (s) {
      case 'Received':       return AppColors.accent;
      case 'Preparing':      return AppColors.primary;
      case 'Ready to Pick Up': return AppColors.success;
      default: return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Order #${order.id.substring(0,8)}', style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Lato')),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: _statusColor(order.status).withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Text(order.status, style: TextStyle(color: _statusColor(order.status), fontWeight: FontWeight.w700, fontSize: 12, fontFamily: 'Lato'))),
        ]),
        const SizedBox(height: 8),
        ...order.items.map((i) => Text('• ${i['name']} × ${i['quantity']}', style: AppTextStyles.bodyMedium)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('₹${order.total.toStringAsFixed(2)}', style: AppTextStyles.priceLarge),
          Text(DateFormat('dd MMM, hh:mm a').format(order.createdAt.toDate()), style: AppTextStyles.labelSmall),
        ]),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────
//  PROFILE SCREEN
// ─────────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _uploading = false;

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final xfile  = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (xfile == null) return;
    setState(() => _uploading = true);
    final uid  = context.read<AuthProvider>().user!.uid;
    final file = File(xfile.path);
    final url  = await FirebaseService.uploadImage(file, 'profiles/$uid.jpg');
    await FirebaseService.updateUserDoc(uid, {'photoUrl': url});
    await context.read<AuthProvider>().loadUser(uid);
    setState(() => _uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          GestureDetector(
            onTap: _pickAndUploadPhoto,
            child: Stack(children: [
              CircleAvatar(radius: 56, backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                child: user?.photoUrl == null ? const Icon(Icons.person, size: 56, color: AppColors.primary) : null),
              Positioned(bottom: 0, right: 0,
                child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: _uploading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.camera_alt, size: 16, color: Colors.white))),
            ]),
          ),
          const SizedBox(height: 24),
          _ProfileRow('Name', user?.fullName ?? '—'),
          _ProfileRow('Email', user?.email ?? '—'),
          if (user?.ucid != null) _ProfileRow('UCID', user!.ucid!),
          _ProfileRow('Gender', user?.gender ?? '—'),
          _ProfileRow('Branch', user?.branch ?? '—'),
          if (user?.classYear != null) _ProfileRow('Class', user!.classYear!),
          if (user?.division != null)  _ProfileRow('Division', user!.division!),
          if (user?.designation != null) _ProfileRow('Designation', user!.designation!),
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
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200)),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: AppTextStyles.labelSmall.copyWith(fontSize: 13)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Lato')),
    ]),
  );
}

// ─────────────────────────────────────────────────────────
//  ADMIN SHELL
// ─────────────────────────────────────────────────────────
class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});
  @override State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  int _tab = 0;
  final _pages = const [AdminOrdersScreen(), AdminMenuScreen()];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Admin Panel'),
      actions: [
        IconButton(icon: const Icon(Icons.logout), onPressed: () async {
          await FirebaseService.logout();
          context.read<AuthProvider>().logout();
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LandingScreen()), (_) => false);
        }),
      ],
    ),
    body: _pages[_tab],
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: (i) => setState(() => _tab = i),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long, color: AppColors.primary), label: 'Orders'),
        NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book, color: AppColors.primary), label: 'Menu'),
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
        tabs: [Tab(text: 'Received'), Tab(text: 'Preparing'), Tab(text: 'Ready')],
      ),
      Expanded(child: TabBarView(children: [
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
    if (s == 'Received')       return 'Preparing';
    if (s == 'Preparing')      return 'Ready to Pick Up';
    return null;
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('orders').where('status', isEqualTo: status).orderBy('createdAt', descending: false).snapshots(),
    builder: (ctx, snap) {
      if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
      if (snap.data!.docs.isEmpty) return Center(child: Text('No $status orders', style: AppTextStyles.bodyMedium));
      return ListView(
        padding: const EdgeInsets.all(16),
        children: snap.data!.docs.map((d) {
          final order = OrderModel.fromMap(d.data() as Map<String,dynamic>, d.id);
          final next  = _nextStatus(order.status);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Order #${order.id.substring(0,8)}', style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Lato')),
                  Text(DateFormat('hh:mm a').format(order.createdAt.toDate()), style: AppTextStyles.labelSmall),
                ]),
                Text('${order.userName} ${order.ucid != null ? "(${order.ucid})" : ""}', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
                const Divider(),
                ...order.items.map((i) => Text('• ${i['name']} × ${i['quantity']}', style: AppTextStyles.bodyMedium)),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('₹${order.total.toStringAsFixed(2)}', style: AppTextStyles.priceLarge),
                  if (next != null) ElevatedButton(
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                    onPressed: () => FirebaseService.updateOrderStatus(order.id, next),
                    child: Text('Mark $next', style: const TextStyle(fontSize: 12))),
                ]),
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
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton.extended(
      backgroundColor: AppColors.primary,
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MenuItemFormScreen())),
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text('Add Item', style: TextStyle(color: Colors.white, fontFamily: 'Lato', fontWeight: FontWeight.w700)),
    ),
    body: StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.menuStream(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        if (snap.data!.docs.isEmpty) return const Center(child: Text('No menu items yet'));
        return ListView(
          padding: const EdgeInsets.all(16),
          children: snap.data!.docs.map((d) {
            final item = MenuItem.fromMap(d.data() as Map<String,dynamic>, d.id);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: ClipRRect(borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(imageUrl: item.imageUrl, width: 56, height: 56, fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Icon(Icons.restaurant))),
                title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Lato')),
                subtitle: Text('₹${item.price.toStringAsFixed(0)} · ${item.category}', style: AppTextStyles.labelSmall),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.edit, color: AppColors.primary),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MenuItemFormScreen(existing: item)))),
                  IconButton(icon: const Icon(Icons.delete, color: AppColors.error),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete Item'),
                          content: Text('Delete "${item.name}"?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                              onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                          ]));
                      if (confirmed == true) await FirebaseService.deleteMenuItem(item.id);
                    }),
                ]),
              ),
            );
          }).toList(),
        );
      }),
  );
}

// ─────────────────────────────────────────────────────────
//  MENU ITEM FORM (Add / Edit)
// ─────────────────────────────────────────────────────────
class MenuItemFormScreen extends StatefulWidget {
  final MenuItem? existing;
  const MenuItemFormScreen({super.key, this.existing});
  @override State<MenuItemFormScreen> createState() => _MenuItemFormScreenState();
}

class _MenuItemFormScreenState extends State<MenuItemFormScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _priceCtrl  = TextEditingController();
  final _descCtrl   = TextEditingController();
  final _imageCtrl  = TextEditingController();
  String? _category;
  bool _isVeg = true, _loading = false;
  File?  _imageFile;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _nameCtrl.text  = e.name;
      _priceCtrl.text = e.price.toString();
      _descCtrl.text  = e.description;
      _imageCtrl.text = e.imageUrl;
      _category       = e.category;
      _isVeg          = e.isVeg;
    }
  }

  Future<void> _pickImage() async {
    final xfile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xfile != null) setState(() => _imageFile = File(xfile.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      String imageUrl = _imageCtrl.text.trim();
      if (_imageFile != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        imageUrl = await FirebaseService.uploadImage(_imageFile!, 'menu/$fileName');
      }
      final data = {
        'name': _nameCtrl.text.trim(),
        'price': double.parse(_priceCtrl.text.trim()),
        'description': _descCtrl.text.trim(),
        'imageUrl': imageUrl,
        'category': _category!,
        'isVeg': _isVeg,
      };
      if (widget.existing != null) {
        await FirebaseService.updateMenuItem(widget.existing!.id, data);
      } else {
        await FirebaseService.addMenuItem(MenuItem(id: '', name: data['name'] as String,
          description: data['description'] as String, imageUrl: imageUrl,
          category: _category!, price: data['price'] as double, isVeg: _isVeg));
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.existing != null ? 'Edit Item' : 'Add Item')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Image preview/upload
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 180, decoration: BoxDecoration(
                color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300)),
              child: _imageFile != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(_imageFile!, fit: BoxFit.cover))
                  : widget.existing?.imageUrl != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(15),
                          child: CachedNetworkImage(imageUrl: widget.existing!.imageUrl, fit: BoxFit.cover))
                      : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Tap to upload image', style: TextStyle(color: Colors.grey, fontFamily: 'Lato')),
                        ]),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(controller: _imageCtrl,
            decoration: const InputDecoration(labelText: 'Or paste image URL', prefixIcon: Icon(Icons.link))),
          const SizedBox(height: 16),
          TextFormField(controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Item Name', prefixIcon: Icon(Icons.fastfood_outlined)),
            validator: (v) => Validators.required(v, 'Name')),
          const SizedBox(height: 14),
          TextFormField(controller: _priceCtrl, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Price (₹)', prefixIcon: Icon(Icons.currency_rupee)),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Price required';
              if (double.tryParse(v) == null) return 'Enter valid price';
              return null;
            }),
          const SizedBox(height: 14),
          TextFormField(controller: _descCtrl, maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description_outlined)),
            validator: (v) => Validators.required(v, 'Description')),
          const SizedBox(height: 14),
          _DropdownField<String>(label: 'Category', prefixIcon: Icons.category_outlined,
            value: _category, items: ['Breakfast','Snacks','Meals','Drinks','Desserts'],
            onChanged: (v) => setState(() => _category = v),
            validator: (_) => _category == null ? 'Select category' : null),
          const SizedBox(height: 14),
          SwitchListTile(
            value: _isVeg, onChanged: (v) => setState(() => _isVeg = v),
            title: const Text('Vegetarian', style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.w600)),
            secondary: Icon(Icons.eco, color: _isVeg ? AppColors.success : AppColors.error),
            activeColor: AppColors.success,
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          const SizedBox(height: 24),
          _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : ElevatedButton(onPressed: _save, child: Text(widget.existing != null ? 'Save Changes' : 'Add to Menu')),
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
    decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08), borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withOpacity(0.3))),
    child: Row(children: [
      const Icon(Icons.error_outline, color: AppColors.error, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(message, style: const TextStyle(color: AppColors.error, fontSize: 13, fontFamily: 'Lato'))),
    ]),
  );
}

class _Footer extends StatelessWidget {
  const _Footer();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 12),
    child: Text('SPIT Pvt. Ltd.', textAlign: TextAlign.center,
      style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontFamily: 'Lato', letterSpacing: 0.8)),
  );
}

class _PasswordStrengthBar extends StatelessWidget {
  final PasswordStrength strength;
  final String password;
  const _PasswordStrengthBar({required this.strength, required this.password});

  Color get _color {
    switch (strength) {
      case PasswordStrength.weak:   return AppColors.error;
      case PasswordStrength.medium: return AppColors.accent;
      case PasswordStrength.strong: return AppColors.success;
    }
  }
  String get _label {
    switch (strength) {
      case PasswordStrength.weak:   return 'Weak — add uppercase, numbers, symbols';
      case PasswordStrength.medium: return 'Medium — getting there!';
      case PasswordStrength.strong: return 'Strong ✓';
    }
  }
  double get _fraction {
    switch (strength) {
      case PasswordStrength.weak:   return 0.33;
      case PasswordStrength.medium: return 0.66;
      case PasswordStrength.strong: return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(value: _fraction, backgroundColor: Colors.grey.shade200, color: _color, minHeight: 6)),
      const SizedBox(height: 4),
      Text(_label, style: TextStyle(fontSize: 12, color: _color, fontFamily: 'Lato')),
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
    required this.label, required this.prefixIcon, required this.value,
    required this.items, required this.onChanged, this.validator,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    value: value,
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(prefixIcon)),
    items: items.map((i) => DropdownMenuItem(value: i, child: Text(i.toString()))).toList(),
    onChanged: onChanged,
    validator: validator,
  );
}

// ─────────────────────────────────────────────────────────
//  STRING EXTENSION
// ─────────────────────────────────────────────────────────
extension StringX on String {
  String get capitalize => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
