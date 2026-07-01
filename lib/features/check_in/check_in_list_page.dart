import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:listriq_app/core/database/app_database.dart';
import 'package:listriq_app/core/database/database_provider.dart';
import 'package:listriq_app/core/services/home_widget_service.dart';

/// Halaman daftar riwayat check-in + edit / delete.
class CheckInListPage extends ConsumerWidget {
  const CheckInListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkInsAsync = ref.watch(allCheckInsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Check-In'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed('/check-in'),
        tooltip: 'Tambah Check-In',
        child: const Icon(Icons.add),
      ),
      body: checkInsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (checkIns) {
          if (checkIns.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Belum ada data check-in',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          // Urut descending by date
          final sorted = [...checkIns]
            ..sort((a, b) => b.date.compareTo(a.date));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final item = sorted[i];
              final formatted =
                  DateFormat('dd/MM/yyyy HH:mm').format(item.date);
              return Dismissible(
                key: Key('checkin_${item.id}'),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => _confirmDelete(context, ref, item),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: ListTile(
                  title: Text(
                    '${item.remainingKWh.toStringAsFixed(1)} kWh',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(formatted),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => Navigator.of(context).pushNamed(
                          '/check-in',
                          arguments: item,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20,
                            color: Colors.red),
                        onPressed: () =>
                            _confirmDelete(context, ref, item),
                      ),
                    ],
                  ),
                  onTap: () => Navigator.of(context).pushNamed(
                    '/check-in',
                    arguments: item,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<bool?> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    MeterCheckIn item,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Check-In'),
        content: Text(
          'Yakin hapus check-in ${item.remainingKWh.toStringAsFixed(1)} kWh '
          '(${DateFormat('dd/MM/yyyy HH:mm').format(item.date)})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true) return false;
      final db = await ref.read(databaseProvider.future);
      await db.deleteCheckIn(item.id);
      ref.invalidate(allCheckInsProvider);
      ref.invalidate(latestCheckInProvider);
      await HomeWidgetService.updateWidget(db);
      return false; // dismiss animation tetap jalan
    });
  }
}
