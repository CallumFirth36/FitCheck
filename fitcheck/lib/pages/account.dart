import 'package:flutter/material.dart';
import 'package:fitcheck/services/auth_service.dart';
import 'package:fitcheck/widgets/gradient_background.dart';
import 'package:fitcheck/core/app_colours.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  // Signs the user out of Firebase.
  // CHANGE: no popPage() any more. This page is a tab inside
  // AppNavigationLayout, so there is nothing to pop. Once signOut()
  // finishes, AuthLayout notices and shows the login page by itself.
  Future<void> _logout() async {
    try {
      await authService.value.signOut();
    } on FirebaseAuthException catch (e) {
      print(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // lets the gradient show behind the (transparent) app bar, like HomePage
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
            // top padding (kToolbarHeight) keeps the list below the app bar
            padding: const EdgeInsets.fromLTRB(24, kToolbarHeight + 16, 24, 24),
            children: [
              // ---- Placeholder rows: replace the labels and add onTap later ----
              const _AccountRow(label: 'Edit Profile', icon: Icons.person_outline),
              const _RowDivider(),
              const _AccountRow(label: 'Change Password', icon: Icons.lock_outline),
              const _RowDivider(),
              const _AccountRow(label: 'Preferences', icon: Icons.tune),
              const _RowDivider(),
              const _AccountRow(label: 'About', icon: Icons.info_outline),
              const _RowDivider(),

              const SizedBox(height: 40),

              // ---- Red log out button ----
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
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

// One row in the list: icon, label and a small arrow. Not a button visually,
// but it still reacts to taps if you give it an onTap later.
class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.label, required this.icon, this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback? onTap; // optional: what happens when the row is tapped

  @override
  Widget build(BuildContext context) {
    // Transparent Material so the tap ripple shows on top of the gradient
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: AppColors.textOnDark),
        title: Text(
          label,
          style: const TextStyle(fontSize: 18, color: AppColors.textOnDark),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white70),
        onTap: onTap ?? () {}, // placeholder: does nothing yet
      ),
    );
  }
}

// The thin line between rows. Delete the _RowDivider() lines above for no lines.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 0.5, color: Colors.white24);
  }
}