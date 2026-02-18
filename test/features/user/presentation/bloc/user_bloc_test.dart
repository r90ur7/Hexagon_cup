import 'package:admissao_app/core/error/failures.dart';
import 'package:admissao_app/features/user/domain/entities/user.dart';
import 'package:admissao_app/features/user/domain/usecases/get_user.dart';
import 'package:admissao_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockGetUser extends Mock implements GetUser {}

void main() {
  late UserBloc bloc;
  late MockGetUser mockGetUser;

  setUp(() {
    mockGetUser = MockGetUser();
    bloc = UserBloc(getUser: mockGetUser);
  });

  // Register fallback values for any() matchers
  setUpAll(() {
    registerFallbackValue(const GetUserParams(userId: ''));
  });

  tearDown(() {
    bloc.close();
  });

  final testUser = User(
    id: '1',
    name: 'Test User',
    email: 'test@example.com',
    createdAt: DateTime(2024, 1),
  );

  const testUserId = '1';

  group('UserBloc', () {
    test('initial state should be UserInitial', () {
      // assert
      expect(bloc.state, equals(const UserInitial()));
    });

    blocTest<UserBloc, UserState>(
      'should emit [UserLoading, UserLoaded] when data is gotten successfully',
      build: () {
        when(() => mockGetUser(any())).thenAnswer((_) async => Right(testUser));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadUserEvent(testUserId)),
      expect: () => [const UserLoading(), UserLoaded(testUser)],
      verify: (_) {
        verify(
          () => mockGetUser(const GetUserParams(userId: testUserId)),
        ).called(1);
      },
    );

    blocTest<UserBloc, UserState>(
      'should emit [UserLoading, UserError] when getting data fails',
      build: () {
        when(() => mockGetUser(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Server error')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadUserEvent(testUserId)),
      expect: () => [const UserLoading(), const UserError('Server error')],
      verify: (_) {
        verify(
          () => mockGetUser(const GetUserParams(userId: testUserId)),
        ).called(1);
      },
    );

    blocTest<UserBloc, UserState>(
      'should emit [UserLoading, UserLoaded] when RefreshUserEvent is added and user is already loaded',
      build: () {
        when(() => mockGetUser(any())).thenAnswer((_) async => Right(testUser));
        return bloc;
      },
      seed: () => UserLoaded(testUser),
      act: (bloc) => bloc.add(const RefreshUserEvent()),
      expect: () => [const UserLoading(), UserLoaded(testUser)],
      verify: (_) {
        verify(
          () => mockGetUser(const GetUserParams(userId: testUserId)),
        ).called(1);
      },
    );
  });

  group('LoadUserEvent', () {
    test('should have correct props', () {
      // arrange
      const event = LoadUserEvent('1');

      // assert
      expect(event.props, ['1']);
    });

    test('two events with same userId should be equal', () {
      // arrange
      const event1 = LoadUserEvent('1');
      const event2 = LoadUserEvent('1');

      // assert
      expect(event1, equals(event2));
    });
  });

  group('UserState', () {
    test('UserLoaded should have correct props', () {
      // arrange
      final state = UserLoaded(testUser);

      // assert
      expect(state.props, [testUser]);
    });

    test('UserError should have correct props', () {
      // arrange
      const state = UserError('error');

      // assert
      expect(state.props, ['error']);
    });
  });
}
