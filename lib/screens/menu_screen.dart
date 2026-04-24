part of '../main.dart';

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

class _MenuListView extends StatefulWidget {
  final String filter;
  final String? selectedItemId;

  const _MenuListView({required this.filter, this.selectedItemId});

  @override
  State<_MenuListView> createState() => _MenuListViewState();
}

class _MenuListViewState extends State<_MenuListView> {
  final Map<String, GlobalKey> _itemKeys = {};

  @override
  void didUpdateWidget(covariant _MenuListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedItemId != oldWidget.selectedItemId ||
        widget.filter != oldWidget.filter) {
      _scrollToSelectedItem();
    }
  }

  void _scrollToSelectedItem() {
    final selectedItemId = widget.selectedItemId;
    if (selectedItemId == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = _itemKeys[selectedItemId]?.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
        alignment: 0.18,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
    final sourceItems =
        menuProvider.items.isNotEmpty ? menuProvider.items : _defaultMenuItems;
    final items = sourceItems
        .where(
            (item) => widget.filter == 'All' || item.category == widget.filter)
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
      itemBuilder: (_, i) {
        final item = items[i];
        return _MenuListItemCard(
          key: _itemKeys.putIfAbsent(item.id, () => GlobalKey()),
          item: item,
          highlighted: item.id == widget.selectedItemId,
        );
      },
    );
  }
}

class _MenuListItemCard extends StatelessWidget {
  final MenuItem item;
  final bool highlighted;

  const _MenuListItemCard({
    super.key,
    required this.item,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final qty = cart.items[item.id]?.quantity ?? 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.primary.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: highlighted
            ? Border.all(color: AppColors.primary.withOpacity(0.6), width: 1.5)
            : null,
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
  final ValueChanged<MenuItem> onItemTap;

  const _AnimatedSpecialsCarousel({
    required this.items,
    required this.onItemTap,
  });

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
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => widget.onItemTap(item),
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
