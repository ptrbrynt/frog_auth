import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:frog_auth/frog_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  Response onRequest(RequestContext _) {
    return Response(body: 'Hello, World!');
  }

  late _MockRequestContext context;

  setUp(() {
    context = _MockRequestContext();
    when(() => context.provide<Map<String, dynamic>>(any()))
        .thenReturn(context);
  });

  group('basic authentication', () {
    late Handler handler;

    setUp(() {
      handler = const Pipeline().addMiddleware(
        basicAuthentication(
          retrieveUser: (_, username, password) async {
            return username == 'peter' && password == 'test'
                ? <String, dynamic>{'username': username}
                : null;
          },
        ),
      ).addHandler(onRequest);
    });

    test('returns ok when user is found', () async {
      final request = Request.get(
        Uri.parse('http://localhost/'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('peter:test'))}',
        },
      );

      when(() => context.request).thenReturn(request);

      final response = await handler(context);

      await expectLater(response.statusCode, equals(HttpStatus.ok));
      await expectLater(await response.body(), equals('Hello, World!'));
    });

    test('returns 401 when user credentials are invalid', () async {
      final request = Request.get(
        Uri.parse('http://localhost/'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('peter:wrong'))}',
        },
      );

      when(() => context.request).thenReturn(request);

      final response = await handler(context);

      await expectLater(response.statusCode, equals(HttpStatus.unauthorized));
    });

    test('returns 400 when credentials do not start with "Basic"', () async {
      final request = Request.get(
        Uri.parse('http://localhost/'),
        headers: {
          'Authorization': 'Bearer ${base64Encode(utf8.encode('peter:test'))}',
        },
      );

      when(() => context.request).thenReturn(request);

      final response = await handler(context);

      await expectLater(response.statusCode, equals(HttpStatus.badRequest));
    });

    test('returns 400 when Authorization header is malformed', () async {
      final request = Request.get(
        Uri.parse('http://localhost/'),
        headers: {
          'Authorization': 'peter:test',
        },
      );

      when(() => context.request).thenReturn(request);

      final response = await handler(context);

      await expectLater(response.statusCode, equals(HttpStatus.badRequest));
    });

    test('returns 400 when Authorization header is missing', () async {
      final request = Request.get(
        Uri.parse('http://localhost/'),
        headers: {},
      );

      when(() => context.request).thenReturn(request);

      final response = await handler(context);

      await expectLater(response.statusCode, equals(HttpStatus.badRequest));
    });
  });

  group('bearer authentication', () {
    late Handler handler;

    setUp(() {
      handler = const Pipeline().addMiddleware(
        bearerAuthentication(
          retrieveUser: (_, token) async {
            return token == 'test_token'
                ? <String, dynamic>{'username': 'test'}
                : null;
          },
        ),
      ).addHandler(onRequest);
    });

    test('returns ok when valid token is provided', () async {
      final request = Request.get(
        Uri.parse('http://localhost/'),
        headers: {
          'Authorization': 'Bearer test_token',
        },
      );

      when(() => context.request).thenReturn(request);

      final response = await handler(context);

      await expectLater(response.statusCode, equals(HttpStatus.ok));
      await expectLater(await response.body(), equals('Hello, World!'));
    });

    test('returns 401 when token is invalid', () async {
      final request = Request.get(
        Uri.parse('http://localhost/'),
        headers: {
          'Authorization': 'Bearer another_token',
        },
      );

      when(() => context.request).thenReturn(request);

      final response = await handler(context);

      await expectLater(response.statusCode, equals(HttpStatus.unauthorized));
    });

    test(
      'returns 400 when Authorization header does not start with "Bearer"',
      () async {
        final request = Request.get(
          Uri.parse('http://localhost/'),
          headers: {
            'Authorization': 'Basic peter:test',
          },
        );

        when(() => context.request).thenReturn(request);

        final response = await handler(context);

        await expectLater(response.statusCode, equals(HttpStatus.badRequest));
      },
    );

    test('returns 400 when Authorization header is malformed', () async {
      final request = Request.get(
        Uri.parse('http://localhost/'),
        headers: {
          'Authorization': 'peter:test',
        },
      );

      when(() => context.request).thenReturn(request);

      final response = await handler(context);

      await expectLater(response.statusCode, equals(HttpStatus.badRequest));
    });

    test('returns 400 when Authorization header is missing', () async {
      final request = Request.get(
        Uri.parse('http://localhost/'),
        headers: {},
      );

      when(() => context.request).thenReturn(request);

      final response = await handler(context);

      await expectLater(response.statusCode, equals(HttpStatus.badRequest));
    });
  });
}
