import 'dart:async' show TimeoutException;
import 'dart:io' show SocketException, HttpException;
import 'package:flutter/foundation.dart' show FlutterError;

String userFriendlyErrorMessage(Object error) {
  if (error is SocketException) {
    return 'Could not connect to the server. Check your connection.';
  }
  if (error is HttpException) {
    return 'Could not connect to the server. Check your connection.';
  }
  if (error is TimeoutException) {
    return 'The request timed out. Please try again.';
  }
  if (error is FormatException) {
    return 'Received unexpected data. Please try again.';
  }
  if (error is FlutterError) {
    return 'Something went wrong. Please try again.';
  }
  if (error is ArgumentError) {
    return 'Something went wrong. Please try again.';
  }

  final msg = error.toString();
  if (msg.contains('SocketException') ||
      msg.contains('Connection refused') ||
      msg.contains('Connection reset')) {
    return 'Could not connect to the server. Check your connection.';
  }
  if (msg.contains('TimeoutException') || msg.contains('timed out')) {
    return 'The request timed out. Please try again.';
  }
  if (msg.contains('type') && msg.contains('is not a subtype')) {
    return 'Received unexpected data. Please try again.';
  }
  if (msg.contains('HandshakeException')) {
    return 'Could not establish a secure connection. Please try again.';
  }
  return 'Something went wrong. Please try again.';
}
