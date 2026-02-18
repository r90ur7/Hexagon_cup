import 'package:admissao_app/features/tournament/domain/entities/match.dart';
import 'package:admissao_app/features/tournament/data/models/team_model.dart';

class MatchModel extends Match {
  const MatchModel({
    required super.id,
    required super.homeTeam,
    required super.awayTeam,
    required super.round,
    super.homeScore,
    super.awayScore,
    super.status,
    super.groupId,
    super.groupName,
    super.nextMatchId,
    super.positionInNextMatch,
    super.winnerId,
  });

  factory MatchModel.fromFirestore(Map<String, dynamic> json, String id) {
    final homeData = json['homeTeam'] as Map<String, dynamic>;
    final awayData = json['awayTeam'] as Map<String, dynamic>;

    return MatchModel(
      id: id,
      homeTeam: TeamModel.fromFirestore(
        homeData,
        (homeData['id'] as String?) ?? 'unknown',
      ),
      awayTeam: TeamModel.fromFirestore(
        awayData,
        (awayData['id'] as String?) ?? 'unknown',
      ),
      homeScore: (json['homeScore'] as int?) ?? 0,
      awayScore: (json['awayScore'] as int?) ?? 0,
      status: MatchStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MatchStatus.scheduled,
      ),
      groupId: json['groupId'] as String?,
      groupName: json['groupName'] as String?,
      nextMatchId: json['nextMatchId'] as String?,
      positionInNextMatch: json['positionInNextMatch'] as String?,
      winnerId: json['winnerId'] as String?,
      round: json['round'] as int,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'homeTeam': (homeTeam as TeamModel).toFirestore()..['id'] = homeTeam.id,
      'awayTeam': (awayTeam as TeamModel).toFirestore()..['id'] = awayTeam.id,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'status': status.name,
      'groupId': groupId,
      'winnerId': winnerId,
      'groupName': groupName,
      'round': round,
      'nextMatchId': nextMatchId,
      'positionInNextMatch': positionInNextMatch,
    };
  }
}
