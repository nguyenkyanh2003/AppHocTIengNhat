import '../network/api_client.dart';

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
    } on ApiException catch (error) {
      return ViewFailure<T>(error.message);
    } catch (_) {
      return ViewFailure<T>('Đã có lỗi xảy ra. Vui lòng thử lại.');
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
