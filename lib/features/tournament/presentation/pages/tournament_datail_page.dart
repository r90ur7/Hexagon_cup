import 'dart:ui';

import 'package:admissao_app/core/styles/app_theme.dart';
import 'package:admissao_app/features/tournament/presentation/pages/widgets/tournament_bracket_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/team_stats.dart';
import '../../domain/usecases/calculate_standings.dart';
import '../../../../core/di/injection.dart';
import '../../domain/repositories/tournament_repository.dart';
import '../bloc/tournament_cubit.dart';

class TournamentDetailPage extends StatelessWidget {
  final String tournamentId;
  final String tournamentName;

  const TournamentDetailPage({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            tournamentName,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () async {
                final matches = await sl<TournamentRepository>()
                    .watchTournamentMatches(tournamentId)
                    .first;
                _exportTournamentSummary(tournamentName, matches);

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Resumo copiado para a área de transferência! 📋',
                    ),
                    backgroundColor: HexColors.success,
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => _showStartKnockoutDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [HexColors.primary, HexColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.next_plan, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Mata-Mata',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'Classificação'),
                  Tab(text: 'Jogos'),
                ],
              ),
            ),
          ),
        ),
        body: StreamBuilder<List<Match>>(
          stream: sl<TournamentRepository>().watchTournamentMatches(
            tournamentId,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: HexColors.primary),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: HexColors.danger,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Erro ao carregar partidas',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: HexColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${snapshot.error}',
                      style: const TextStyle(
                        color: HexColors.textSubtle,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final matches = snapshot.data ?? [];

            return TabBarView(
              children: [
                _buildStandingsTab(matches),
                _buildMatchesTab(context, matches),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Aba de Classificação ──────────────────────────────────────────────────

  Widget _buildStandingsTab(List<Match> matches) {
    final groups = <String, List<Match>>{};
    for (var m in matches) {
      if (m.groupName != null) {
        groups.putIfAbsent(m.groupName!, () => []).add(m);
      }
    }

    if (groups.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.table_chart_outlined,
              color: HexColors.primary,
              size: 48,
            ),
            SizedBox(height: 12),
            Text(
              'Nenhuma fase de grupos.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: HexColors.textPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Esta copa usa formato de mata-mata direto.',
              style: TextStyle(color: HexColors.textSubtle, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: groups.entries.map((entry) {
        final teamsInGroup = _getTeamsFromMatches(entry.value);
        final standings = sl<CalculateStandingsUseCase>().call(
          teamsInGroup,
          entry.value,
          seed: tournamentId,
        );
        return _GroupTable(groupName: entry.key, standings: standings);
      }).toList(),
    );
  }

  // ── Aba de Jogos ──────────────────────────────────────────────────────────
  Widget _buildMatchesTab(BuildContext context, List<Match> matches) {
    final championName = _getChampionName(matches);

    final groupMatches = matches.where((m) => m.groupName != null).toList();
    final knockoutMatches = matches.where((m) => m.groupName == null).toList();
    knockoutMatches.sort((a, b) => a.round.compareTo(b.round));

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 32),
      children: [
        if (championName != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _ChampionBanner(name: championName),
          ),

        if (knockoutMatches.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: _SectionLabel(
              label: 'Chaveamento Principal',
              icon: Icons.account_tree_outlined,
            ),
          ),
          const SizedBox(height: 12),
          TournamentBracketView(
            matches: knockoutMatches,
            championName: championName,
          ),
          const SizedBox(height: 32),
        ],

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (groupMatches.isNotEmpty) ...[
                const _SectionLabel(
                  label: 'Fase de Grupos',
                  icon: Icons.groups_outlined,
                ),
                const SizedBox(height: 12),
                ...groupMatches.map(
                  (m) => _MatchCard(
                    match: m,
                    onTap: () => _showEditScoreDialog(context, m),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              if (knockoutMatches.isNotEmpty) ...[
                const _SectionLabel(
                  label: 'Confrontos Diretos',
                  icon: Icons.list,
                ),
                const SizedBox(height: 12),
                ..._buildKnockoutSections(context, knockoutMatches),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _exportTournamentSummary(String name, List<Match> matches) {
    final champion = _getChampionName(matches);
    final knockoutMatches = matches.where((m) => m.groupName == null).toList();
    knockoutMatches.sort((a, b) => a.round.compareTo(b.round));

    StringBuffer buffer = StringBuffer();
    buffer.writeln("RESUMO: $name\n");

    if (champion != null) {
      buffer.writeln("CAMPEÃO: ${champion.toUpperCase()}");
      buffer.writeln("---------------------------\n");
    }

    buffer.writeln("FASE FINAL (MATA-MATA)");
    int? lastRound;
    for (var m in knockoutMatches) {
      if (m.round != lastRound) {
        lastRound = m.round;
        buffer.writeln("\n${_getPhaseName(m.round).toUpperCase()}:");
      }
      buffer.writeln(
        "${m.homeTeam.name} ${m.homeScore} x ${m.awayScore} ${m.awayTeam.name}",
      );
    }

    buffer.writeln("\nGerado por Hexagon CUP -https://hexagonsports.com.br/");

    Clipboard.setData(ClipboardData(text: buffer.toString()));
  }

  List<Widget> _buildKnockoutSections(
    BuildContext context,
    List<Match> knockoutMatches,
  ) {
    final widgets = <Widget>[];
    int? lastRound;

    for (final match in knockoutMatches) {
      if (match.round != lastRound) {
        lastRound = match.round;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: _SectionLabel(
              label: _getPhaseName(match.round),
              icon: _getPhaseIcon(match.round),
              color: _getPhaseColor(match.round),
            ),
          ),
        );
      }
      widgets.add(
        _MatchCard(
          match: match,
          isKnockout: true,
          onTap: () => _showEditScoreDialog(context, match),
        ),
      );
    }

    return widgets;
  }

  String _getPhaseName(int round) {
    if (round == 100) return 'Grande Final';
    if (round == 50) return 'Semifinal';
    if (round == 10) return 'Quartas de Final';
    if (round == 5) return 'Oitavas de Final';
    if (round == 3) return 'Rodada de 32';
    if (round == 1) return 'Preliminar';
    return 'Mata-Mata';
  }

  IconData _getPhaseIcon(int round) {
    if (round == 100) return Icons.emoji_events;
    if (round == 50) return Icons.sports_score;
    if (round == 10) return Icons.stadium;
    return Icons.sports_soccer;
  }

  Color _getPhaseColor(int round) {
    if (round == 100) return HexColors.warning;
    if (round == 50) return HexColors.danger;
    if (round == 10) return HexColors.primary;
    return HexColors.textSubtle;
  }

  String? _getChampionName(List<Match> matches) {
    try {
      final finalMatch = matches.firstWhere(
        (m) => m.round == 100,
        orElse: () => throw Exception(),
      );

      if (finalMatch.status == MatchStatus.finished &&
          finalMatch.winnerId != null) {
        final winnerTeam = finalMatch.winnerId == finalMatch.homeTeam.id
            ? finalMatch.homeTeam
            : finalMatch.awayTeam;
        return winnerTeam.name;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  List<Team> _getTeamsFromMatches(List<Match> matches) {
    final teams = <String, Team>{};
    for (var m in matches) {
      teams[m.homeTeam.id] = m.homeTeam;
      teams[m.awayTeam.id] = m.awayTeam;
    }
    return teams.values.toList();
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _showStartKnockoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HexColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: HexColors.border),
        ),
        title: const Text(
          'Iniciar Mata-Mata',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Deseja encerrar a fase de grupos e iniciar o mata-mata?\n\nOs 2 primeiros de cada grupo serão classificados.',
          style: TextStyle(color: HexColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: HexColors.textSubtle),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text('Gerando mata-mata...'),
                    ],
                  ),
                  backgroundColor: HexColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );

              final matchesStream = sl<TournamentRepository>()
                  .watchTournamentMatches(tournamentId);
              matchesStream.first
                  .then((matchList) {
                    final allTeams = _getTeamsFromMatches(matchList);
                    context.read<TournamentCubit>().startKnockoutStage(
                      tournamentId,
                      matchList,
                      allTeams,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Mata-mata criado com sucesso! ⚔️'),
                          ],
                        ),
                        backgroundColor: HexColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  })
                  .catchError((Object error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro: $error'),
                        backgroundColor: HexColors.danger,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  });
            },
            child: const Text('Iniciar ⚔️'),
          ),
        ],
      ),
    );
  }

  void _showEditScoreDialog(BuildContext context, Match match) {
    final homeCtrl = TextEditingController(text: match.homeScore.toString());
    final awayCtrl = TextEditingController(text: match.awayScore.toString());
    String? penaltyWinnerId;
    final isKnockout = match.groupName == null;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: HexColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: HexColors.border),
          ),
          title: Text(
            isKnockout ? 'Resultado Mata-Mata' : 'Resultado da Partida',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          match.homeTeam.name,
                          style: const TextStyle(
                            color: HexColors.textSubtle,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: homeCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: HexColors.textPrimary,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '×',
                      style: TextStyle(
                        fontSize: 24,
                        color: HexColors.textSubtle,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          match.awayTeam.name,
                          style: const TextStyle(
                            color: HexColors.textSubtle,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: awayCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: HexColors.textPrimary,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (isKnockout && homeCtrl.text == awayCtrl.text) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: HexColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: HexColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quem avançou nos pênaltis?',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: HexColors.warning,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _PenaltyOption(
                        team: match.homeTeam,
                        isSelected: penaltyWinnerId == match.homeTeam.id,
                        onTap: () =>
                            setState(() => penaltyWinnerId = match.homeTeam.id),
                      ),
                      const SizedBox(height: 6),
                      _PenaltyOption(
                        team: match.awayTeam,
                        isSelected: penaltyWinnerId == match.awayTeam.id,
                        onTap: () =>
                            setState(() => penaltyWinnerId = match.awayTeam.id),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: HexColors.textSubtle),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final homeError = Match.validateScoreText(homeCtrl.text);
                if (homeError != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(homeError),
                      backgroundColor: HexColors.danger,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                  return;
                }
                final awayError = Match.validateScoreText(awayCtrl.text);
                if (awayError != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(awayError),
                      backgroundColor: HexColors.danger,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                  return;
                }

                final hScore = int.parse(homeCtrl.text);
                final aScore = int.parse(awayCtrl.text);

                String? finalWinnerId;
                if (hScore > aScore) {
                  finalWinnerId = match.homeTeam.id;
                } else if (aScore > hScore) {
                  finalWinnerId = match.awayTeam.id;
                } else {
                  finalWinnerId = penaltyWinnerId;
                }

                if (isKnockout && finalWinnerId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Selecione o vencedor dos pênaltis!'),
                      backgroundColor: HexColors.warning,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                  return;
                }

                final ok = await context
                    .read<TournamentCubit>()
                    .updateMatchResult(
                      tournamentId: tournamentId,
                      match: match,
                      homeScore: hScore,
                      awayScore: aScore,
                      winnerId: finalWinnerId,
                    );
                if (!context.mounted) return;
                if (ok) {
                  Navigator.pop(ctx);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Erro ao salvar placar.'),
                      backgroundColor: HexColors.danger,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tabela de Classificação do Grupo ─────────────────────────────────────────

class _GroupTable extends StatelessWidget {
  final String groupName;
  final List<TeamStats> standings;
  const _GroupTable({required this.groupName, required this.standings});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: HexColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: HexColors.primary.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: HexColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [HexColors.primary, HexColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      groupName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Grupo $groupName',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: HexColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: const [
                SizedBox(
                  width: 24,
                  child: Text(
                    '#',
                    style: TextStyle(
                      color: HexColors.textSubtle,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Time',
                    style: TextStyle(
                      color: HexColors.textSubtle,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _TableHeader('P'),
                _TableHeader('J'),
                _TableHeader('V'),
                _TableHeader('E'),
                _TableHeader('D'),
                _TableHeader('SG'),
              ],
            ),
          ),

          ...standings.asMap().entries.map((entry) {
            final pos = entry.key + 1;
            final s = entry.value;
            final isClassified = pos <= 2;
            return Container(
              decoration: BoxDecoration(
                color: isClassified
                    ? HexColors.success.withValues(alpha: 0.06)
                    : null,
                border: const Border(
                  top: BorderSide(color: HexColors.border, width: 0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        '$pos',
                        style: TextStyle(
                          color: isClassified
                              ? HexColors.success
                              : HexColors.textSubtle,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: HexColors.cardHighlight,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                s.team.name.isNotEmpty
                                    ? s.team.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: HexColors.primary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              s.team.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: HexColors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _TableCell(
                      '${s.points}',
                      bold: true,
                      color: HexColors.primary,
                    ),
                    _TableCell('${s.wins + s.draws + s.losses}'),
                    _TableCell('${s.wins}', color: HexColors.success),
                    _TableCell('${s.draws}', color: HexColors.warning),
                    _TableCell('${s.losses}', color: HexColors.danger),
                    _TableCell(
                      '${s.goalDifference > 0 ? '+' : ''}${s.goalDifference}',
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: HexColors.textSubtle,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final bool bold;
  final Color? color;
  const _TableCell(this.text, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color ?? HexColors.textMuted,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ── Card de Partida ───────────────────────────────────────────────────────────

class _MatchCard extends StatelessWidget {
  final Match match;
  final VoidCallback onTap;
  final bool isKnockout;
  const _MatchCard({
    required this.match,
    required this.onTap,
    this.isKnockout = false,
  });

  @override
  Widget build(BuildContext context) {
    final isFinished = match.status == MatchStatus.finished;
    final homeWon = isFinished && match.winnerId == match.homeTeam.id;
    final awayWon = isFinished && match.winnerId == match.awayTeam.id;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isFinished
                ? Colors.white.withValues(alpha: 0.08)
                : HexColors.primary.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            if (isKnockout && isFinished)
              BoxShadow(
                color: HexColors.primary.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: HexColors.surface.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                match.homeTeam.name,
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: homeWon
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: homeWon
                                      ? HexColors.textPrimary
                                      : HexColors.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                              if (homeWon)
                                const Text(
                                  'VENCEDOR',
                                  style: TextStyle(
                                    color: HexColors.success,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        _TeamAvatar(
                          name: match.homeTeam.name,
                          isWinner: homeWon,
                        ),
                      ],
                    ),
                  ),

                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isFinished
                          ? HexColors.cardHighlight
                          : HexColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isFinished
                            ? HexColors.primary.withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Text(
                      isFinished
                          ? '${match.homeScore} × ${match.awayScore}'
                          : '- × -',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: isFinished
                            ? HexColors.textPrimary
                            : HexColors.textSubtle,
                      ),
                    ),
                  ),

                  Expanded(
                    child: Row(
                      children: [
                        _TeamAvatar(
                          name: match.awayTeam.name,
                          isWinner: awayWon,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                match.awayTeam.name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: awayWon
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: awayWon
                                      ? HexColors.textPrimary
                                      : HexColors.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                              if (awayWon)
                                const Text(
                                  'VENCEDOR',
                                  style: TextStyle(
                                    color: HexColors.success,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color:
                          (isFinished
                                  ? HexColors.textSubtle
                                  : HexColors.primary)
                              .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isFinished
                          ? Icons.edit_outlined
                          : Icons.add_circle_outline,
                      color: isFinished
                          ? HexColors.textSubtle
                          : HexColors.primary,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Avatar de Time ────────────────────────────────────────────────────────────

class _TeamAvatar extends StatelessWidget {
  final String name;
  final bool isWinner;
  const _TeamAvatar({required this.name, this.isWinner = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isWinner
              ? [HexColors.primary, HexColors.primaryDark]
              : [HexColors.surfaceElevated, HexColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isWinner
              ? HexColors.primary.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.1),
          width: 1.5,
        ),
        boxShadow: isWinner
            ? [
                BoxShadow(
                  color: HexColors.primary.withValues(alpha: 0.25),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: isWinner ? Colors.white : HexColors.textSubtle,
          ),
        ),
      ),
    );
  }
}

// ── Banner de Campeão ─────────────────────────────────────────────────────────

class _ChampionBanner extends StatelessWidget {
  final String name;
  const _ChampionBanner({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: HexColors.warning.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: HexColors.warning.withValues(alpha: 0.15),
            blurRadius: 32,
            spreadRadius: -4,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  HexColors.warning.withValues(alpha: 0.15),
                  HexColors.primary.withValues(alpha: 0.08),
                  HexColors.surface.withValues(alpha: 0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        HexColors.warning.withValues(alpha: 0.25),
                        Colors.transparent,
                      ],
                      radius: 0.8,
                    ),
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: HexColors.warning,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'CAMPEÃO',
                  style: TextStyle(
                    color: HexColors.warning,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: HexColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Label de Seção ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _SectionLabel({
    required this.label,
    required this.icon,
    this.color = HexColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Opção de pênalti ──────────────────────────────────────────────────────────

class _PenaltyOption extends StatelessWidget {
  final Team team;
  final bool isSelected;
  final VoidCallback onTap;
  const _PenaltyOption({
    required this.team,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? HexColors.primary.withValues(alpha: 0.15)
              : HexColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? HexColors.primary : HexColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? HexColors.primary : HexColors.textSubtle,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              team.name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? HexColors.primary : HexColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
