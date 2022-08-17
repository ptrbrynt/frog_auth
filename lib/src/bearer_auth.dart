import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

/// A Bearer authentication scheme.
///
/// This is a simple authentication scheme that uses a token provided in the
/// Authorization header. The header should be in the form "Bearer <token>".
///
/// Requires a [retrieveUser] callback, which you should use to look up the
/// user in your database. The callback should return `null` if no user is
/// found; in that case the middleware will response with a 401 (Unauthorized).
///
/// If the user is found, the middleware will continue the request and provide
/// the retrieved user object to the request context. It can be accessed using
/// `context.read<User>()`.
///
/// The middleware will also respond with a 400 (Bad Request) if the
/// Authorization header is missing or malformed.
Middleware bearerAuthentication<User extends Object>({
  required UserFromToken<User> retrieveUser,
}) {
  return (handler) {
    return (context) async {
      final authHeader = context.request.headers['Authorization'];

      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response(statusCode: HttpStatus.badRequest);
      }

      try {
        final token = authHeader.split(' ')[1];
        final user = await retrieveUser(token);

        if (user == null) {
          return Response(statusCode: HttpStatus.unauthorized);
        }

        return await handler(context.provide(() => user));
      } on Exception {
        return Response(statusCode: HttpStatus.badRequest);
      }
    };
  };
}

typedef UserFromToken<User extends Object> = Future<User?> Function(
  String token,
);
