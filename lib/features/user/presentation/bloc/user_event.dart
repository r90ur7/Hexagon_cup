part of 'user_bloc.dart';

/// Base class for all User events
abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load a user
class LoadUserEvent extends UserEvent {
  const LoadUserEvent(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to refresh user data
class RefreshUserEvent extends UserEvent {
  const RefreshUserEvent();
}
