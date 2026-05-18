import 'package:equatable/equatable.dart';

class Multireddit with EquatableMixin {
  final String id;
  final String name;
  final String displayName;
  final List<String> subredditNames;
  final String owner;
  final String? description;

  const Multireddit({
    required this.id,
    required this.name,
    required this.displayName,
    required this.subredditNames,
    required this.owner,
    this.description,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        displayName,
        subredditNames,
        owner,
        description,
      ];
}
