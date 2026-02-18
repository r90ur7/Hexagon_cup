import 'package:admissao_app/features/tournament/data/models/tournament_model.dart';
import 'package:admissao_app/features/tournament/domain/usecases/calculate_standings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'tournament_state.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/match.dart';
import '../../domain/repositories/tournament_repository.dart';
import '../../domain/usecases/generate_groups_usecase.dart';
import '../../domain/usecases/generate_knockout_bracket.dart';

class TournamentCubit extends Cubit<TournamentState> {
  final TournamentRepository repository;
  final GenerateGroupsUseCase generateGroups;
  final GenerateKnockoutBracket generateKnockout;
  final CalculateStandingsUseCase calculateStandings;

  TournamentCubit({
    required this.repository,
    required this.generateGroups,
    required this.generateKnockout,
    required this.calculateStandings,
  }) : super(TournamentInitial());

  List<Team> _allTeamsFromDb = [];
  List<Team> get allTeamsFromDb => _allTeamsFromDb;
  List<Tournament> _tournaments = [];
  List<Tournament> get tournaments => _tournaments;
  // Getters para facilitar filtros na UI
  List<Tournament> get startedTournaments => _tournaments
      .where((t) => t.effectiveStatus == TournamentStatus.started)
      .toList();
  List<Tournament> get ongoingTournaments => _tournaments
      .where((t) => t.effectiveStatus == TournamentStatus.ongoing)
      .toList();
  List<Tournament> get finishedTournaments => _tournaments
      .where((t) => t.effectiveStatus == TournamentStatus.finished)
      .toList();

  /// Tudo que não está finalizado (started + ongoing)
  List<Tournament> get activeTournaments => _tournaments
      .where((t) => t.effectiveStatus != TournamentStatus.finished)
      .toList();

  Future<void> deleteTournament(String tournamentId) async {
    emit(TournamentLoading());
    try {
      await repository.deleteTournament(tournamentId);
      await loadTournaments();
    } catch (e) {
      emit(TournamentError("Erro ao excluir copa: $e"));
    }
  }

  Future<void> addOrUpdateTeam({String? id, required String name}) async {
    emit(TournamentLoading());
    try {
      final team = Team(id: id ?? const Uuid().v4(), name: name);
      await repository.saveTeam(team);
      await fetchTeams();
    } catch (e) {
      emit(TournamentError("Erro ao salvar time: $e"));
    }
  }

  Future<void> removeTeam(String teamId) async {
    emit(TournamentLoading());
    try {
      await repository.deleteTeam(teamId);
      await fetchTeams();
    } catch (e) {
      emit(TournamentError("Erro ao excluir time"));
    }
  }

