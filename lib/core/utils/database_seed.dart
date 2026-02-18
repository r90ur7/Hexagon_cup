import 'package:admissao_app/features/tournament/domain/entities/team.dart';
import 'package:admissao_app/features/tournament/domain/repositories/tournament_repository.dart';
import 'package:uuid/uuid.dart';

class DatabaseSeed {
  static Future<void> seedTeams(TournamentRepository repository) async {
    final existingTeams = await repository.getTeams();
    if (existingTeams.isNotEmpty) return;

    final List<String> initialTeams = [
      'Real Madrid',
      'Manchester City',
      'Bayern Munich',
      'Arsenal',
      'Barcelona',
      'PSG',
      'Inter Milan',
      'Borussia Dortmund',
      'Liverpool',
      'Bayer Leverkusen',
      'Juventus',
      'Milan',
      'Atletico Madrid',
      'Benfica',
      'Porto',
      'Sporting',
    ];

    for (var name in initialTeams) {
      final team = Team(id: const Uuid().v4(), name: name);
      await repository.saveTeam(team);
    }
  }
}
