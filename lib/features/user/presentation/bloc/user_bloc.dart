import 'package:admissao_app/features/user/domain/entities/user.dart';
import 'package:admissao_app/features/user/domain/usecases/get_user.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'user_event.dart';
part 'user_state.dart';

/// BLoC for User feature
/// Manages user-related state and business logic in the presentation layer
class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc({required this.getUser}) : super(const UserInitial()) {
    on<LoadUserEvent>(_onLoadUser);
    on<RefreshUserEvent>(_onRefreshUser);
  }
  final GetUser getUser;

  Future<void> _onLoadUser(LoadUserEvent event, Emitter<UserState> emit) async {
    emit(const UserLoading());

    final result = await getUser(GetUserParams(userId: event.userId));

    result.fold(
      (failure) => emit(UserError(failure.message)),
      (user) => emit(UserLoaded(user)),
    );
  }

  Future<void> _onRefreshUser(
    RefreshUserEvent event,
    Emitter<UserState> emit,
  ) async {
    if (state is UserLoaded) {
      final currentUser = (state as UserLoaded).user;
      emit(const UserLoading());

      final result = await getUser(GetUserParams(userId: currentUser.id));

      result.fold(
        (failure) => emit(UserError(failure.message)),
        (user) => emit(UserLoaded(user)),
      );
    }
  }
}
