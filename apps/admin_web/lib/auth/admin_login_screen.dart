import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/rbac/admin_access.dart';
import '../core/widgets/admin_tokens.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AdminGradients.command),
        child: Stack(
          children: [
            Positioned(
              left: -120,
              top: -120,
              child: _LoginOrb(
                size: 300,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            Positioned(
              right: -90,
              bottom: -100,
              child: _LoginOrb(
                size: 260,
                color: AdminColors.accent.withValues(alpha: 0.22),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AdminSpacing.lg),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1040),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(AdminRadius.xl),
                          boxShadow: AdminShadows.floating,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: constraints.maxWidth < 820
                            ? Column(
                                children: [
                                  const _LoginBrandPanel(),
                                  _LoginForm(
                                    email: _email,
                                    password: _password,
                                    loading: _loading,
                                    error: _error,
                                    onSignIn: _signIn,
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  const Expanded(child: _LoginBrandPanel()),
                                  Expanded(
                                    child: _LoginForm(
                                      email: _email,
                                      password: _password,
                                      loading: _loading,
                                      error: _error,
                                      onSignIn: _signIn,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = FirebaseAuth.instance;
      await auth.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      final claims = await auth.currentUser?.getIdTokenResult(true);
      final role = roleFromClaims(claims?.claims);
      if (!mounted) return;
      if (role == null) {
        context.go('/access-denied');
      } else {
        context.go(firstAllowedPath(role));
      }
    } on FirebaseAuthException catch (error) {
      setState(() => _error = error.message ?? error.code);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _LoginBrandPanel extends StatelessWidget {
  const _LoginBrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 520),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF10131A),
            Color(0xFF163B44),
            Color(0xFF0E7C72),
          ],
        ),
      ),
      padding: const EdgeInsets.all(AdminSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AdminRadius.lg),
            ),
            child: const Icon(Icons.storefront, color: Colors.white, size: 30),
          ),
          const Spacer(),
          Text(
            'Run the marketplace like a command room.',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: AdminSpacing.md),
          const Text(
            'Staff-only access for moderation, merchants, users, campaigns, and audit trails.',
            style: TextStyle(color: Color(0xFFE5E7EB), height: 1.5),
          ),
          const SizedBox(height: AdminSpacing.lg),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _LoginPill('Custom Claims'),
              _LoginPill('Firestore Rules'),
              _LoginPill('Immutable Audit'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  final TextEditingController email;
  final TextEditingController password;
  final bool loading;
  final String? error;
  final VoidCallback onSignIn;

  const _LoginForm({
    required this.email,
    required this.password,
    required this.loading,
    required this.error,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AdminSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Olmeg Admin',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          const Text(
            'Sign in with an approved staff account.',
            style: TextStyle(color: AdminColors.muted),
          ),
          const SizedBox(height: AdminSpacing.xl),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
          const SizedBox(height: AdminSpacing.md),
          TextField(
            controller: password,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            obscureText: true,
            onSubmitted: (_) {
              if (!loading) onSignIn();
            },
          ),
          if (error != null) ...[
            const SizedBox(height: AdminSpacing.md),
            Container(
              decoration: BoxDecoration(
                color: AdminColors.dangerSoft,
                borderRadius: BorderRadius.circular(AdminRadius.md),
              ),
              padding: const EdgeInsets.all(AdminSpacing.md),
              child: Text(
                error!,
                style: const TextStyle(color: AdminColors.danger),
              ),
            ),
          ],
          const SizedBox(height: AdminSpacing.xl),
          FilledButton.icon(
            onPressed: loading ? null : onSignIn,
            icon: loading
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.login),
            label:
                Text(loading ? 'Checking access...' : 'Enter command center'),
          ),
        ],
      ),
    );
  }
}

class _LoginPill extends StatelessWidget {
  final String label;

  const _LoginPill(this.label);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _LoginOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _LoginOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
