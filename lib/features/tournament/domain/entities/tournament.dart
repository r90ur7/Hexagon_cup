import 'package:equatable/equatable.dart';
import 'package:admissao_app/features/tournament/domain/entities/team.dart';

enum TournamentFormat { groupAndKnockout, directKnockout }

extension TournamentFormatLabel on TournamentFormat {
  String get label {
    switch (this) {
      case TournamentFormat.groupAndKnockout:
        return 'Grupos e Mata-Mata';
      case TournamentFormat.directKnockout:
        return 'Mata-Mata Direto';
    }
  }
}

/// Status de uma copa — persistido no Firestore e calculável a partir dos dados.
enum TournamentStatus {
  /// Recém-criada, primeira fase ainda em andamento, criada há ≤ 1 dia.
  started,

  /// Já está rolando: mais de 1 dia ou times em fases diferentes.
  ongoing,

  /// Campeão definido.
  finished,
}

extension TournamentStatusLabel on TournamentStatus {
  String get label {
    switch (this) {
      case TournamentStatus.started:
        return 'Iniciada';
      case TournamentStatus.ongoing:
        return 'Em andamento';
      case TournamentStatus.finished:
        return 'Finalizada';
    }
  }

  /// Cor temática do status.
  String get colorHex {
    switch (this) {
      case TournamentStatus.started:
        return '#2196F3'; // azul
      case TournamentStatus.ongoing:
        return '#FF9800'; // laranja
      case TournamentStatus.finished:
        return '#4CAF50'; // verde
    }
  }
}

class Tournament extends Equatable {
  const Tournament({
    required this.id,
    required this.name,
    required this.teams,
    required this.format,
    this.status = TournamentStatus.started,
    this.championId,
    this.createdAt,
  });
  final String id;
  final String name;
  final List<Team> teams;
  final TournamentFormat format;
  final TournamentStatus status;
  final String? championId;
  final DateTime? createdAt;

  /// Atalho de compatibilidade.
  bool get isCompleted => status == TournamentStatus.finished;

  /// Status efetivo: leva em conta a idade do torneio.
  /// Se status é [started] mas criado há mais de 1 dia, vira [ongoing].
  TournamentStatus get effectiveStatus {
    if (status == TournamentStatus.finished) return TournamentStatus.finished;
    if (status == TournamentStatus.ongoing) return TournamentStatus.ongoing;
    // status é 'started' — verifica idade
    if (createdAt != null &&
        DateTime.now().difference(createdAt!).inDays >= 1) {
      return TournamentStatus.ongoing;
    }
    return TournamentStatus.started;
  }

  @override
  List<Object?> get props => [
    id,
    name,
    teams,
    format,
    status,
    championId,
    createdAt,
  ];
}
