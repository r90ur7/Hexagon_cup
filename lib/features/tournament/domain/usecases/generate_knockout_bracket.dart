import 'package:uuid/uuid.dart';
import '../entities/match.dart';
import '../entities/team.dart';
import '../../data/models/match_model.dart';

/// Gera um bracket de mata-mata para **qualquer** número de times (2+).
///
/// Quando o total não é potência de 2, os primeiros times da lista
/// (mais bem classificados) recebem BYE e avançam direto para a próxima fase.
///
/// Round values:
///   100 = Final
///    50 = Semifinal
///    10 = Quartas de Final
///     5 = Oitavas de Final
///     3 = Rodada de 32
///     1 = Rodada preliminar / BYE round
class GenerateKnockoutBracket {
  static const _waitingTeam = Team(id: 'waiting', name: 'Aguardando...');
  static const _uuid = Uuid();

  List<Match> call({
    required String tournamentId,
    required List<Team> qualifiedTeams,
  }) {
    final int n = qualifiedTeams.length;
    if (n < 2) return [];

    final int bracketSize = _nextPowerOf2(n);
    final int totalRounds = _log2(bracketSize);
    final List<Team?> seeded = _seedTeams(qualifiedTeams, bracketSize);
    final allMatches = <MatchModel>[];

    final roundMatchIds = <List<String>>[];
    for (int r = 0; r < totalRounds; r++) {
      final matchCount = 1 << r;
      roundMatchIds.add(List.generate(matchCount, (_) => _uuid.v4()));
    }

    for (int r = 0; r < totalRounds; r++) {
      final roundValue = _getRoundValue(r, totalRounds);
      final ids = roundMatchIds[r];

      for (int i = 0; i < ids.length; i++) {
        String? nextMatchId;
        String? posInNext;
        if (r > 0) {
          nextMatchId = roundMatchIds[r - 1][i ~/ 2];
          posInNext = (i % 2 == 0) ? 'home' : 'away';
        }

        allMatches.add(
          MatchModel(
            id: ids[i],
            homeTeam: _waitingTeam,
            awayTeam: _waitingTeam,
            round: roundValue,
            nextMatchId: nextMatchId,
            positionInNextMatch: posInNext,
            status: MatchStatus.scheduled,
          ),
        );
      }
    }

    final firstRoundIdx = totalRounds - 1;
    final firstRoundIds = roundMatchIds[firstRoundIdx];
    final firstRoundMatches = allMatches
        .where((m) => firstRoundIds.contains(m.id))
        .toList();

    firstRoundMatches.sort(
      (a, b) =>
          firstRoundIds.indexOf(a.id).compareTo(firstRoundIds.indexOf(b.id)),
    );

    for (int i = 0; i < firstRoundMatches.length; i++) {
      final home = seeded[i * 2];
      final away = seeded[i * 2 + 1];
      final old = firstRoundMatches[i];

      final idx = allMatches.indexWhere((m) => m.id == old.id);

      if (home != null && away != null) {
        allMatches[idx] = MatchModel(
          id: old.id,
          homeTeam: home,
          awayTeam: away,
          round: old.round,
          nextMatchId: old.nextMatchId,
          positionInNextMatch: old.positionInNextMatch,
          status: MatchStatus.scheduled,
        );
      } else if (home != null && away == null) {
        allMatches[idx] = MatchModel(
          id: old.id,
          homeTeam: home,
          awayTeam: const Team(id: 'bye', name: 'BYE'),
          homeScore: 1,
          awayScore: 0,
          round: old.round,
          nextMatchId: old.nextMatchId,
          positionInNextMatch: old.positionInNextMatch,
          winnerId: home.id,
          status: MatchStatus.finished,
        );
        if (old.nextMatchId != null) {
          _propagateWinner(
            allMatches,
            old.nextMatchId!,
            old.positionInNextMatch,
            home,
          );
        }
      } else if (home == null && away != null) {
        allMatches[idx] = MatchModel(
          id: old.id,
          homeTeam: const Team(id: 'bye', name: 'BYE'),
          awayTeam: away,
          homeScore: 0,
          awayScore: 1,
          round: old.round,
          nextMatchId: old.nextMatchId,
          positionInNextMatch: old.positionInNextMatch,
          winnerId: away.id,
          status: MatchStatus.finished,
        );
        if (old.nextMatchId != null) {
          _propagateWinner(
            allMatches,
            old.nextMatchId!,
            old.positionInNextMatch,
            away,
          );
        }
      }
    }

    allMatches.removeWhere(
      (m) => m.homeTeam.id == 'bye' && m.awayTeam.id == 'bye',
    );

    return allMatches;
  }

  /// Propaga o vencedor de um BYE para a próxima partida
  void _propagateWinner(
    List<MatchModel> matches,
    String nextMatchId,
    String? position,
    Team winner,
  ) {
    final idx = matches.indexWhere((m) => m.id == nextMatchId);
    if (idx == -1) return;

    final next = matches[idx];
    matches[idx] = MatchModel(
      id: next.id,
      homeTeam: position == 'home' ? winner : next.homeTeam,
      awayTeam: position == 'away' ? winner : next.awayTeam,
      round: next.round,
      nextMatchId: next.nextMatchId,
      positionInNextMatch: next.positionInNextMatch,
      status: next.status,
    );
  }

  /// Distribui os times num bracket clássico de torneio.
  /// BYEs vão para os últimos slots, assim os cabeças de chave passam direto.
  /// Cruzamento: 1º do Grupo A vs 2º do Grupo B (estilo Copa do Mundo).
  List<Team?> _seedTeams(List<Team> teams, int bracketSize) {
    final slots = List<Team?>.filled(bracketSize, null);

    for (int i = 0; i < teams.length; i++) {
      slots[i] = teams[i];
    }

    return slots;
  }

  /// Próxima potência de 2 >= n
  int _nextPowerOf2(int n) {
    if (n <= 1) return 1;
    var p = 1;
    while (p < n) {
      p *= 2;
    }
    return p;
  }

  int _log2(int n) {
    var count = 0;
    var v = n;
    while (v > 1) {
      v ~/= 2;
      count++;
    }
    return count;
  }

  /// Mapeia o índice da rodada (0=final) para o valor de round.
  int _getRoundValue(int reverseIndex, int totalRounds) {
    switch (reverseIndex) {
      case 0:
        return 100; // Final
      case 1:
        return 50; // Semifinal
      case 2:
        return 10; // Quartas de Final
      case 3:
        return 5; // Oitavas de Final
      case 4:
        return 3; // Rodada de 32
      default:
        return 1; // Preliminar
    }
  }
}
