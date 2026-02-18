import 'package:equatable/equatable.dart';
import '../../domain/entities/tournament.dart';

abstract class TournamentState extends Equatable {
  const TournamentState();
  @override
  List<Object?> get props => [];
}

class TournamentInitial extends TournamentState {}

class TournamentLoading extends TournamentState {}

class TournamentSuccess extends TournamentState {
  final List<Tournament> tournaments;
  const TournamentSuccess(this.tournaments);
  @override
  List<Object?> get props => [tournaments];
}

class TournamentCreated extends TournamentState {} // Para navegar após criar

class TournamentError extends TournamentState {
  final String message;
  const TournamentError(this.message);
  @override
  List<Object?> get props => [message];
}
