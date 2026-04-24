part of '../main.dart';

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
                color: notification.read ? Colors.white : AppColors.bg,
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
                      Text(notification.message,
                          style: AppTextStyles.bodyMedium),
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
                  onTap: () => FirebaseService.markNotificationRead(
                      userId, notification.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
