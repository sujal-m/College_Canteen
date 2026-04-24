part of '../main.dart';

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
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('No menu items yet',
                            style: AppTextStyles.titleLarge),
                        const SizedBox(height: 8),
                        const Text(
                          'Seed the default menu into local SharedPreferences storage.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await context
                                .read<MenuProvider>()
                                .seedDefaultsIfEmpty();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text(
                                  'Starter menu created in local storage.'),
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _MenuImage(
                              imagePath: item.imageUrl, width: 56, height: 56),
                        ),
                        title: Text(
                          item.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontFamily: 'Lato'),
                        ),
                        subtitle: Text(
                          'Rs. ${item.price.toStringAsFixed(0)} · ${item.category}\nImage: ${item.imageUrl}',
                          style: AppTextStyles.labelSmall,
                        ),
                        isThreeLine: true,
                        trailing:
                            Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: AppColors.primary),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      MenuItemFormScreen(existing: item)),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: AppColors.error),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Delete Item'),
                                  content: Text('Delete "${item.name}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.error),
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await context
                                    .read<MenuProvider>()
                                    .deleteItem(item.id);
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
        id: widget.existing?.id ??
            'local_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        imageUrl: imageUrl,
        category: _category!,
        price: double.parse(_priceCtrl.text.trim()),
        isVeg: _isVeg,
      );
      if (widget.existing != null) {
        await context
            .read<MenuProvider>()
            .updateItem(widget.existing!.id, item);
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
