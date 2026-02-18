part of 'user_bloc.dart';

/// Base class for all User states
abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class UserInitial extends UserState {
  const UserInitial();
}

/// Loading state
class UserLoading extends UserState {
  const UserLoading();
}

/// Success state with user data
class UserLoaded extends UserState {
  const UserLoaded(this.user);
  final User user;

  @override
  List<Object?> get props => [user];
}

/// Error state
class UserError extends UserState {
  const UserError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
