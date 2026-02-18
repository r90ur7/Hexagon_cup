import 'package:equatable/equatable.dart';
import 'package:admissao_app/features/tournament/domain/entities/team.dart';

class Group extends Equatable {

  const Group({required this.id, required this.name, required this.teams});
  final String id;
  final String name;
  final List<Team> teams;

  @override
  List<Object?> get props => [id, name, teams];
}
