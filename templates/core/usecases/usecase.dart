import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../errors/failures.dart';

/// Generic base interface for all UseCases.
/// Enforces single-responsibility and functional error handling.
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Use when a UseCase does not accept any parameters.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
