import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

/// A Basic authentication scheme.
///
/// This is a very simple authentication scheme that uses a username and
/// password provided in the Authorization header. The header should be
/// in the form "Basic <username>:<password>", where the username/password
/// portion is base64-encoded.
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
Middleware basicAuthentication<User extends Object>({
  required UserFromCredentials<User> retrieveUser,
}) {
  return (handler) {
    return (context) async {
      final authHeader = context.request.headers['Authorization'];

      if (authHeader == null || !authHeader.startsWith('Basic ')) {
        return Response(statusCode: HttpStatus.badRequest);
      }

      try {
        final credentials = utf8
            .decode(
              base64.decode(authHeader.split(' ')[1]),
            )
            .split(':');

        final username = credentials.first;
        final password = credentials[1];

        final user = await retrieveUser(username, password);

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

typedef UserFromCredentials<User extends Object> = Future<User?> Function(
  String username,
  String password,
);
