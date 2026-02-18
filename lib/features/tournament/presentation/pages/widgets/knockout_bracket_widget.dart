import 'package:admissao_app/core/styles/app_theme.dart';
import 'package:flutter/material.dart';
import '../../../domain/entities/match.dart';

/// Bracket visual de mata-mata: Quartas → Semi → Final → 🏆
///
/// Scroll horizontal, sem zoom. Toque em um jogo para editar placar.
class KnockoutBracketWidget extends StatelessWidget {
  const KnockoutBracketWidget({
    super.key,
    required this.knockoutMatches,
    required this.onMatchTap,
  });

  final List<Match> knockoutMatches;
  final void Function(Match match) onMatchTap;

  // ── Dimensões ────────────────────────────────────────────────────────────
  static const cardW = 140.0;
  static const cardH = 76.0;
  static const connW = 40.0;
  static const colW = cardW + connW;
  static const trophyW = 90.0;

  @override
  Widget build(BuildContext context) {
    if (knockoutMatches.isEmpty) return const SizedBox.shrink();

    final rounds = <int, List<Match>>{};
    for (final m in knockoutMatches) {
      rounds.putIfAbsent(m.round, () => []).add(m);
    }
    final sortedRounds = rounds.keys.toList()..sort();

    const double matchCardH = 80;
    const double matchCardW = 150;
    const double connectorW = 32;
    const double columnW = matchCardW + connectorW;

    final totalColumns = sortedRounds.length + 1;
    final maxMatchesInFirstRound = sortedRounds.isNotEmpty
        ? (rounds[sortedRounds.first]?.length ?? 1)
        : 1;

    final totalH = maxMatchesInFirstRound * matchCardH * 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              ...sortedRounds.map(
                (round) => SizedBox(
                  width: columnW,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getPhaseColor(round).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getPhaseColor(round).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        _getPhaseName(round),
                        style: TextStyle(
                          color: _getPhaseColor(round),
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: columnW - connectorW + 20,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: HexColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: HexColors.warning.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Text(
                      'CAMPEÃO',
                      style: TextStyle(
                        color: HexColors.warning,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: SizedBox(
            width: totalColumns * columnW + 20,
            height: totalH,
            child: CustomPaint(
              painter: _BracketLinePainter(
                rounds: rounds,
                sortedRounds: sortedRounds,
                matchCardH: matchCardH,
                matchCardW: matchCardW,
                connectorW: connectorW,
                totalH: totalH,
              ),
              child: Stack(
                children: _buildMatchCards(
                  rounds: rounds,
                  sortedRounds: sortedRounds,
                  matchCardH: matchCardH,
                  matchCardW: matchCardW,
                  connectorW: connectorW,
                  totalH: totalH,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMatchCards({
    required Map<int, List<Match>> rounds,
    required List<int> sortedRounds,
    required double matchCardH,
    required double matchCardW,
    required double connectorW,
    required double totalH,
  }) {
    final widgets = <Widget>[];

    for (int col = 0; col < sortedRounds.length; col++) {
      final round = sortedRounds[col];
      final matchesInRound = rounds[round]!;
      final count = matchesInRound.length;

      final sectionH = totalH / count;

      for (int row = 0; row < count; row++) {
        final match = matchesInRound[row];
        final top = sectionH * row + (sectionH - matchCardH) / 2;
        final left = col * (matchCardW + connectorW);

        widgets.add(
          Positioned(
            left: left,
            top: top,
            width: matchCardW,
            height: matchCardH,
            child: _BracketMatchCard(
              match: match,
              onTap: () => onMatchTap(match),
            ),
          ),
        );
      }
    }

    final finalRound = sortedRounds.last;
    final finalMatch = rounds[finalRound]!.first;
    final trophyLeft = sortedRounds.length * (matchCardW + connectorW);
    final trophyTop = totalH / 2 - 30;

    final champion = _getChampion(finalMatch);

    widgets.add(
      Positioned(
        left: trophyLeft,
        top: trophyTop,
        width: matchCardW,
        height: 60,
        child: Container(
          decoration: BoxDecoration(
            gradient: champion != null
                ? LinearGradient(
                    colors: [
                      HexColors.warning.withValues(alpha: 0.2),
                      HexColors.primary.withValues(alpha: 0.1),
                    ],
                  )
                : null,
            color: champion == null ? HexColors.surfaceElevated : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: champion != null
                  ? HexColors.warning.withValues(alpha: 0.5)
                  : HexColors.border,
              width: champion != null ? 2 : 1,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.emoji_events,
                  color: champion != null
                      ? HexColors.warning
                      : HexColors.textSubtle,
                  size: 20,
                ),
                const SizedBox(height: 2),
                Text(
                  champion ?? '???',
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: champion != null
                        ? HexColors.warning
                        : HexColors.textSubtle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return widgets;
  }

  String? _getChampion(Match finalMatch) {
    if (finalMatch.status != MatchStatus.finished) return null;
    if (finalMatch.winnerId == finalMatch.homeTeam.id) {
      return finalMatch.homeTeam.name;
    }
    if (finalMatch.winnerId == finalMatch.awayTeam.id) {
      return finalMatch.awayTeam.name;
    }
    return null;
  }

  String _getPhaseName(int round) {
    if (round == 100) return 'FINAL';
    if (round == 50) return 'SEMI';
    if (round == 10) return 'QUARTAS';
    return 'RODADA';
  }

  Color _getPhaseColor(int round) {
    if (round == 100) return HexColors.danger;
    if (round == 50) return HexColors.primary;
    return HexColors.primary;
  }
}

// ── Card de partida no bracket ──────────────────────────────────────────────

class _BracketMatchCard extends StatelessWidget {
  final Match match;
  final VoidCallback onTap;

  const _BracketMatchCard({required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isFinished = match.status == MatchStatus.finished;
    final isWaiting =
        match.homeTeam.id == 'waiting' || match.awayTeam.id == 'waiting';
    final homeWon = isFinished && match.winnerId == match.homeTeam.id;
    final awayWon = isFinished && match.winnerId == match.awayTeam.id;

    return GestureDetector(
      onTap: isWaiting ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: HexColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isFinished
                ? HexColors.success.withValues(alpha: 0.5)
                : HexColors.border,
            width: isFinished ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BracketTeamRow(
              name: match.homeTeam.name,
              score: isFinished ? match.homeScore : null,
              isWinner: homeWon,
              isWaiting: match.homeTeam.id == 'waiting',
              isTop: true,
            ),
            Container(height: 1, color: HexColors.border),
            _BracketTeamRow(
              name: match.awayTeam.name,
              score: isFinished ? match.awayScore : null,
              isWinner: awayWon,
              isWaiting: match.awayTeam.id == 'waiting',
              isTop: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _BracketTeamRow extends StatelessWidget {
  final String name;
  final int? score;
  final bool isWinner;
  final bool isWaiting;
  final bool isTop;

  const _BracketTeamRow({
    required this.name,
    this.score,
    this.isWinner = false,
    this.isWaiting = false,
    this.isTop = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isWinner
            ? HexColors.success.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.vertical(
          top: isTop ? const Radius.circular(9) : Radius.zero,
          bottom: !isTop ? const Radius.circular(9) : Radius.zero,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              color: isWinner ? HexColors.success : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              isWaiting ? 'Aguardando...' : name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: isWinner ? FontWeight.w800 : FontWeight.w600,
                fontSize: 11,
                color: isWaiting
                    ? HexColors.textSubtle
                    : isWinner
                    ? HexColors.textPrimary
                    : HexColors.textMuted,
              ),
            ),
          ),
          if (score != null)
            Container(
              width: 24,
              height: 22,
              decoration: BoxDecoration(
                color: isWinner
                    ? HexColors.success.withValues(alpha: 0.2)
                    : HexColors.cardHighlight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '$score',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: isWinner ? HexColors.success : HexColors.textSubtle,
                  ),
                ),
              ),
            ),
          if (score == null && !isWaiting)
            Container(
              width: 24,
              height: 22,
              decoration: BoxDecoration(
                color: HexColors.cardHighlight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Text(
                  '-',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: HexColors.textSubtle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── CustomPainter para as linhas conectoras do bracket ───────────────────────

class _BracketLinePainter extends CustomPainter {
  final Map<int, List<Match>> rounds;
  final List<int> sortedRounds;
  final double matchCardH;
  final double matchCardW;
  final double connectorW;
  final double totalH;

  _BracketLinePainter({
    required this.rounds,
    required this.sortedRounds,
    required this.matchCardH,
    required this.matchCardW,
    required this.connectorW,
    required this.totalH,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = HexColors.border
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final paintHighlight = Paint()
      ..color = HexColors.primary.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int col = 0; col < sortedRounds.length; col++) {
      final round = sortedRounds[col];
      final matchesInRound = rounds[round]!;
      final count = matchesInRound.length;
      final sectionH = totalH / count;

      for (int row = 0; row < count; row++) {
        final match = matchesInRound[row];
        final centerY = sectionH * row + sectionH / 2;
        final rightX = col * (matchCardW + connectorW) + matchCardW;

        final isFinished = match.status == MatchStatus.finished;
        final usePaint = isFinished ? paintHighlight : paint;

        canvas.drawLine(
          Offset(rightX, centerY),
          Offset(rightX + connectorW / 2, centerY),
          usePaint,
        );

        if (col < sortedRounds.length - 1) {
          final nextRound = sortedRounds[col + 1];
          final nextCount = rounds[nextRound]!.length;
          final nextSectionH = totalH / nextCount;

          final nextRow = row ~/ 2;
          final nextCenterY = nextSectionH * nextRow + nextSectionH / 2;

          final midX = rightX + connectorW / 2;

          canvas.drawLine(
            Offset(midX, centerY),
            Offset(midX, nextCenterY),
            usePaint,
          );

          if (row % 2 == 1 || count == 1) {
            canvas.drawLine(
              Offset(midX, nextCenterY),
              Offset(rightX + connectorW, nextCenterY),
              usePaint,
            );
          } else if (row % 2 == 0 && row + 1 < count) {
            canvas.drawLine(
              Offset(midX, nextCenterY),
              Offset(rightX + connectorW, nextCenterY),
              usePaint,
            );
          }
        }

        if (col == sortedRounds.length - 1) {
          final trophyX = sortedRounds.length * (matchCardW + connectorW);
          final trophyCenterY = totalH / 2;
          canvas.drawLine(
            Offset(rightX + connectorW / 2, centerY),
            Offset(rightX + connectorW / 2, trophyCenterY),
            usePaint,
          );
          canvas.drawLine(
            Offset(rightX + connectorW / 2, trophyCenterY),
            Offset(trophyX, trophyCenterY),
            usePaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
