import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../providers/auth_provider.dart';
import '../providers/firestore_provider.dart';
import '../theme/app_palette.dart';
import '../theme/app_radii.dart';
import '../widgets/app_drawer.dart';
import '../widgets/theme_mode_selector.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final AnimationController _logoController;
  late final Animation<double> _logoAnimation;

  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _passwordErrorText;
  String? _emailErrorText;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    );
    _logoController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The viewport must shrink for the keyboard: in sign-up mode the card is
      // tall enough that the submit button would otherwise sit under it with
      // no scrollable overflow to reach.
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                    ScaleTransition(
                      scale: _logoAnimation,
                      child: const _LoginLogo(),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      _isSignUp
                          ? context.strings.createYourAccount
                          : context.strings.welcome,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSignUp
                          ? context.strings.signUpIntro
                          : context.strings.signInIntro,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.palette.bodyText,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.palette.surface,
                        borderRadius: BorderRadius.circular(AppRadii.xl),
                        border: Border.all(color: context.palette.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            autofocus: true,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: context.strings.email,
                              hintText: 'you@example.com',
                              errorText: _emailErrorText,
                              prefixIcon:
                                  const Icon(Icons.account_circle_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return context.strings.enterYourEmail;
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) {
                              FocusScope.of(context).nextFocus();
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: _isSignUp
                                ? TextInputAction.next
                                : TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: context.strings.password,
                              helperText: _isSignUp
                                  ? context.strings.atLeast6Chars
                                  : null,
                              errorText: _passwordErrorText,
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? context.strings.showPassword
                                    : context.strings.hidePassword,
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            onFieldSubmitted: (_) {
                              if (_isSignUp) {
                                FocusScope.of(context).nextFocus();
                              } else {
                                _submit();
                              }
                            },
                          ),
                          if (_isSignUp) ...[
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                labelText: context.strings.confirmPassword,
                                prefixIcon:
                                    const Icon(Icons.lock_reset_rounded),
                              ),
                              onFieldSubmitted: (_) => _submit(),
                            ),
                          ],
                          if (!_isSignUp) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  activeColor: context.palette.primary,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                ),
                                Expanded(
                                  child: Text(
                                    context.strings.rememberMe,
                                    style: TextStyle(
                                      color: context.palette.bodyText,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed:
                                      _isLoading ? null : _forgotPassword,
                                  child: Text(context.strings.forgot),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 10),
                          FilledButton.icon(
                            onPressed: _isLoading ? null : _submit,
                            icon: _isLoading
                                ? SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: context.palette.onPrimary,
                                    ),
                                  )
                                : Icon(
                                    _isSignUp
                                        ? Icons.person_add_alt_1_rounded
                                        : Icons.login_rounded,
                                  ),
                            label: Text(_submitLabel),
                          ),
                          const SizedBox(height: 16),
                          const _OrDivider(),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _continueWithGoogle,
                            icon: const _GoogleMark(),
                            label: Text(
                              _isSignUp
                                  ? context.strings.signUpWithGoogle
                                  : context.strings.continueWithGoogle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: _isLoading ? null : _toggleMode,
                      child: Text(
                        _isSignUp
                            ? context.strings.haveAccountSignIn
                            : context.strings.newHereCreate,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // The first screen anyone sees, so the language switch
                    // has to be reachable before signing in.
                    const LanguageSelector(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _submitLabel {
    final strings = context.strings;
    if (_isLoading) {
      return _isSignUp ? strings.creatingAccount : strings.signingIn;
    }
    return _isSignUp ? strings.createAccount : strings.continueLabel;
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _emailErrorText = null;
      _passwordErrorText = null;
      _confirmPasswordController.clear();
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (password.isEmpty) {
      setState(() {
        _passwordErrorText = context.strings.enterPassword;
      });
      return;
    }

    if (_isSignUp && password != _confirmPasswordController.text) {
      setState(() {
        _passwordErrorText = context.strings.passwordsDontMatch;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _passwordErrorText = null;
      _emailErrorText = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      final credential = _isSignUp
          ? await auth.signUpWithEmail(email: email, password: password)
          : await auth.signInWithEmail(email: email, password: password);

      await _openWorkspace(
        credential.user,
        isNewUser: credential.additionalUserInfo?.isNewUser ?? _isSignUp,
      );
    } on FirebaseAuthException catch (error) {
      _showAuthError(error);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _continueWithGoogle() async {
    final strings = context.strings;
    setState(() {
      _isLoading = true;
      _passwordErrorText = null;
      _emailErrorText = null;
    });

    try {
      final credential = await ref.read(authServiceProvider).signInWithGoogle();
      await _openWorkspace(
        credential.user,
        isNewUser: credential.additionalUserInfo?.isNewUser ?? false,
      );
    } on FirebaseAuthException catch (error) {
      _showAuthError(error);
    } catch (error) {
      // The plugin throws PlatformException for setup problems — a missing
      // SHA-1 fingerprint surfaces here as ApiException: 10.
      _showMessage(strings.googleSignInFailed(error));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Creates the account's profile document — and, for the seed account, pulls
  /// in the pre-multi-user data — before any screen reads Firestore.
  Future<void> _openWorkspace(User? user, {required bool isNewUser}) async {
    if (user == null) return;
    final strings = context.strings;
    final error = await syncUserWorkspace(
      ref.read(firestoreServiceProvider),
      user,
    );

    // Shown before navigating: the message belongs to the app-level
    // ScaffoldMessenger, but this screen is disposed by pushReplacement.
    if (error != null) {
      _showMessage(strings.dataNotLoaded(error));
    }

    if (mounted) {
      // A brand-new account picks which features it wants before seeing the
      // full app; returning users go straight to their day.
      Navigator.of(context).pushReplacementNamed(
        isNewUser ? AppRoutes.moduleSetup : AppRoutes.home,
      );
    }
  }

  void _showAuthError(FirebaseAuthException error) {
    if (!mounted) return;

    final strings = context.strings;
    setState(() {
      switch (error.code) {
        case 'invalid-email':
          _emailErrorText = strings.enterValidEmail;
        case 'email-already-in-use':
          _emailErrorText = strings.emailInUse;
        case 'user-not-found':
        case 'user-disabled':
          _emailErrorText = strings.noAccountForEmail;
        case 'weak-password':
          _passwordErrorText = strings.useAtLeast6Chars;
        case 'wrong-password':
        case 'invalid-credential':
          _passwordErrorText = strings.incorrectPassword;
        case 'too-many-requests':
          _passwordErrorText = strings.tooManyAttempts;
        case 'account-exists-with-different-credential':
          _emailErrorText = strings.linkGoogleHint;
        case 'operation-not-allowed':
          _emailErrorText = strings.signInMethodDisabled;
        case 'web-context-canceled':
        case 'canceled':
          break;
        default:
          _passwordErrorText = strings.signInFailed(error.message);
      }
    });
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    final strings = context.strings;
    if (email.isEmpty) {
      setState(() {
        _emailErrorText = strings.enterEmailToReset;
      });
      return;
    }

    try {
      await ref.read(authServiceProvider).sendPasswordResetEmail(email);
      _showMessage(strings.resetEmailSent(email));
    } on FirebaseAuthException catch (error) {
      _showMessage(strings.resetEmailFailed(error.message));
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      children: [
        Expanded(child: Divider(color: palette.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            context.strings.or,
            style: TextStyle(
              color: palette.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Divider(color: palette.divider)),
      ],
    );
  }
}

/// The Google "G" drawn from its four brand colours, so no network image or
/// bundled asset is needed for the button.
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 18,
      child: CustomPaint(painter: _GoogleMarkPainter()),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.22;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    // Four quarter arcs, starting at the 3 o'clock position.
    const quarter = 1.5707963267948966;
    const arcs = [
      (-quarter, _red),
      (-quarter * 2, _yellow),
      (quarter * 2, _green),
      (0.0, _blue),
    ];
    for (final (start, color) in arcs) {
      canvas.drawArc(rect, start, quarter, false, paint..color = color);
    }

    // The crossbar of the G.
    canvas.drawLine(
      Offset(size.width * 0.52, size.height / 2),
      Offset(size.width - stroke / 2, size.height / 2),
      paint..color = _blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LoginLogo extends StatelessWidget {
  const _LoginLogo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [context.palette.primary, context.palette.violet],
          ),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          boxShadow: [
            BoxShadow(
              color: context.palette.primary.withOpacity(0.28),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(
          Icons.sync_rounded,
          color: context.palette.onPrimary,
          size: 36,
        ),
      ),
    );
  }
}
