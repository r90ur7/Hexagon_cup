import 'package:admissao_app/features/tournament/domain/entities/team.dart';

class TeamStats {
  TeamStats(this.team);
  final Team team;
  int wins = 0;
  int draws = 0;
  int losses = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;

  int get points => (wins * 3) + draws;
  int get goalDifference => goalsFor - goalsAgainst;
  int get gamesPlayed => wins + draws + losses;
}
