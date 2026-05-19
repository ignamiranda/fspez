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

  factory SessionCookie.fromValue(String cookieValue, {String? rawCookie, String? modhash}) {
    return SessionCookie(
      value: cookieValue,
      expiresAt: DateTime.now().add(const Duration(days: 365)),
      rawCookie: rawCookie,
      modhash: modhash,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  @override
  List<Object?> get props => [value, expiresAt, rawCookie, modhash];
}
