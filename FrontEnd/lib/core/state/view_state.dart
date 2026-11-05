import '../network/api_client.dart';

/// Câu báo lỗi cho người dùng từ một exception bất kỳ.
///
/// Lỗi của `ApiClient` đã là câu đọc được; lỗi khác (đọc sai JSON, lỗi lập trình)
/// là chi tiết kỹ thuật nên không đưa lên giao diện.
String userMessageOf(Object error) => error is ApiException
    ? error.message
    : 'Đã có lỗi xảy ra. Vui lòng thử lại.';

/// Trạng thái của một dữ liệu bất đồng bộ trên màn hình.
///
/// Thay cho bộ ba `_isLoading` / `_error` / `_data` mà mỗi provider tự quản.
/// Bộ ba đó cho phép những tổ hợp vô nghĩa (đang loading mà vẫn có lỗi cũ, có
/// dữ liệu nhưng cờ loading chưa tắt); [ViewState] thì mỗi lúc chỉ ở đúng một
/// trạng thái nên UI không cần đoán.
sealed class ViewState<T> {
  const ViewState();

  const factory ViewState.idle() = ViewIdle<T>;
  const factory ViewState.loading() = ViewLoading<T>;
  const factory ViewState.data(T value) = ViewData<T>;
  const factory ViewState.failure(String message) = ViewFailure<T>;

  /// Cầu nối cho provider còn giữ bộ ba `isLoading` / `error` / dữ liệu, để màn
  /// hình vẫn đi qua `AsyncView`.
  ///
  /// Đã có nội dung thì giữ nguyên nội dung kể cả khi đang tải lại hoặc lần tải
  /// lại lỗi: mất mạng một lần không được xoá trắng màn hình.
  factory ViewState.fromLegacy({
    required bool isLoading,
    required String? error,
    required T? value,
    bool isEmpty = false,
  }) {
    if (value != null && !isEmpty) return ViewData<T>(value);
    if (isLoading) return ViewLoading<T>();
    if (error != null) return ViewFailure<T>(error);
    return value != null ? ViewData<T>(value) : ViewIdle<T>();
  }

  /// Như [ViewState.fromLegacy] nhưng cho màn chi tiết: đang tải hoặc lỗi thì không
  /// giữ bản cũ, vì bản cũ có thể là của mục khác.
  ///
  /// Chưa có gì mà cũng không lỗi là "chưa tải xong" (hiện vòng xoay), nên provider
  /// phải đặt `error` khi server không trả về mục đó.
  factory ViewState.detail({
    required bool isLoading,
    required String? error,
    required T? value,
  }) {
    if (isLoading) return ViewLoading<T>();
    if (error != null) return ViewFailure<T>(error);
    return value != null ? ViewData<T>(value) : ViewIdle<T>();
  }

  bool get isLoading => this is ViewLoading<T>;
  bool get hasData => this is ViewData<T>;

  T? get valueOrNull => switch (this) {
        ViewData<T>(:final value) => value,
        _ => null,
      };

  String? get errorOrNull => switch (this) {
        ViewFailure<T>(:final message) => message,
        _ => null,
      };

  /// Chạy một tác vụ và bọc kết quả vào [ViewState].
  ///
  /// Đây là nơi duy nhất dịch exception sang thông báo cho người dùng, nên màn
  /// hình không bao giờ hiển thị `Exception: ...` thô nữa.
  static Future<ViewState<T>> guard<T>(Future<T> Function() task) async {
    try {
      return ViewData<T>(await task());
    } catch (error) {
      return ViewFailure<T>(userMessageOf(error));
    }
  }
}

/// Chưa yêu cầu dữ liệu lần nào.
final class ViewIdle<T> extends ViewState<T> {
  const ViewIdle();
}

final class ViewLoading<T> extends ViewState<T> {
  const ViewLoading();
}

final class ViewData<T> extends ViewState<T> {
  const ViewData(this.value);

  final T value;
}

final class ViewFailure<T> extends ViewState<T> {
  const ViewFailure(this.message);

  final String message;
}
