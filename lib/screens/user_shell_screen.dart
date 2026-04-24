part of '../main.dart';

class UserShellScreen extends StatefulWidget {
  const UserShellScreen({super.key});
  @override
  State<UserShellScreen> createState() => _UserShellScreenState();
}

class _UserShellScreenState extends State<UserShellScreen> {
  int _tab = 0;
  String? _selectedMenuItemId;
  String? _selectedMenuCategory;
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

  void _showMenuItem(MenuItem item) {
    setState(() {
      _tab = 1;
      _selectedMenuItemId = item.id;
      _selectedMenuCategory = item.category;
    });
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
        children: [
          _UserHomeBody(onSpecialTap: _showMenuItem),
          _MenuBody(
            selectedItemId: _selectedMenuItemId,
            selectedCategory: _selectedMenuCategory,
          ),
          const _CartBody(),
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

class _UserHomeBody extends StatelessWidget {
  final ValueChanged<MenuItem> onSpecialTap;

  const _UserHomeBody({required this.onSpecialTap});

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
            child: _AnimatedSpecialsCarousel(
              items: specials,
              onItemTap: onSpecialTap,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
        const SliverToBoxAdapter(child: _Footer()),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }
}

class _MenuBody extends StatefulWidget {
  final String? selectedItemId;
  final String? selectedCategory;

  const _MenuBody({this.selectedItemId, this.selectedCategory});

  @override
  State<_MenuBody> createState() => _MenuBodyState();
}

class _MenuBodyState extends State<_MenuBody> {
  String _filter = 'All';

  @override
  void didUpdateWidget(covariant _MenuBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedItemId != oldWidget.selectedItemId &&
        widget.selectedCategory != null) {
      setState(() => _filter = widget.selectedCategory!);
    }
  }

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
          child: _MenuListView(
            filter: _filter,
            selectedItemId: widget.selectedItemId,
          ),
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
