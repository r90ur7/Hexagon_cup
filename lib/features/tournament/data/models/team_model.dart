import 'package:admissao_app/features/tournament/domain/entities/team.dart';

class TeamModel extends Team {
  const TeamModel({required super.id, required super.name, super.logoUrl});

  // Converte Firestore Document para Model
  factory TeamModel.fromFirestore(Map<String, dynamic> json, String id) {
    return TeamModel(
      id: id,
      name: (json['name'] as String?) ?? '',
      logoUrl: json['logoUrl'] as String?,
    );
  }

  // Converte Model para Map do Firestore
  Map<String, dynamic> toFirestore() {
    return {'name': name, if (logoUrl != null) 'logoUrl': logoUrl};
  }
}
