import 'package:admissao_app/core/styles/app_theme.dart';
import 'package:admissao_app/features/auth/presentation/profile_page.dart';
import 'package:admissao_app/features/tournament/domain/entities/tournament.dart';
import 'package:admissao_app/features/tournament/presentation/pages/tournament_datail_page.dart';
import 'package:admissao_app/features/tournament/presentation/pages/tournament_management_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/tournament_cubit.dart';
import '../bloc/tournament_state.dart';
import 'tournament_create_page.dart';

class TournamentListPage extends StatefulWidget {
  const TournamentListPage({super.key});

  @override
  State<TournamentListPage> createState() => _TournamentListPageState();
}

class _TournamentListPageState extends State<TournamentListPage> {
  @override
  void initState() {
    super.initState();
    context.read<TournamentCubit>().loadTournaments();
    context.read<TournamentCubit>().fetchTeams();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [HexColors.primary, HexColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.sports_soccer,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Hexagon Cup',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: HexColors.cardHighlight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: HexColors.border),
              ),
              child: const Icon(
                Icons.person_outline,
                color: HexColors.primary,
                size: 20,
              ),
            ),
            tooltip: 'Meu Perfil',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: HexColors.cardHighlight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: HexColors.border),
              ),
              child: const Icon(
                Icons.settings_outlined,
                color: HexColors.primary,
                size: 20,
              ),
            ),
            tooltip: 'Gerenciamento',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TournamentManagementPage(),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TournamentCreatePage()),
        ),
        icon: const Icon(Icons.add),
        label: const Text(
          'Nova Copa',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: HexColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<TournamentCubit, TournamentState>(
      builder: (context, state) {
        final list = context.watch<TournamentCubit>().tournaments;

        if (state is TournamentLoading && list.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: HexColors.primary),
          );
        }

        if (list.isEmpty) {
          return _EmptyTournaments(
            onCreateTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TournamentCreatePage()),
            ),
          );
        }

        return RefreshIndicator(
          color: HexColors.primary,
          backgroundColor: HexColors.surface,
          onRefresh: () => context.read<TournamentCubit>().loadTournaments(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: list.length,
            itemBuilder: (context, index) => _TournamentCard(
              tournament: list[index],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TournamentDetailPage(
                    tournamentId: list[index].id,
                    tournamentName: list[index].name,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Card de Copa ─────────────────────────────────────────────────────────────

class _TournamentCard extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback onTap;
  const _TournamentCard({required this.tournament, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sv = _statusConfig(tournament.effectiveStatus);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: HexColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: HexColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // ── Ícone de status ──────────────────────────────
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: sv.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(sv.icon, color: sv.color, size: 26),
              ),
              const SizedBox(width: 14),

              // ── Info ─────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tournament.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: HexColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tournament.teams.length} times • ${tournament.format.label}',
                      style: const TextStyle(
                        color: HexColors.textSubtle,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Badge de status ──────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: sv.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  sv.label,
                  style: TextStyle(
                    color: sv.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: HexColors.textSubtle,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Estado vazio ─────────────────────────────────────────────────────────────

class _EmptyTournaments extends StatelessWidget {
  final VoidCallback onCreateTap;
  const _EmptyTournaments({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: HexColors.cardHighlight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events_outlined,
                size: 56,
                color: HexColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Nenhuma copa criada',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: HexColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crie sua primeira copa e comece a competição!',
              textAlign: TextAlign.center,
              style: TextStyle(color: HexColors.textSubtle, fontSize: 14),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: onCreateTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [HexColors.primary, HexColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: HexColors.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Text(
                  '+ Criar primeira copa',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Config de status ──────────────────────────────────────────────────────────

class _StatusConfig {
  final IconData icon;
  final Color color;
  final String label;
  const _StatusConfig(this.icon, this.color, this.label);
}

_StatusConfig _statusConfig(TournamentStatus status) {
  switch (status) {
    case TournamentStatus.started:
      return const _StatusConfig(
        Icons.flag_outlined,
        Color(0xFF4FC3F7),
        'NOVA',
      );
    case TournamentStatus.ongoing:
      return const _StatusConfig(
        Icons.sports_soccer,
        HexColors.primary,
        'EM JOGO',
      );
    case TournamentStatus.finished:
      return const _StatusConfig(
        Icons.emoji_events,
        HexColors.warning,
        'FINALIZADA',
      );
  }
}
