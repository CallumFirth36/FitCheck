import 'package:flutter/material.dart';
import 'package:fitcheck/services/auth_service.dart';
import 'package:fitcheck/services/settings_service.dart';
import 'package:fitcheck/services/wardrobe_service.dart';
import 'package:fitcheck/widgets/gradient_background.dart';
import 'package:fitcheck/core/app_colours.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  // Signs the user out of Firebase. AuthLayout shows login
  Future<void> _logout() async {
    try {
      await authService.value.signOut();
    } on FirebaseAuthException catch (e) {
      print(e.message);
    }
  }

  void _openChangePassword(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ChangePasswordDialog(),
    );
  }

  void _openDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DeleteAccountDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'My Account',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textOnDark,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: GradientBackground(
        colours: AppColors.authGradient,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, kToolbarHeight + 16, 24, 24),
            children: [
              // change password
              _AccountRow(
                label: 'Change Password',
                icon: Icons.lock_outline,
                onTap: () => _openChangePassword(context),
              ),
              const _RowDivider(),

              // expands in place to show the preference options
              const _PreferencesSection(),
              const _RowDivider(),

              // Delete account button
              _AccountRow(
                label: 'Delete Account',
                icon: Icons.delete_outline,
                color: Colors.redAccent,
                onTap: () => _openDeleteAccount(context),
              ),
              const _RowDivider(),

              const SizedBox(height: 40),

              // log out
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Log Out', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Error Codes
String _messageFor(FirebaseAuthException e) {
  switch (e.code) {
    case 'wrong-password':
    case 'invalid-credential':
      return 'That password is incorrect.';
    case 'weak-password':
      return 'The new password is too weak.';
    case 'requires-recent-login':
      return 'For security, log out and back in, then try again.';
    case 'too-many-requests':
      return 'Too many attempts. Please try again later.';
    case 'network-request-failed':
      return 'No connection. Check your internet.';
    default:
      return 'Something went wrong. Please try again.';
  }
}


// Change password
class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  bool _loading = false;
  String? _error; // shown under the fields when something is wrong

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentController.text;
    final next = _newController.text;

    if (current.isEmpty) {
      setState(() => _error = 'Enter your current password.');
      return;
    }
    if (next.length < 6) {
      setState(() => _error = 'New password must be at least 6 characters.');
      return;
    }

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await authService.value.resetPasswordFromCurrentPassword(
        currentPassword: current,
        newPassword: next,
      );
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Password updated.')));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _messageFor(e);
      });
    } catch (e) {
      print(e);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _currentController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New password (6+ characters)',
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
}

// Delete account
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _error = 'Enter your password to confirm.');
      return;
    }

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await authService.value.reauthenticate(password: password);

      await wardrobeService.deleteAllItems();

      await authService.value.deleteAccount();

      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Your account has been deleted.')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _messageFor(e);
      });
    } catch (e) {
      print(e);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = "Couldn't delete your data. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete account?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This permanently deletes your account and every item in your '
              'wardrobe. This cannot be undone.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Enter your password to confirm',
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}

// preferences - text size
class _PreferencesSection extends StatelessWidget {
  const _PreferencesSection();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        shape: Border(),
        collapsedShape: Border(),
        iconColor: Colors.white70,
        collapsedIconColor: Colors.white70,
        leading: Icon(Icons.tune, color: AppColors.textOnDark),
        title: Text(
          'Preferences',
          style: TextStyle(fontSize: 18, color: AppColors.textOnDark),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 40, right: 8, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Text size',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textOnDark,
                    ),
                  ),
                  const SizedBox(height: 8),

                  ValueListenableBuilder<TextSizeOption>(
                    valueListenable: settingsService.textSize,
                    builder: (context, current, _) {
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: TextSizeOption.values.map((option) {
                          return ChoiceChip(
                            label: Text(option.label),
                            selected: current == option,
                            selectedColor: AppColors.accent,
                            onSelected: (_) =>
                                settingsService.setTextSize(option),
                          );
                        }).toList(),
                      );
                    },
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

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.label,
    required this.icon,
    this.onTap,
    this.color = AppColors.textOnDark,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: color),
        title: Text(label, style: TextStyle(fontSize: 18, color: color)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white70),
        onTap: onTap ?? () {},
      ),
    );
  }
}

// line between options
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 0.5, color: Colors.white24);
  }
}