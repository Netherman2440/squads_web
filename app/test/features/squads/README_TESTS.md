# Squads Feature Test Suite

This directory contains comprehensive unit tests for the Squads feature.

## Test Coverage

### Domain Layer Tests

#### Entities
- **squad_test.dart**: Tests for Squad entity
  - Enum parsers (SquadVisibility, SportType)
  - Squad construction and validation
  - copyWith functionality
  - fromMap/toMap serialization
  - Round-trip serialization
  - Edge cases (null values, invalid data)

- **user_squad_role_test.dart**: Tests for UserSquadRole entity
  - SquadRole enum and parser
  - Role label generation
  - fromMap deserialization
  - Case-insensitive parsing

### Application Layer Tests

#### Use Cases
- **create_squad_use_case_test.dart**: Tests for CreateSquadUseCase
  - Validation (empty names, whitespace)
  - Business rules (one squad per owner)
  - Success scenarios
  - Name trimming
  - Error handling

- **apply_to_squad_use_case_test.dart**: Tests for ApplyToSquadUseCase
  - Squad application flow
  - Parameter validation
  - Error propagation

- **get_squads_use_case_test.dart**: Tests for GetSquadsUseCase
  - Guest user scenarios
  - Logged-in user role enrichment
  - Filter forwarding (visibility, search, sport type)
  - Empty results handling
  - Error handling

### Presentation Layer Tests

#### State
- **squads_state_test.dart**: Tests for SquadsState
  - Default values
  - copyWith functionality
  - State transitions (loading, error, success)
  - Immutability

## Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/features/squads/domain/entities/squad_test.dart

# Run tests with coverage
flutter test --coverage

# Run tests in watch mode (if using a watcher)
flutter test --watch
```

## Test Dependencies

- `flutter_test`: Flutter's testing framework
- `mockito`: Mocking library for repository tests
- `build_runner`: Code generation for mockito

## Generating Mocks

If you add new dependencies or modify interfaces that need mocking, regenerate mocks:

```bash
cd app
flutter pub run build_runner build --delete-conflicting-outputs
```

## Test Structure

Tests follow the Arrange-Act-Assert (AAA) pattern:
1. **Arrange**: Set up test data and mocks
2. **Act**: Execute the code being tested  
3. **Assert**: Verify the expected outcomes

## Coverage Goals

- Domain entities: 100% (pure functions, no external dependencies)
- Use cases: 95%+ (business logic)
- State classes: 100% (data structures)
- Repositories: Covered via integration tests (not included here)
- UI widgets: Covered via widget tests (not included here)

## Notes

- Repository implementations are tested via integration tests with a test database
- Widget tests for UI components should be added separately
- State notifier tests require Riverpod testing utilities (to be added)