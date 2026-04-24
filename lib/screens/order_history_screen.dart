part of '../main.dart';

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
