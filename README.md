# Frog Auth

Authentication tools for [Dart Frog](http://dartfrog.vgv.dev) apps.

## Installation

![Pub Version](https://img.shields.io/pub/v/frog_auth)

```sh
dart pub add frog_auth
```

## Usage

### Basic Authentication

To support [Basic authentication](https://en.wikipedia.org/wiki/Basic_access_authentication), simply add the `basicAuthentication` middleware:

```dart
Handler middleware(Handler handler) {
    return handler.use(
        basicAuthentication(
            retrieveUser: (context, username, password) async {
                // TODO Retrieve user by username/password
            },
        ),
    );
}
```

The `retrieveUser` callback should be used to lookup the user using the given username and password. If no user is found with the given credentials, you should return `null`.

If a non-null user is returned by the `retrieveUser` callback, it will be provided to the current request context and can be retrieved using `context.read()`.

`retrieveUser` can return an object of any type extending `Object`, so should be flexible enough to work with any database system.

### Bearer Authentication

To support [Bearer authentication](https://datatracker.ietf.org/doc/html/rfc6750), simply add the `bearerAuthentication` middleware:

```dart
Handler middleware(Handler handler) {
    return handler.use(
        bearerAuthentication(
            retrieveUser: (context, token) async {
                // TODO Retrieve user by token
            },
        ),
    );
}
```

The `retrieveUser` callback should be used to lookup the user using the given token. If no user is found with the given token, you should return `null`.

If a non-null user is returned by the `retrieveUser` callback, it will be provided to the current request context and can be retrieved using `context.read()`.

`retrieveUser` can return an object of any type extending `Object`, so should be flexible enough to work with any database system.
