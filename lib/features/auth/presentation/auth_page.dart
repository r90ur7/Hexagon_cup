import 'package:flutter/material.dart';
import 'package:admissao_app/core/styles/app_theme.dart';
import 'package:admissao_app/core/di/injection.dart';
import 'package:admissao_app/features/auth/data/repositories/auth_repository.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepo = sl<AuthRepository>();
  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty)
      return;

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await _authRepo.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        await _authRepo.register(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      }
    } on Exception catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo / Ícone
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: HexColors.primary.withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.sports_soccer,
                  size: 80,
                  color: HexColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _isLogin ? "Bem-vindo de volta" : "Criar nova conta",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin
                    ? "Entre para gerenciar seus torneios"
                    : "Cadastre-se para começar",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 40),
              // E-mail
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "E-mail",
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              // Senha
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Senha",
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 32),
              // Botão principal
              _isLoading
                  ? const CircularProgressIndicator(color: HexColors.primary)
                  : ElevatedButton(
                      onPressed: _submit,
                      child: Text(_isLogin ? "ENTRAR" : "CADASTRAR"),
                    ),
              const SizedBox(height: 12),
              // Alternar login/cadastro
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin
                      ? "Não tem conta? Cadastre-se"
                      : "Já tem conta? Faça Login",
                  style: const TextStyle(color: HexColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
