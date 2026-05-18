import 'package:equatable/equatable.dart';

class SessionCookie with EquatableMixin {
  final String value;
  final DateTime expiresAt;
  final String? rawCookie;
  final String? modhash;

  const SessionCookie({
    required this.value,
    required this.expiresAt,
    this.rawCookie,
    this.modhash,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  @override
  List<Object?> get props => [value, expiresAt, rawCookie, modhash];
}
