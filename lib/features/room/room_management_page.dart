import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:listriq_app/core/services/firebase_service.dart';

/// Halaman Buat / Gabung Kos.
class RoomManagementPage extends ConsumerStatefulWidget {
  const RoomManagementPage({super.key});

  @override
  ConsumerState<RoomManagementPage> createState() =>
      _RoomManagementPageState();
}

class _RoomManagementPageState extends ConsumerState<RoomManagementPage> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isCreating = false;
  bool _isJoining = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _isCreating = true);
    try {
      final code = await FirebaseService.createRoom(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kos "$name" dibuat! Kode invite: $code'),
            duration: const Duration(seconds: 5),
          ),
        );
        _nameController.clear();
      }
    } catch (e) {
      _showError('Gagal buat kos: $e');
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _joinRoom() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() => _isJoining = true);
    try {
      await FirebaseService.joinRoom(code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil gabung kos!')),
        );
        _codeController.clear();
      }
    } catch (e) {
      _showError('Gagal gabung: $e');
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode Kos'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── SECTION: Buat Kos ─────────────────────────────
            Icon(Icons.home, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              'Buat Kos Baru',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Buat grup untuk berbagi info token dengan teman satu kos.\n'
              'Hanya data ringan yang disimpan di cloud.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nama Kos',
                hintText: 'Contoh: Kos Pak RT',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.edit),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: _isCreating ? null : _createRoom,
                icon: _isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(_isCreating ? 'Membuat...' : 'Buat Kos'),
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // ── SECTION: Gabung Kos ───────────────────────────
            Icon(Icons.group_add, size: 48,
                color: theme.colorScheme.secondary),
            const SizedBox(height: 8),
            Text(
              'Gabung Kos',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Masukkan kode invite dari teman satu kos kamu.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Kode Invite',
                hintText: 'Tempel kode dari teman',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.vpn_key),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _isJoining ? null : _joinRoom,
                icon: _isJoining
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login),
                label:
                    Text(_isJoining ? 'Bergabung...' : 'Gabung Kos'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
