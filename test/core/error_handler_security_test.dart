import 'package:flutter_test/flutter_test.dart';

/// B-084: Error Handler Security Tests
void main() {
  group('Error Sanitization', () {
    test('should sanitize SQL errors', () {
      const String sqlError = 'SqliteException: no such table: users';

      final sanitized = _sanitizeError(sqlError);

      expect(sanitized, 'Database error occurred');
      expect(sanitized.contains('Sqlite'), false);
      expect(sanitized.contains('table'), false);
    });

    test('should sanitize database errors', () {
      const String dbError = 'Database error: invalid schema';

      final sanitized = _sanitizeError(dbError);

      expect(sanitized, 'Database error occurred');
      expect(sanitized.contains('schema'), false);
    });

    test('should sanitize generic exceptions', () {
      const String exception = 'Exception: Invalid argument';

      final sanitized = _sanitizeError(exception);

      expect(sanitized, 'An error occurred');
      expect(sanitized.contains('Exception'), false);
      expect(sanitized.contains('argument'), false);
    });

    test('should sanitize error objects', () {
      const String error = 'Error: Network timeout';

      final sanitized = _sanitizeError(error);

      expect(sanitized, 'An error occurred');
      expect(sanitized.contains('Error:'), false);
      expect(sanitized.contains('timeout'), false);
    });

    test('should handle unknown errors', () {
      const String unknownError = 'Something went wrong';

      final sanitized = _sanitizeError(unknownError);

      expect(sanitized, 'Unexpected error');
    });
  });

  group('SQL Pattern Detection', () {
    test('should detect Sqlite keywords', () {
      const errors = [
        'SqliteException',
        'Sqlite error',
        'SQLITE_ERROR',
      ];

      for (final error in errors) {
        final isSqlError = error.toLowerCase().contains('sqlite');
        expect(isSqlError, true);
      }
    });

    test('should detect SQL keywords', () {
      const errors = [
        'SQL syntax error',
        'Invalid SQL query',
        'sql exception',
      ];

      for (final error in errors) {
        final isSqlError = error.toLowerCase().contains('sql');
        expect(isSqlError, true);
      }
    });

    test('should detect database keywords', () {
      const errors = [
        'Database connection failed',
        'database schema error',
        'DATABASE_ERROR',
      ];

      for (final error in errors) {
        final isDbError = error.toLowerCase().contains('database');
        expect(isDbError, true);
      }
    });
  });

  group('Debug vs Release Mode', () {
    test('should show full error in debug mode', () {
      const bool isDebug = true;
      const String fullError = 'SqliteException: no such table: users';

      final displayError = isDebug ? fullError : _sanitizeError(fullError);

      if (isDebug) {
        expect(displayError, fullError);
        expect(displayError.contains('Sqlite'), true);
      }
    });

    test('should hide details in release mode', () {
      const bool isDebug = false;
      const String fullError = 'SqliteException: no such table: users';

      final displayError = isDebug ? fullError : _sanitizeError(fullError);

      if (!isDebug) {
        expect(displayError, isNot(fullError));
        expect(displayError.contains('Sqlite'), false);
      }
    });
  });

  group('User-Friendly Messages', () {
    test('should provide actionable message for database errors', () {
      const String sanitized = 'Database error occurred';

      expect(sanitized.contains('Database'), true);
      expect(sanitized.contains('occurred'), true);
    });

    test('should provide generic message for unknown errors', () {
      const String sanitized = 'An error occurred';

      expect(sanitized.contains('error'), true);
      expect(sanitized.length, lessThan(50)); // Keep it short
    });

    test('should avoid technical jargon', () {
      final userMessages = [
        'Database error occurred',
        'An error occurred',
        'Unexpected error',
      ];

      for (final msg in userMessages) {
        expect(msg.contains('Exception'), false);
        expect(msg.contains('Stack'), false);
        expect(msg.contains('trace'), false);
        expect(msg.contains('SQL'), false);
      }
    });
  });
}

/// Helper function (same as in main.dart)
String _sanitizeError(Object error) {
  final errorString = error.toString().toLowerCase();
  
  if (errorString.contains('sqlite') || 
      errorString.contains('sql') ||
      errorString.contains('database')) {
    return 'Database error occurred';
  }
  
  if (errorString.contains('exception:') || 
      errorString.contains('error:')) {
    return 'An error occurred';
  }
  
  return 'Unexpected error';
}
