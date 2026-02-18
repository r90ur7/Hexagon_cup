import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:admissao_app/features/tournament/domain/entities/match.dart';
import 'package:admissao_app/features/tournament/domain/entities/team.dart';
import 'package:admissao_app/features/tournament/domain/entities/tournament.dart';
import 'package:admissao_app/features/tournament/domain/repositories/tournament_repository.dart';
import 'package:admissao_app/features/tournament/data/models/match_model.dart';
import 'package:admissao_app/features/tournament/data/models/team_model.dart';
import 'package:admissao_app/features/tournament/data/models/tournament_model.dart';

class TournamentRepositoryImpl implements TournamentRepository {
  TournamentRepositoryImpl(this._firestore);
  final FirebaseFirestore _firestore;

  @override
  Future<void> updateMatchResult(
    String tournamentId,
    Match match,
    int hScore,
    int aScore, {
    String? winnerId,
  }) async {
    final batch = _firestore.batch();
    final tournamentRef = _firestore
        .collection('tournaments')
        .doc(tournamentId);
    batch.update(tournamentRef.collection('matches').doc(match.id), {
      'homeScore': hScore,
      'awayScore': aScore,
      'status': 'finished',
      'winnerId': winnerId,
    });

    if (match.nextMatchId != null &&
        winnerId != null &&
        match.positionInNextMatch != null) {
      final winnerTeam = winnerId == match.homeTeam.id
          ? match.homeTeam
          : match.awayTeam;
      final winnerModel = TeamModel(
        id: winnerTeam.id,
        name: winnerTeam.name,
        logoUrl: winnerTeam.logoUrl,
      );
      final nextMatchRef = tournamentRef
          .collection('matches')
          .doc(match.nextMatchId);

      batch.update(nextMatchRef, {
        '${match.positionInNextMatch}Team': {
          'id': winnerModel.id,
          ...winnerModel.toFirestore(),
        },
      });
    }

    if (match.round == 100) {
      batch.update(tournamentRef, {
        'status': 'finished',
        'championId': winnerId,
        'finishedAt': DateTime.now().toIso8601String(),
      });
    }

    await batch.commit();
  }

  @override
  Future<List<Tournament>> getAllTournaments() async {
    final snapshot = await _firestore.collection('tournaments').get();
    return snapshot.docs
        .map((doc) => TournamentModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<void> saveTeam(Team team) async {
    final model = TeamModel(
      id: team.id,
      name: team.name,
      logoUrl: team.logoUrl,
    );
    await _firestore.collection('teams').doc(team.id).set(model.toFirestore());
  }

  @override
  Future<void> saveTournamentMatches(
    String tournamentId,
    List<Match> matches,
  ) async {
    final batch = _firestore.batch();

    for (var match in matches) {
      final matchRef = _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('matches')
          .doc(match.id);

      batch.set(matchRef, {
        'id': match.id,
        'homeTeam': {
          'id': match.homeTeam.id,
          'name': match.homeTeam.name,
          'logoUrl': match.homeTeam.logoUrl,
        },
        'awayTeam': {
          'id': match.awayTeam.id,
          'name': match.awayTeam.name,
          'logoUrl': match.awayTeam.logoUrl,
        },
        'homeScore': match.homeScore,
        'awayScore': match.awayScore,
        'round': match.round,
        'groupName': match.groupName,
        'status': match.status.name,
        'nextMatchId': match.nextMatchId,
        'positionInNextMatch': match.positionInNextMatch,
      });
    }

    await batch.commit();
  }

  @override
  Future<List<Team>> getTeams() async {
    final snapshot = await _firestore.collection('teams').get();
    return snapshot.docs
        .map((doc) => TeamModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<List<Team>> getAllTeams() async {
    try {
      final snapshot = await _firestore.collection('teams').get();
      return snapshot.docs
          .map((doc) => TeamModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar times: $e');
    }
  }

  @override
  Future<void> createTournament(Tournament tournament) async {
    try {
      final model = tournament as TournamentModel;

      final data = model.toFirestore();
      await _firestore.collection('tournaments').doc(tournament.id).set(data);
    } catch (e, stackTrace) {
      throw Exception('Erro ao criar copa: $e');
    }
  }

  @override
  Stream<List<Match>> watchTournamentMatches(String tournamentId) {
    return _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('matches')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MatchModel.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  @override
  Future<void> deleteTournament(String tournamentId) async {
    final matchesRef = _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('matches');
    final matchesDocs = await matchesRef.get();
    final batch = _firestore.batch();
    for (var doc in matchesDocs.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_firestore.collection('tournaments').doc(tournamentId));
    await batch.commit();
  }

  @override
  Future<void> deleteTeam(String teamId) async {
    await _firestore.collection('teams').doc(teamId).delete();
  }

  @override
  Future<void> updateTournamentStatus(
    String tournamentId,
    TournamentStatus status,
  ) async {
    await _firestore.collection('tournaments').doc(tournamentId).update({
      'status': status.name,
    });
  }

  @override
  Future<void> renameTournament(String tournamentId, String newName) async {
    await _firestore.collection('tournaments').doc(tournamentId).update({
      'name': newName,
    });
  }

  @override
  Future<void> updateTournamentTeams(
    String tournamentId,
    List<Team> teams,
  ) async {
    await _firestore.collection('tournaments').doc(tournamentId).update({
      'teams': teams
          .map(
            (t) => {
              'id': t.id,
              'name': t.name,
              if (t.logoUrl != null) 'logoUrl': t.logoUrl,
            },
          )
          .toList(),
    });
  }

  @override
  Future<bool> tournamentHasKnockoutMatches(String tournamentId) async {
    final snapshot = await _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('matches')
        .where('groupName', isNull: true)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  @override
  Stream<List<Tournament>> watchTournaments() {
    return _firestore.collection('tournaments').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => TournamentModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<void> replaceKnockoutMatches(
    String tournamentId,
    List<Match> matches,
  ) async {
    final matchesRef = _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('matches');

    final oldKnockout = await matchesRef.where('groupName', isNull: true).get();

    final batch = _firestore.batch();

    for (var doc in oldKnockout.docs) {
      batch.delete(doc.reference);
    }

    for (var match in matches) {
      final matchRef = matchesRef.doc(match.id);

      batch.set(matchRef, {
        'id': match.id,
        'homeTeam': {
          'id': match.homeTeam.id,
          'name': match.homeTeam.name,
          'logoUrl': match.homeTeam.logoUrl,
        },
        'awayTeam': {
          'id': match.awayTeam.id,
          'name': match.awayTeam.name,
          'logoUrl': match.awayTeam.logoUrl,
        },
        'homeScore': match.homeScore,
        'awayScore': match.awayScore,
        'round': match.round,
        'groupName': match.groupName,
        'status': match.status.name,
        'nextMatchId': match.nextMatchId,
        'positionInNextMatch': match.positionInNextMatch,
      });
    }

    batch.update(_firestore.collection('tournaments').doc(tournamentId), {
      'status': 'ongoing',
    });

    await batch.commit();
  }
}
