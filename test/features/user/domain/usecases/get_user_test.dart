import 'package:admissao_app/core/error/failures.dart';
import 'package:admissao_app/features/user/domain/entities/user.dart';
import 'package:admissao_app/features/user/domain/repositories/user_repository.dart';
import 'package:admissao_app/features/user/domain/usecases/get_user.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock do Repository
class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late GetUser useCase;
  late MockUserRepository mockRepository;

  setUp(() {
    mockRepository = MockUserRepository();
    useCase = GetUser(mockRepository);
  });

  final testUser = User(
    id: '1',
    name: 'Test User',
    email: 'test@example.com',
    createdAt: DateTime(2024, 1),
  );

  const testUserId = '1';

  group('GetUser UseCase', () {
    test('should return User when repository returns success', () async {
      // arrange
      when(
        () => mockRepository.getUser(any()),
      ).thenAnswer((_) async => Right(testUser));

      // act
      final result = await useCase(const GetUserParams(userId: testUserId));

      // assert
      expect(result, Right<Failure, User>(testUser));
      verify(() => mockRepository.getUser(testUserId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test(
      'should return ServerFailure when repository returns failure',
      () async {
        // arrange
        const testFailure = ServerFailure(message: 'Server error');
        when(
          () => mockRepository.getUser(any()),
        ).thenAnswer((_) async => const Left(testFailure));

        // act
        final result = await useCase(const GetUserParams(userId: testUserId));

        // assert
        expect(result, const Left<Failure, User>(testFailure));
        verify(() => mockRepository.getUser(testUserId)).called(1);
        verifyNoMoreInteractions(mockRepository);
      },
    );

    test('should call repository with correct parameters', () async {
      // arrange
      when(
        () => mockRepository.getUser(any()),
      ).thenAnswer((_) async =>  Right(testUser));

      // act
      await useCase(const GetUserParams(userId: testUserId));

      // assert
      verify(() => mockRepository.getUser(testUserId)).called(1);
    });
  });

  group('GetUserParams', () {
    test('should be a subclass of Equatable', () {
      // assert
      expect(const GetUserParams(userId: '1'), isA<Object>());
    });

    test('props should contain userId', () {
      // arrange
      const params = GetUserParams(userId: '1');

      // assert
      expect(params.props, ['1']);
    });

    test('two instances with same userId should be equal', () {
      // arrange
      const params1 = GetUserParams(userId: '1');
      const params2 = GetUserParams(userId: '1');

      // assert
      expect(params1, equals(params2));
    });

    test('two instances with different userId should not be equal', () {
      // arrange
      const params1 = GetUserParams(userId: '1');
      const params2 = GetUserParams(userId: '2');

      // assert
      expect(params1, isNot(equals(params2)));
    });
  });
}
