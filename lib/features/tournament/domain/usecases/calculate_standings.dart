import 'package:admissao_app/features/tournament/domain/entities/match.dart';
import 'package:admissao_app/features/tournament/domain/entities/team.dart';
import 'package:admissao_app/features/tournament/domain/entities/team_stats.dart';

class CalculateStandingsUseCase {
  List<TeamStats> call(List<Team> teams, List<Match> matches, {String? seed}) {
    // Inicializa os stats para cada time
    final statsMap = <String, TeamStats>{
      for (final team in teams) team.id: TeamStats(team),
    };

    for (final match in matches) {
      if (match.status != MatchStatus.finished) continue;

      final home = statsMap[match.homeTeam.id]!;
      final away = statsMap[match.awayTeam.id]!;

      home.goalsFor += match.homeScore;
      home.goalsAgainst += match.awayScore;
      away.goalsFor += match.awayScore;
      away.goalsAgainst += match.homeScore;
      if (match.homeScore > match.awayScore) {
        home.wins++;
        away.losses++;
      } else if (match.homeScore < match.awayScore) {
        away.wins++;
        home.losses++;
      } else {
        home.draws++;
        away.draws++;
      }
    }

    final seedKey = seed ?? 'default-seed';
    return statsMap.values.toList()..sort((a, b) {
      var cmp = b.points.compareTo(a.points);
      if (cmp == 0) cmp = b.wins.compareTo(a.wins);
      if (cmp == 0) cmp = b.goalDifference.compareTo(a.goalDifference);
      if (cmp == 0) cmp = b.goalsFor.compareTo(a.goalsFor);
      if (cmp == 0) {
        final aHash = _stableHash('$seedKey:${a.team.id}');
        final bHash = _stableHash('$seedKey:${b.team.id}');
        cmp = aHash.compareTo(bHash);
      }
      return cmp;
    });
  }

  int _stableHash(String input) {
    var hash = 0x811c9dc5;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }
}
