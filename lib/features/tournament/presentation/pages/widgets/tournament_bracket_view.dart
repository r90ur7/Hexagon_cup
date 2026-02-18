import 'package:flutter/material.dart';
import 'package:admissao_app/features/tournament/domain/entities/match.dart';

class TournamentBracketView extends StatelessWidget {
  final List<Match> matches;
  final String? championName;

  const TournamentBracketView({
    super.key,
    required this.matches,
    this.championName,
  });

  @override
  Widget build(BuildContext context) {
    final roundMap = <int, List<Match>>{};
    for (final m in matches) {
      roundMap.putIfAbsent(m.round, () => []).add(m);
    }
    final sortedRounds = roundMap.keys.toList()..sort();

    String phaseName(int round) {
      switch (round) {
        case 100:
          return 'FINAL';
        case 50:
          return 'SEMI';
        case 10:
          return 'QUARTAS';
        case 5:
          return 'OITAVAS';
        case 3:
          return 'R. DE 32';
        case 1:
          return 'PRELIM.';
        default:
          return 'FASE $round';
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final round in sortedRounds)
            _buildPhaseColumn(phaseName(round), roundMap[round]!),
          if (championName != null) _buildChampionColumn(championName!),
        ],
      ),
    );
  }

  Widget _buildPhaseColumn(String title, List<Match> phaseMatches) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          ...phaseMatches.map((m) => _MatchNode(match: m)).toList(),
        ],
      ),
    );
  }

  Widget _buildChampionColumn(String name) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.emoji_events, color: Colors.amber, size: 60),
        const SizedBox(height: 10),
        const Text("CAMPEÃO", style: TextStyle(fontWeight: FontWeight.bold)),
        Text(
          name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _MatchNode extends StatelessWidget {
  final Match match;
  const _MatchNode({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _TeamRow(
            name: match.homeTeam.name,
            score: match.homeScore,
            isWinner: match.winnerId == match.homeTeam.id,
          ),
          const Divider(height: 1, color: Colors.white10),
          _TeamRow(
            name: match.awayTeam.name,
            score: match.awayScore,
            isWinner: match.winnerId == match.awayTeam.id,
          ),
        ],
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  final String name;
  final int score;
  final bool isWinner;

  const _TeamRow({
    required this.name,
    required this.score,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                color: isWinner ? Colors.blue : Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            score.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isWinner ? Colors.blue : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
