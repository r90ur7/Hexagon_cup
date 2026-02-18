import 'package:equatable/equatable.dart';
import 'package:admissao_app/features/tournament/domain/entities/team.dart';

enum MatchStatus { scheduled, live, finished }

class Match extends Equatable {
  const Match({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    this.homeScore = 0,
    this.awayScore = 0,
    this.status = MatchStatus.scheduled,
    this.groupId,
    this.groupName,
    this.nextMatchId,
    this.positionInNextMatch,
    this.winnerId,
    required this.round,
  });
  final String id;
  final Team homeTeam;
  final Team awayTeam;
  final int homeScore;
  final int awayScore;
  final MatchStatus status;
  final String? groupId;
  final String? groupName;
  final String? nextMatchId;
  final String? winnerId;
  final String? positionInNextMatch;
  final int round;

  // Helper para facilitar a lógica de quem avançou
  Team? get winner {
    if (status != MatchStatus.finished) return null;
    if (homeScore > awayScore) return homeTeam;
    if (awayScore > homeScore) return awayTeam;
    return null; // Empate
  }

  static String? validateScoreText(String value, {int min = 0, int max = 99}) {
    if (value.trim().isEmpty) {
      return 'Preencha o placar.';
    }
    final parsed = int.tryParse(value);
    if (parsed == null) {
      return 'Placar invalido.';
    }
    return validateScore(parsed, min: min, max: max);
  }

  static String? validateScore(int value, {int min = 0, int max = 99}) {
    if (value < min || value > max) {
      return 'Placar deve estar entre $min e $max.';
    }
    return null;
  }

  @override
  List<Object?> get props => [
    id,
    homeTeam,
    awayTeam,
    homeScore,
    awayScore,
    status,
    groupId,
    groupName,
    nextMatchId,
    positionInNextMatch,
    winnerId,
    round,
  ];
}
