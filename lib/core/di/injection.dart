import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:admissao_app/core/network/network_info.dart';
import 'package:admissao_app/core/constants/api_constants.dart';
import 'package:admissao_app/features/user/data/datasources/user_remote_datasource.dart';
import 'package:admissao_app/features/user/data/datasources/user_local_datasource.dart';
import 'package:admissao_app/features/user/data/repositories/user_repository_impl.dart';
import 'package:admissao_app/features/user/domain/repositories/user_repository.dart';
import 'package:admissao_app/features/user/domain/usecases/get_user.dart';
import 'package:admissao_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:admissao_app/features/tournament/domain/repositories/tournament_repository.dart';
import 'package:admissao_app/features/tournament/data/repositories/tournament_repository_impl.dart';
import 'package:admissao_app/features/tournament/domain/usecases/calculate_standings.dart';
import 'package:admissao_app/features/tournament/domain/usecases/generate_groups_usecase.dart';
import 'package:admissao_app/features/tournament/domain/usecases/generate_knockout_bracket.dart';
import 'package:admissao_app/features/tournament/presentation/bloc/tournament_cubit.dart';

final sl = GetIt.instance;

/// Configura todas as dependências da aplicação via Service Locator (GetIt).
Future<void> init() async {
  // ── Tournament ──────────────────────────────────────────────────────────
  sl.registerFactory(
    () => TournamentCubit(
      repository: sl(),
      generateGroups: sl(),
      generateKnockout: sl(),
      calculateStandings: sl(),
    ),
  );

  sl.registerLazySingleton(() => CalculateStandingsUseCase());
  sl.registerLazySingleton(() => GenerateGroupsUseCase());
  sl.registerLazySingleton(() => GenerateKnockoutBracket());

  sl.registerLazySingleton<TournamentRepository>(
    () => TournamentRepositoryImpl(sl()),
  );

  // ── User ────────────────────────────────────────────────────────────────
  sl.registerFactory(() => UserBloc(getUser: sl()));
  sl.registerLazySingleton(() => GetUser(sl()));

  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(dio: sl()),
  );

  sl.registerLazySingleton<UserLocalDataSource>(
    () => UserLocalDataSourceImpl(sharedPreferences: sl()),
  );

  // ── Core & External ─────────────────────────────────────────────────────
  sl.registerLazySingleton<NetworkInfo>(NetworkInfoImpl.new);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(_createDio);

  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
}

/// Creates and configures Dio instance
Dio _createDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: {
        'Content-Type': ApiConstants.contentType,
        'Accept': ApiConstants.accept,
      },
    ),
  );

  dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));

  return dio;
}
