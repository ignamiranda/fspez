import 'package:equatable/equatable.dart';
import 'session_cookie.dart';

class Account with Equatable {
  final String id;
  final String username;
  final SessionCookie sessionCookie;

  const Account({
    required this.id,
    required this.username,
    required this.sessionCookie,
  });

  @override
  List<Object?> get props => [id, username, sessionCookie];
}
