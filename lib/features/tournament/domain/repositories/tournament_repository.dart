import 'package:admissao_app/features/tournament/domain/entities/tournament.dart';
import 'package:admissao_app/features/tournament/domain/entities/team.dart';
import 'package:admissao_app/features/tournament/domain/entities/match.dart';

abstract class TournamentRepository {
  Future<List<Team>> getAllTeams();
  Future<void> createTournament(Tournament tournament);
  Future<void> updateMatchResult(
    String tournamentId,
    Match match,
    int homeScore,
    int awayScore, {
    String? winnerId,
  });
  Future<void> saveTeam(Team team);
  Future<void> deleteTeam(String teamId);
  Future<List<Team>> getTeams();
  Future<void> saveTournamentMatches(String tournamentId, List<Match> matches);
  Future<void> replaceKnockoutMatches(String tournamentId, List<Match> matches);
  Future<List<Tournament>> getAllTournaments();
  Future<void> deleteTournament(String tournamentId);
  Future<void> updateTournamentStatus(
    String tournamentId,
    TournamentStatus status,
  );
  Future<void> renameTournament(String tournamentId, String newName);
  Future<void> updateTournamentTeams(String tournamentId, List<Team> teams);
  Future<bool> tournamentHasKnockoutMatches(String tournamentId);
  Stream<List<Match>> watchTournamentMatches(String tournamentId);
  Stream<List<Tournament>> watchTournaments();
}