  Future<bool> updateMatchResult({
    required String tournamentId,
    required Match match,
    required int homeScore,
    required int awayScore,
    String? winnerId,
  }) async {
    final homeError = Match.validateScore(homeScore);
    if (homeError != null) {
      emit(TournamentError(homeError));
      return false;
    }
    final awayError = Match.validateScore(awayScore);
    if (awayError != null) {
      emit(TournamentError(awayError));
      return false;
    }

    emit(TournamentLoading());
    try {
      await repository
          .updateMatchResult(
            tournamentId,
            match,
            homeScore,
            awayScore,
            winnerId: winnerId,
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Timeout ao salvar placar. Verifique sua conexao.',
              );
            },
          );
      emit(TournamentSuccess(tournaments));
      return true;
    } catch (e) {
      emit(TournamentError('Erro ao salvar placar: $e'));
      return false;
    }
  }

  Future<void> fetchTeams() async {
    try {
      _allTeamsFromDb = await repository.getTeams();
      emit(TournamentSuccess(const []));
    } catch (e) {
      emit(TournamentError("Erro ao buscar times"));
    }
  }

  /// Cria uma nova copa do zero
  Future<void> createTournament({
    required String name,
    required List<Team> selectedTeams,
    required TournamentFormat format,
    Map<String, List<String>>? manualGroups,
    List<List<String>>? manualKnockoutMatchups,
  }) async {
    emit(TournamentLoading());

    try {
      if (selectedTeams.length < 4 || selectedTeams.length > 32) {
        throw Exception("Selecione entre 4 e 32 times.");
      }

      final tournamentId = const Uuid().v4();

      final tournament = TournamentModel(
        id: tournamentId,
        name: name,
        teams: selectedTeams,
        format: format,
        status: TournamentStatus.started,
        createdAt: DateTime.now(),
      );

      await repository
          .createTournament(tournament)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                "Timeout ao salvar no Firebase. Verifique sua conexão.",
              );
            },
          );

      if (format == TournamentFormat.groupAndKnockout) {
        final result = generateGroups(
          selectedTeams,
          manualGroups: manualGroups,
        );
        final List<Match> matches = result['matches'] as List<Match>;
        await repository.saveTournamentMatches(tournamentId, matches);
      } else if (format == TournamentFormat.directKnockout) {
        // Reordena os times pelos confrontos manuais se fornecido
        List<Team> orderedTeams;
        if (manualKnockoutMatchups != null) {
          orderedTeams = [];
          for (final pair in manualKnockoutMatchups) {
            for (final id in pair) {
              orderedTeams.add(selectedTeams.firstWhere((t) => t.id == id));
            }
          }
        } else {
          orderedTeams = List.from(selectedTeams)..shuffle();
        }
        final knockoutMatches = generateKnockout(
          tournamentId: tournamentId,
          qualifiedTeams: orderedTeams,
        );
        await repository.saveTournamentMatches(tournamentId, knockoutMatches);
      }

      emit(TournamentCreated());
      await loadTournaments();
    } catch (e, stackTrace) {
      emit(TournamentError("Erro ao criar copa: $e"));
    }
  }

  Future<void> startKnockoutStage(
    String tournamentId,
    List<Match> groupMatches,
    List<Team> allTeams,
  ) async {
    emit(TournamentLoading());
    try {
      final qualified = <Team>[];
      final groupNames =
          groupMatches
              .map((m) => m.groupName)
              .whereType<String>()
              .toSet()
              .toList()
            ..sort();

      for (var g in groupNames) {
        if (g == null) continue;

        final groupMatchesList = groupMatches
            .where((m) => m.groupName == g)
            .toList();
        final teamsInGroup = allTeams
            .where(
              (t) => groupMatchesList.any(
                (m) => m.homeTeam.id == t.id || m.awayTeam.id == t.id,
              ),
            )
            .toList();

        final randomSeed = '${DateTime.now().microsecondsSinceEpoch}';
        final standings = calculateStandings.call(
          teamsInGroup,
          groupMatchesList,
          seed: randomSeed,
        );

        if (standings.length >= 2) {
          qualified.add(standings[0].team);
          qualified.add(standings[1].team);
        }
      }

      final knockoutMatches = generateKnockout(
        tournamentId: tournamentId,
        qualifiedTeams: qualified,
      );

      await repository.replaceKnockoutMatches(tournamentId, knockoutMatches);

      emit(TournamentSuccess(tournaments));
    } catch (e) {
      emit(TournamentError("Erro ao gerar mata-mata: $e"));
    }
  }

  Future<void> loadTournaments() async {
    emit(TournamentLoading());
    try {
      _tournaments = await repository.getAllTournaments();
      emit(TournamentSuccess(_tournaments));
    } catch (e) {
      emit(TournamentError("Erro ao carregar torneios: $e"));
    }
  }

  Future<void> renameTournament(String tournamentId, String newName) async {
    emit(TournamentLoading());
    try {
      await repository.renameTournament(tournamentId, newName);
      await loadTournaments();
    } catch (e) {
      emit(TournamentError("Erro ao renomear copa: $e"));
    }
  }

  Future<void> addTeamToTournament(String tournamentId, Team team) async {
    emit(TournamentLoading());
    try {
      final tournament = _tournaments.firstWhere((t) => t.id == tournamentId);
      final updatedTeams = [...tournament.teams, team];
      await repository.updateTournamentTeams(tournamentId, updatedTeams);
      await loadTournaments();
    } catch (e) {
      emit(TournamentError("Erro ao adicionar time: $e"));
    }
  }

  Future<void> removeTeamFromTournament(
    String tournamentId,
    String teamId,
  ) async {
    emit(TournamentLoading());
    try {
      final tournament = _tournaments.firstWhere((t) => t.id == tournamentId);
      final updatedTeams = tournament.teams
          .where((t) => t.id != teamId)
          .toList();
      await repository.updateTournamentTeams(tournamentId, updatedTeams);
      await loadTournaments();
    } catch (e) {
      emit(TournamentError("Erro ao remover time: $e"));
    }
  }
}
