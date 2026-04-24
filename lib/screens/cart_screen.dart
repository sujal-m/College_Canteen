part of '../main.dart';

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
