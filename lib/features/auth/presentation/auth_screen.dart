import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/routes.dart';
import '../../../core/widget/components.dart';
import 'auth_view_model.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final email = TextEditingController(),
      password = TextEditingController(),
      name = TextEditingController();
  bool registering = false, obscure = true;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authViewModelProvider);
    ref.listen(authViewModelProvider, (previous, next) {
      final failure = next.failure;
      if (failure != null && failure != previous?.failure) {
        if (failure.code == 'EMAIL_ALREADY_REGISTERED' && registering) {
          setState(() => registering = false);
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(failure.message)));
      }
      if (next.status == AuthStatus.authenticated &&
          previous?.status != AuthStatus.authenticated) {
        final onboarding = ref.read(onboardingViewModelProvider);
        final target = next.user?.onboardingCompleted == true
            ? Routes.home
            : onboarding.selectedExam == null
            ? Routes.exams
            : Routes.value;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go(target);
        });
      }
    });
    void submit() {
      FocusScope.of(context).unfocus();
      ref
          .read(authViewModelProvider.notifier)
          .submit(
            email: email.text,
            password: password.text,
            displayName: registering ? name.text : null,
          );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Hatora hesabın')),
      body: PageBody(
        children: [
          Text(
            registering ? 'Hesabını oluştur' : 'Tekrar hoş geldin',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          const Text(
            'Hatalarını öğrenmeye dönüştür. Kayıtların hesabında seni beklesin.',
          ),
          const SizedBox(height: 28),
          AutofillGroup(
            child: Column(
              children: [
                if (registering) ...[
                  TextField(
                    controller: name,
                    enabled: !state.busy,
                    autofillHints: const [AutofillHints.name],
                    decoration: const InputDecoration(labelText: 'Adın'),
                  ),
                  const SizedBox(height: 14),
                ],
                TextField(
                  controller: email,
                  enabled: !state.busy,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'E-posta'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: password,
                  enabled: !state.busy,
                  obscureText: obscure,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: [
                    registering
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  textInputAction: TextInputAction.done,
                  onSubmitted: state.busy ? null : (_) => submit(),
                  decoration: InputDecoration(
                    labelText: 'Parola',
                    helperText: registering ? '8–100 karakter' : null,
                    suffixIcon: IconButton(
                      tooltip: obscure ? 'Parolayı göster' : 'Parolayı gizle',
                      onPressed: () => setState(() => obscure = !obscure),
                      icon: Icon(
                        obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (state.failure != null) ErrorView(error: state.failure!),
          HatoraPrimaryButton(
            label: registering ? 'Hesabımı oluştur' : 'Giriş yap',
            busyLabel: registering
                ? 'Hesap oluşturuluyor…'
                : 'Giriş yapılıyor…',
            busy: state.busy,
            onPressed: submit,
          ),
          TextButton(
            onPressed: state.busy
                ? null
                : () => setState(() => registering = !registering),
            child: Text(
              registering ? 'Zaten hesabım var' : 'Yeni hesap oluştur',
            ),
          ),
        ],
      ),
    );
  }
}
