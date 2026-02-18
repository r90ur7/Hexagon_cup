import 'package:equatable/equatable.dart';

class Team extends Equatable {

  const Team({required this.id, required this.name, this.logoUrl});
  final String id;
  final String name;
  final String? logoUrl;

  @override
  List<Object?> get props => [id, name, logoUrl];
}
