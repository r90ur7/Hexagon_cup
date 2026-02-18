import 'package:flutter/material.dart';
import 'package:admissao_app/core/di/injection.dart';
import 'package:admissao_app/core/styles/app_theme.dart';
import 'package:admissao_app/features/auth/data/repositories/auth_repository.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = sl<AuthRepository>();
    final user = authRepo.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Meu Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),

          // Avatar
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: HexColors.primary.withValues(alpha: 0.15),
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? const Icon(Icons.person, size: 50, color: HexColors.primary)
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          // Nome
          Center(
            child: Text(
              user?.displayName ?? 'Jogador Hexagon',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 4),

          // E-mail
          Center(
            child: Text(
              user?.email ?? '—',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: HexColors.textSubtle),
            ),
          ),
          const SizedBox(height: 40),

          // Informações da conta
          _SectionTitle(title: 'Informações da Conta'),
          const SizedBox(height: 12),

          _InfoTile(
            icon: Icons.email_outlined,
            label: 'E-mail',
            value: user?.email ?? '—',
          ),
          _InfoTile(
            icon: Icons.badge_outlined,
            label: 'UID',
            value: user?.uid ?? '—',
          ),
          _InfoTile(
            icon: Icons.calendar_today_outlined,
            label: 'Conta criada em',
            value: user?.metadata.creationTime != null
                ? _formatDate(user!.metadata.creationTime!)
                : '—',
          ),
          _InfoTile(
            icon: Icons.login_outlined,
            label: 'Último login',
            value: user?.metadata.lastSignInTime != null
                ? _formatDate(user!.metadata.lastSignInTime!)
                : '—',
          ),
          _InfoTile(
            icon: Icons.verified_outlined,
            label: 'E-mail verificado',
            value: user?.emailVerified == true ? 'Sim ✅' : 'Não ❌',
          ),

          const SizedBox(height: 40),

          // Ações
          _SectionTitle(title: 'Ações'),
          const SizedBox(height: 12),

          // Editar nome
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: HexColors.primary,
              ),
              title: const Text('Editar nome'),
              trailing: const Icon(
                Icons.chevron_right,
                color: HexColors.textSubtle,
              ),
              onTap: () => _showEditNameDialog(context, user?.displayName),
            ),
          ),
          const SizedBox(height: 8),

          // Enviar verificação de e-mail
          if (user?.emailVerified == false)
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.mark_email_read_outlined,
                  color: HexColors.warning,
                ),
                title: const Text('Verificar e-mail'),
                subtitle: const Text('Enviar link de verificação'),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: HexColors.textSubtle,
                ),
                onTap: () async {
                  await user?.sendEmailVerification();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('E-mail de verificação enviado!'),
                      ),
                    );
                  }
                },
              ),
            ),
          const SizedBox(height: 8),

          // Alterar senha
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.lock_reset_outlined,
                color: HexColors.warning,
              ),
              title: const Text('Redefinir senha'),
              subtitle: const Text('Envia link por e-mail'),
              trailing: const Icon(
                Icons.chevron_right,
                color: HexColors.textSubtle,
              ),
              onTap: () async {
                if (user?.email != null) {
                  await sl<AuthRepository>().resetPassword(user!.email!);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'E-mail de redefinição de senha enviado!',
                        ),
                      ),
                    );
                  }
                }
              },
            ),
          ),

          const SizedBox(height: 32),

          // Logout
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: HexColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(Icons.logout),
            label: const Text('SAIR DA CONTA'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} às '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  void _showEditNameDialog(BuildContext context, String? currentName) {
    final controller = TextEditingController(text: currentName ?? '');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar nome'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nome',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await sl<AuthRepository>().updateDisplayName(newName);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nome atualizado!')),
                  );
                  // Força rebuild para mostrar nome novo
                  (context as Element).markNeedsBuild();
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: HexColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await sl<AuthRepository>().logout();
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: HexColors.primary,
        fontWeight: FontWeight.w700,
        fontSize: 13,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: HexColors.primary),
        title: Text(
          label,
          style: const TextStyle(fontSize: 13, color: HexColors.textSubtle),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 15, color: HexColors.textPrimary),
        ),
      ),
    );
  }
}
