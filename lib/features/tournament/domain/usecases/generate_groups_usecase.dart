import 'package:admissao_app/features/tournament/data/models/match_model.dart';
import 'package:uuid/uuid.dart';
import '../entities/team.dart';
import '../entities/group.dart';
import '../entities/match.dart';

class GenerateGroupsUseCase {
  /// Divide os times em grupos de 4 e gera as partidas iniciais.
  /// Se [manualGroups] for informado, usa a distribuição manual (mapa grupo -> lista de IDs).
  /// Caso contrário, distribui automaticamente (shuffle).
  Map<String, dynamic> call(
    List<Team> teams, {
    Map<String, List<String>>? manualGroups,
  }) {
    final List<Group> groups = [];
    final List<Match> allMatches = [];
    final int numberOfGroups = teams.length ~/ 4;

    if (manualGroups != null && manualGroups.isNotEmpty) {
      // Arranjo manual: usa a ordem definida pelo usuário
      final sortedGroupNames = manualGroups.keys.toList()..sort();
      for (final groupName in sortedGroupNames) {
        final teamIds = manualGroups[groupName]!;
        final groupTeams = teamIds
            .map((id) => teams.firstWhere((t) => t.id == id))
            .toList();

        groups.add(
          Group(id: const Uuid().v4(), name: groupName, teams: groupTeams),
        );

        // Gerar partidas do grupo (Todos contra todos)
        for (int j = 0; j < groupTeams.length; j++) {
          for (int k = j + 1; k < groupTeams.length; k++) {
            allMatches.add(
              MatchModel(
                id: const Uuid().v4(),
                homeTeam: groupTeams[j],
                awayTeam: groupTeams[k],
                homeScore: 0,
                awayScore: 0,
                round: 1,
                status: MatchStatus.scheduled,
                groupName: groupName,
              ),
            );
          }
        }
      }
    } else {
      // Arranjo automático: shuffle
      final shuffledTeams = List<Team>.from(teams)..shuffle();

      for (int i = 0; i < numberOfGroups; i++) {
        final groupName = String.fromCharCode(65 + i); // A, B, C...
        final groupTeams = shuffledTeams.sublist(i * 4, (i * 4) + 4);

        groups.add(
          Group(id: const Uuid().v4(), name: groupName, teams: groupTeams),
        );

        for (int j = 0; j < groupTeams.length; j++) {
          for (int k = j + 1; k < groupTeams.length; k++) {
            allMatches.add(
              MatchModel(
                id: const Uuid().v4(),
                homeTeam: groupTeams[j],
                awayTeam: groupTeams[k],
                homeScore: 0,
                awayScore: 0,
                round: 1,
                status: MatchStatus.scheduled,
                groupName: groupName,
              ),
            );
          }
        }
      }
    }

    return {'groups': groups, 'matches': allMatches};
  }
}
