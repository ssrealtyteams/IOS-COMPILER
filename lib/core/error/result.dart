// Result type for error handling without exceptions
import 'package:equatable/equatable.dart';

sealed class Result<T, E extends AppError> {
  const Result();

  factory Result.success(T data) = Success<T, E>;
  factory Result.failure(E error) = Failure<T, E>;

  bool get isSuccess => this is Success<T, E>;
  bool get isFailure => this is Failure<T, E>;

  T get data => (this as Success<T, E>).data;
  E get error => (this as Failure<T, E>).error;

  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(E error) onFailure,
  }) {
    return switch (this) {
      Success(:final data) => onSuccess(data),
      Failure(:final error) => onFailure(error),
    };
  }

  Result<R, E> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success(:final data) => Result.success(transform(data)),
      Failure(:final error) => Result.failure(error),
    };
  }

  T? getOrNull() => isSuccess ? data : null;
  T getOrElse(T defaultValue) => isSuccess ? data : defaultValue;
}

final class Success<T, E extends AppError> extends Result<T, E> {
  const Success(this.data);
  final T data;
}

final class Failure<T, E extends AppError> extends Result<T, E> {
  const Failure(this.error);
  final E error;
}

// ─── App Error ───────────────────────────────────────────────────────────────
class AppError extends Equatable {
  const AppError({
    required this.message,
    required this.type,
    this.code,
    this.statusCode,
    this.details,
  });

  final String message;
  final AppErrorType type;
  final String? code;
  final int? statusCode;
  final List<String>? details;

  factory AppError.network(String message) => AppError(
        message: message,
        type: AppErrorType.network,
      );

  factory AppError.server(String message, {int? statusCode, String? code}) =>
      AppError(
        message: message,
        type: AppErrorType.server,
        statusCode: statusCode,
        code: code,
      );

  factory AppError.unauthorized() => const AppError(
        message: 'Session expired. Please login again.',
        type: AppErrorType.unauthorized,
        statusCode: 401,
      );

  factory AppError.forbidden() => const AppError(
        message: 'You do not have permission to perform this action.',
        type: AppErrorType.forbidden,
        statusCode: 403,
      );

  factory AppError.notFound(String resource) => AppError(
        message: '$resource not found.',
        type: AppErrorType.notFound,
        statusCode: 404,
      );

  factory AppError.validation(String message, {List<String>? details}) =>
      AppError(
        message: message,
        type: AppErrorType.validation,
        statusCode: 422,
        details: details,
      );

  factory AppError.local(String message) => AppError(
        message: message,
        type: AppErrorType.local,
      );

  factory AppError.unknown() => const AppError(
        message: 'An unexpected error occurred. Please try again.',
        type: AppErrorType.unknown,
      );

  @override
  List<Object?> get props => [message, type, code, statusCode];

  @override
  String toString() => 'AppError(type: $type, message: $message)';
}

enum AppErrorType {
  network,
  server,
  unauthorized,
  forbidden,
  notFound,
  validation,
  local,
  unknown,
}

// ─── View State ──────────────────────────────────────────────────────────────
sealed class ViewState {
  const ViewState();
  const factory ViewState.initial() = _Initial;
  const factory ViewState.loading() = _Loading;
  const factory ViewState.success() = _Success;
  const factory ViewState.error(String message) = _Error;

  bool get isInitial => this is _Initial;
  bool get isLoading => this is _Loading;
  bool get isSuccess => this is _Success;
  bool get isError => this is _Error;

  String? get errorMessage => isError ? (this as _Error).message : null;
}

final class _Initial extends ViewState {
  const _Initial();
}

final class _Loading extends ViewState {
  const _Loading();
}

final class _Success extends ViewState {
  const _Success();
}

final class _Error extends ViewState {
  const _Error(this.message);
  final String message;
}

// ─── Pagination ──────────────────────────────────────────────────────────────
class PaginationParams {
  const PaginationParams({this.page = 1, this.limit = 20});
  final int page;
  final int limit;

  Map<String, dynamic> toQueryMap() => {'page': page, 'limit': limit};
}

class PaginatedList<T> {
  const PaginatedList({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<T> items;
  final int total;
  final int page;
  final int limit;

  bool get hasNextPage => (page * limit) < total;
  int get totalPages => (total / limit).ceil();

  static PaginatedList<T> empty<T>() => const PaginatedList(
        items: [],
        total: 0,
        page: 1,
        limit: 20,
      );

  factory PaginatedList.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final data = json['data'] as List<dynamic>;
    final meta = json['meta'] as Map<String, dynamic>;
    return PaginatedList(
      items: data.map((e) => fromJson(e as Map<String, dynamic>)).toList(),
      total: meta['total'] as int,
      page: meta['page'] as int,
      limit: meta['limit'] as int,
    );
  }
}
