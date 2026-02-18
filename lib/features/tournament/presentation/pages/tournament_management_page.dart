import 'package:admissao_app/core/styles/app_theme.dart';
import 'package:admissao_app/features/tournament/domain/entities/team.dart';
import 'package:admissao_app/features/tournament/domain/entities/tournament.dart';
import 'package:admissao_app/features/tournament/presentation/bloc/tournament_cubit.dart';
import 'package:admissao_app/features/tournament/presentation/bloc/tournament_state.dart';
import 'package:admissao_app/features/tournament/presentation/pages/tournament_datail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TournamentManagementPage extends StatelessWidget {
  const TournamentManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Gerenciamento',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              decoration: BoxDecoration(
                color: HexColors.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const TabBar(
                indicator: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [HexColors.primary, HexColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: HexColors.textSubtle,
                labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'Equipes'),
                  Tab(text: 'Histórico'),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [_TeamsTab(), _HistoryTab()],
        ),
        floatingActionButton: _DynamicFab(),
      ),
    );
  }
}

// ── FAB dinâmico ──────────────────────────────────────────────────────────────

class _DynamicFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: DefaultTabController.of(context),
      builder: (ctx, _) {
        final index = DefaultTabController.of(ctx).index;
        if (index == 0) {
          return FloatingActionButton.extended(
            onPressed: () => _showTeamDialog(context),
            icon: const Icon(Icons.person_add),
            label: const Text('Novo Time', style: TextStyle(fontWeight: FontWeight.w700)),
            backgroundColor: HexColors.primary,
            foregroundColor: Colors.white,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ── Dialog de time ────────────────────────────────────────────────────────────

void _showTeamDialog(BuildContext context, {Team? team}) {
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
        team == null ? 'Novo Time' : 'Editar Equipe',
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

// ── Aba 1: Equipes ────────────────────────────────────────────────────────────

class _TeamsTab extends StatelessWidget {
  const _TeamsTab();

  @override
  Widget build(BuildContext context) {
    final teams = context.watch<TournamentCubit>().allTeamsFromDb;

    if (teams.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
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
              'Toque em + para adicionar.',
              style: TextStyle(color: HexColors.textSubtle, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: teams.length,
      itemBuilder: (context, index) {
        final team = teams[index];
        final initial = team.name.isNotEmpty ? team.name[0].toUpperCase() : '?';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: HexColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: HexColors.border),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: HexColors.cardHighlight,
                shape: BoxShape.circle,
                border: Border.all(color: HexColors.primary.withValues(alpha: 0.4)),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: HexColors.primary,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            title: Text(
              team.name,
              style: const TextStyle(fontWeight: FontWeight.w700, color: HexColors.textPrimary),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionBtn(
                  icon: Icons.edit_outlined,
                  color: HexColors.primary,
                  onTap: () => _showTeamDialog(context, team: team),
                ),
                const SizedBox(width: 8),
                _ActionBtn(
                  icon: Icons.delete_outline,
                  color: HexColors.danger,
                  onTap: () => context.read<TournamentCubit>().removeTeam(team.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Aba 2: Histórico de Copas ─────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TournamentCubit, TournamentState>(
      builder: (context, state) {
        final cubit = context.watch<TournamentCubit>();
        final started = cubit.startedTournaments;
        final ongoing = cubit.ongoingTournaments;
        final finished = cubit.finishedTournaments;

        if (state is TournamentLoading &&
            started.isEmpty &&
            ongoing.isEmpty &&
            finished.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: HexColors.primary));
        }

        if (started.isEmpty && ongoing.isEmpty && finished.isEmpty) {
          return const Center(
            child: Text(
              'Nenhuma copa encontrada.',
              style: TextStyle(color: HexColors.textSubtle),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            if (started.isNotEmpty) ...[
              _SectionHeader(label: 'Novas', icon: Icons.flag_outlined, color: const Color(0xFF4FC3F7)),
              ...started.map((t) => _HistoryCard(tournament: t)),
              const SizedBox(height: 8),
            ],
            if (ongoing.isNotEmpty) ...[
              _SectionHeader(label: 'Em Andamento', icon: Icons.sports_soccer, color: HexColors.primary),
              ...ongoing.map((t) => _HistoryCard(tournament: t)),
              const SizedBox(height: 8),
            ],
            if (finished.isNotEmpty) ...[
              _SectionHeader(label: 'Finalizadas', icon: Icons.emoji_events, color: HexColors.warning),
              ...finished.map((t) => _HistoryCard(tournament: t)),
            ],
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _SectionHeader({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Tournament tournament;
  const _HistoryCard({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final status = tournament.effectiveStatus;
    final Color color;
    final IconData icon;
    final String label;

    switch (status) {
      case TournamentStatus.started:
        color = const Color(0xFF4FC3F7);
        icon = Icons.flag_outlined;
        label = 'NOVA';
      case TournamentStatus.ongoing:
        color = HexColors.primary;
        icon = Icons.sports_soccer;
        label = 'EM JOGO';
      case TournamentStatus.finished:
        color = HexColors.warning;
        icon = Icons.emoji_events;
        label = 'FINALIZADA';
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TournamentDetailPage(
            tournamentId: tournament.id,
            tournamentName: tournament.name,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: HexColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: HexColors.border),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(
            tournament.name,
            style: const TextStyle(fontWeight: FontWeight.w700, color: HexColors.textPrimary),
          ),
          subtitle: Text(
            '${tournament.teams.length} times • ${tournament.format.label}',
            style: const TextStyle(color: HexColors.textSubtle, fontSize: 12),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 10),
                ),
              ),
              const SizedBox(width: 4),
              _ActionBtn(
                icon: Icons.edit_outlined,
                color: HexColors.primary,
                onTap: () => _showEditOptions(context, tournament),
              ),
              const SizedBox(width: 4),
              _ActionBtn(
                icon: Icons.delete_outline,
                color: HexColors.danger,
                onTap: () => _confirmDelete(context, tournament),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditOptions(BuildContext context, Tournament tournament) {
    showModalBottomSheet(
      context: context,
      backgroundColor: HexColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: HexColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: HexColors.primary),
              title: const Text('Renomear Copa', style: TextStyle(color: HexColors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameDialog(context, tournament);
              },
            ),
            ListTile(
              leading: const Icon(Icons.groups, color: HexColors.primary),
              title: Text(
                tournament.effectiveStatus == TournamentStatus.started
                    ? 'Gerenciar Times'
                    : 'Expulsar Times',
                style: const TextStyle(color: HexColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showTeamsSheet(context, tournament);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, Tournament tournament) {
    final controller = TextEditingController(text: tournament.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HexColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: HexColors.border),
        ),
        title: const Text('Renomear Copa', style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Novo nome'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: HexColors.textSubtle)),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != tournament.name) {
                context.read<TournamentCubit>().renameTournament(tournament.id, newName);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showTeamsSheet(BuildContext context, Tournament tournament) {
    final cubit = context.read<TournamentCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: HexColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _TeamsSheet(tournamentId: tournament.id),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Tournament tournament) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HexColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: HexColors.border),
        ),
        title: const Text('Excluir Copa', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          'Tem certeza que deseja excluir "${tournament.name}"?\n\nTodas as partidas serão apagadas.',
          style: const TextStyle(color: HexColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: HexColors.textSubtle)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: HexColors.danger),
            onPressed: () {
              context.read<TournamentCubit>().deleteTournament(tournament.id);
              Navigator.pop(ctx);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

// ── Sheet de times da copa ────────────────────────────────────────────────────

class _TeamsSheet extends StatelessWidget {
  final String tournamentId;
  const _TeamsSheet({required this.tournamentId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TournamentCubit, TournamentState>(
      builder: (context, state) {
        final cubit = context.read<TournamentCubit>();
        final found = cubit.tournaments.where((t) => t.id == tournamentId);
        if (found.isEmpty) {
          return const SizedBox(
            height: 120,
            child: Center(child: Text('Copa não encontrada.', style: TextStyle(color: HexColors.textSubtle))),
          );
        }
        final tournament = found.first;
        final canAdd = tournament.effectiveStatus == TournamentStatus.started;
        final available = cubit.allTeamsFromDb
            .where((t) => !tournament.teams.any((ct) => ct.id == t.id))
            .toList();

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (_, scrollController) => Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: HexColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  canAdd ? 'Gerenciar Times' : 'Expulsar Times',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: HexColors.textPrimary),
                ),
              ),
              const Divider(color: HexColors.border),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    ...tournament.teams.map(
                      (team) => _SheetTeamTile(
                        team: team,
                        icon: Icons.person_remove,
                        iconColor: HexColors.danger,
                        onAction: () => cubit.removeTeamFromTournament(tournamentId, team.id),
                      ),
                    ),
                    if (canAdd && available.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'ADICIONAR',
                          style: TextStyle(color: HexColors.primary, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1),
                        ),
                      ),
                      ...available.map(
                        (team) => _SheetTeamTile(
                          team: team,
                          icon: Icons.person_add,
                          iconColor: HexColors.success,
                          onAction: () => cubit.addTeamToTournament(tournamentId, team),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SheetTeamTile extends StatelessWidget {
  final Team team;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onAction;
  const _SheetTeamTile({required this.team, required this.icon, required this.iconColor, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final initial = team.name.isNotEmpty ? team.name[0].toUpperCase() : '?';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: HexColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HexColors.border),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: HexColors.cardHighlight,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w800, color: HexColors.primary)),
          ),
        ),
        title: Text(team.name, style: const TextStyle(fontWeight: FontWeight.w600, color: HexColors.textPrimary)),
        trailing: _ActionBtn(icon: icon, color: iconColor, onTap: onAction),
      ),
    );
  }
}

// ── Botão de ação pequeno ─────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
