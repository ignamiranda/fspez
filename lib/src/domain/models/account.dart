import 'package:equatable/equatable.dart';
import 'session_cookie.dart';

class Account with EquatableMixin {
  final String id;
  final String username;
  final SessionCookie sessionCookie;
  final bool isDefault;

  const Account({
    required this.id,
    required this.username,
    required this.sessionCookie,
    this.isDefault = false,
  });

  @override
  List<Object?> get props => [id, username, sessionCookie, isDefault];
}
