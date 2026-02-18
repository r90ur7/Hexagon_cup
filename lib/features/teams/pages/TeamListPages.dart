import 'package:admissao_app/core/styles/app_theme.dart';
import 'package:admissao_app/features/tournament/domain/entities/team.dart';
import 'package:admissao_app/features/tournament/presentation/bloc/tournament_cubit.dart';
import 'package:admissao_app/features/tournament/presentation/bloc/tournament_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── Função top-level para abrir o form de time ──────────────────────────────
void showTeamForm(BuildContext context, {Team? team}) {
  final controller = TextEditingController(text: team?.name);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: HexColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: HexColors.border),
      ),
      title: Text(
        team == null ? 'Novo Time' : 'Editar Time',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(labelText: 'Nome do time'),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar', style: TextStyle(color: HexColors.textSubtle)),
        ),
        ElevatedButton(
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              context.read<TournamentCubit>().addOrUpdateTeam(
                id: team?.id,
                name: controller.text.trim(),
              );
              Navigator.pop(ctx);
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    ),
  );
}

class TeamListPage extends StatefulWidget {
  const TeamListPage({super.key});

  @override
  State<TeamListPage> createState() => _TeamListPageState();
}

class _TeamListPageState extends State<TeamListPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Times', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _HexButton(
              label: '+ Criar Time',
              onTap: () => showTeamForm(context),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Barra de busca ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Buscar times...',
                hintStyle: TextStyle(color: HexColors.textSubtle),
                prefixIcon: Icon(Icons.search, color: HexColors.textSubtle),
              ),
            ),
          ),

          // ── Grid de times ───────────────────────────────────
          Expanded(
            child: BlocBuilder<TournamentCubit, TournamentState>(
              builder: (context, state) {
                final all = context.watch<TournamentCubit>().allTeamsFromDb;
                final teams = _search.isEmpty
                    ? all
                    : all.where((t) => t.name.toLowerCase().contains(_search)).toList();

                if (all.isEmpty) {
                  return _EmptyState(onAdd: () => showTeamForm(context));
                }

                if (teams.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhum time encontrado.',
                      style: TextStyle(color: HexColors.textSubtle),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: teams.length,
                  itemBuilder: (context, index) =>
                      _TeamCard(team: teams[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

}

// ── Card individual de time ──────────────────────────────────────────────────

class _TeamCard extends StatelessWidget {
  final Team team;
  const _TeamCard({required this.team});

  @override
  Widget build(BuildContext context) {
    final initial = team.name.isNotEmpty ? team.name[0].toUpperCase() : '?';

    return Container(
      decoration: BoxDecoration(
        color: HexColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: HexColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Escudo / Avatar ────────────────────────────────
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: HexColors.cardHighlight,
              shape: BoxShape.circle,
              border: Border.all(color: HexColors.primary.withValues(alpha: 0.4)),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: HexColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Nome ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              team.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: HexColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Ações ──────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionIcon(
                icon: Icons.edit_outlined,
                color: HexColors.primary,
                onTap: () => showTeamForm(context, team: team),
              ),
              const SizedBox(width: 16),
              _ActionIcon(
                icon: Icons.delete_outline,
                color: HexColors.danger,
                onTap: () => context.read<TournamentCubit>().removeTeam(team.id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Ícone de ação circular ───────────────────────────────────────────────────

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionIcon({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

// ── Botão estilo Hexagon (AppBar) ────────────────────────────────────────────

class _HexButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _HexButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [HexColors.primary, HexColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Estado vazio ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: HexColors.cardHighlight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_outlined, size: 48, color: HexColors.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum time cadastrado.',
            style: TextStyle(fontWeight: FontWeight.w700, color: HexColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Crie o primeiro time para começar.',
            style: TextStyle(color: HexColors.textSubtle, fontSize: 13),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [HexColors.primary, HexColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                '+ Criar primeiro time',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}