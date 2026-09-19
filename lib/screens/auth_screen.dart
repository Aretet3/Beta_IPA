import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../services/auth_service.dart';
import '../config/app_config.dart';
import 'webview_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;
  String? _twoFactorTempToken;
  bool _showTwoFactor = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _twoFactorController = TextEditingController();
  final _serverController = TextEditingController(text: AppConfig.serverUrl);

  final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _serverController.text = AppConfig.serverUrl;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _twoFactorController.dispose();
    _serverController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AppConfig.setServerUrl(_serverController.text.trim());

      if (_showTwoFactor) {
        final result = await _auth.verifyTwoFactor(
          tempToken: _twoFactorTempToken!,
          code: _twoFactorController.text.trim(),
        );
        if (result['error'] != null) {
          setState(() => _error = result['error']);
          return;
        }
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const WebViewScreen()),
          );
        }
        return;
      }

      Map<String, dynamic> result;
      if (_isLogin) {
        result = await _auth.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        result = await _auth.register(
          fullName: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (result['twoFactorRequired'] == true) {
        setState(() {
          _twoFactorTempToken = result['tempToken'];
          _showTwoFactor = true;
          _loading = false;
        });
        return;
      }

      if (result['error'] != null) {
        setState(() {
          _error = result['error'];
          _loading = false;
        });
        return;
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WebViewScreen()),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF071126), Color(0xFF0D1B2A), Color(0xFF0A1628)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: size.width > 600 ? size.width * 0.25 : 24,
              vertical: 32,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  _buildLogo(),
                  const SizedBox(height: 40),
                  if (_showTwoFactor) ...[
                    _buildTwoFactorSection(),
                  ] else ...[
                    _buildAuthFields(),
                  ],
                  const SizedBox(height: 16),
                  if (_error != null) _buildError(),
                  const SizedBox(height: 24),
                  _buildSubmitButton(),
                  const SizedBox(height: 16),
                  _buildServerUrlToggle(),
                  if (!_showTwoFactor) ...[
                    const SizedBox(height: 24),
                    _buildSwitchAuthMode(),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF4DC8F0), Color(0xFF8B5CF6)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4DC8F0).withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'B',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Beta',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildAuthFields() {
    return Column(
      children: [
        if (!_isLogin) ...[
          _buildField(_nameController, 'Имя', Icons.person_outline),
          const SizedBox(height: 12),
          _buildField(_usernameController, 'Username', Icons.alternate_email),
          const SizedBox(height: 12),
        ],
        _buildField(_emailController, 'Email', Icons.email_outlined,
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        _buildField(
          _passwordController,
          'Пароль',
          Icons.lock_outline,
          obscure: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.white38,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ],
    );
  }

  Widget _buildTwoFactorSection() {
    return Column(
      children: [
        Icon(Icons.security, size: 48, color: const Color(0xFF4DC8F0)),
        const SizedBox(height: 16),
        const Text(
          'Двухфакторная аутентификация',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Введите код из приложения-аутентификатора',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.5),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _buildField(
          _twoFactorController,
          'Код 2FA',
          Icons.pin,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      validator: (v) => (v == null || v.isEmpty) ? 'Обязательное поле' : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        prefixIcon: Icon(icon, color: Colors.white30, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF0D1B2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4DC8F0), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFff5f78).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFff5f78).withOpacity(0.3)),
      ),
      child: Text(
        _error!,
        style: const TextStyle(color: Color(0xFFff5f78), fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _loading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4DC8F0),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                _showTwoFactor
                    ? 'Подтвердить'
                    : (_isLogin ? 'Войти' : 'Регистрация'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildServerUrlToggle() {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(top: 8),
      title: Text(
        'Настройки сервера',
        style: TextStyle(
          fontSize: 12,
          color: Colors.white.withOpacity(0.3),
        ),
      ),
      leading: Icon(
        Icons.settings,
        size: 16,
        color: Colors.white.withOpacity(0.3),
      ),
      children: [
        _buildField(
          _serverController,
          'URL сервера',
          Icons.dns,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSwitchAuthMode() {
    return TextButton(
      onPressed: () => setState(() {
        _isLogin = !_isLogin;
        _error = null;
      }),
      child: Text(
        _isLogin
            ? 'Нет аккаунта? Регистрация'
            : 'Уже есть аккаунт? Войти',
        style: const TextStyle(
          color: Color(0xFF4DC8F0),
          fontSize: 14,
        ),
      ),
    );
  }
}
