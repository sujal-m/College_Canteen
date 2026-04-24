part of '../main.dart';

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

    setState(() {
      _loading = true;
      _error = null;
    });

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
        try {
          await cred.user?.delete();
        } catch (_) {}
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
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error));
    } catch (e) {
      // Firestore write or other error after auth account was created
      if (cred != null) {
        try {
          await cred.user?.delete();
        } catch (_) {}
      }
      if (!mounted) return;
      final msg = 'Registration failed: ${e.toString().split(']').last.trim()}';
      setState(() => _error = msg);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error));
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
                              onPressed: () => setState(
                                  () => _showConfirmPass = !_showConfirmPass))),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Confirm password is required';
                        if (v.length < 8) return 'Minimum 8 characters';
                        if (Validators.passwordStrength(v) ==
                            PasswordStrength.weak)
                          return 'Password is too weak';
                        if (v != _password.text)
                          return 'Passwords do not match';
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
