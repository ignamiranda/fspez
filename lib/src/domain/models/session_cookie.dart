import 'package:equatable/equatable.dart';

class SessionCookie with EquatableMixin {
  final String value;
  final DateTime expiresAt;

  const SessionCookie({
    required this.value,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  @override
  List<Object?> get props => [value, expiresAt];
}
