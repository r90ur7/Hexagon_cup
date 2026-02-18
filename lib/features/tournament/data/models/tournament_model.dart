import 'package:admissao_app/features/tournament/domain/entities/tournament.dart';
import 'package:admissao_app/features/tournament/data/models/team_model.dart';

class TournamentModel extends Tournament {
  const TournamentModel({
    required super.id,
    required super.name,
    required super.teams,
    required super.format,
    super.status,
    super.championId,
    super.createdAt,
  });

  factory TournamentModel.fromFirestore(Map<String, dynamic> json, String id) {
    // Compatibilidade: se existir isCompleted=true antigo, mapeia para finished
    final rawStatus = json['status'] as String?;
    final legacyCompleted = (json['isCompleted'] as bool?) ?? false;

    TournamentStatus status;
    if (rawStatus != null) {
      status = TournamentStatus.values.firstWhere(
        (e) => e.name == rawStatus,
        orElse: () => TournamentStatus.started,
      );
    } else if (json['championId'] != null || legacyCompleted) {
      // Copa legada com campeão ou flag antigo isCompleted
      status = TournamentStatus.finished;
    } else {
      // Copa legada sem campo status: se não tem campeão, é uma copa
      // antiga que já estava rolando (não faz sentido ser 'started').
      status = TournamentStatus.ongoing;
    }

    DateTime? createdAt;
    if (json['createdAt'] != null) {
      createdAt = DateTime.tryParse(json['createdAt'] as String);
    }

    return TournamentModel(
      id: id,
      name: (json['name'] as String?) ?? '',
      teams: (json['teams'] as List)
          .map(
            (t) => TeamModel.fromFirestore(
              t as Map<String, dynamic>,
              (t)['id'] as String,
            ),
          )
          .toList(),
      format: TournamentFormat.values.firstWhere(
        (e) => e.name == json['format'],
        orElse: () => TournamentFormat.directKnockout,
      ),
      status: status,
      championId: json['championId'] as String?,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'teams': teams.map((t) {
        if (t is TeamModel) {
          return t.toFirestore()..['id'] = t.id;
        }
        return TeamModel(id: t.id, name: t.name).toFirestore()..['id'] = t.id;
      }).toList(),
      'format': format.name,
      'status': status.name,
      'championId': championId,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }
}
