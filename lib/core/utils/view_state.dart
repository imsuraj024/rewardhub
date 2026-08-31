sealed class ViewState<T> {
  const ViewState();

  bool get isLoading => this is ViewStateLoading;

  String? get errorMessage {
    if (this is ViewStateError) {
      return (this as ViewStateError).message;
    }
    return null;
  }
}

class ViewStateInitial<T> extends ViewState<T> {
  const ViewStateInitial();
}

class ViewStateLoading<T> extends ViewState<T> {
  const ViewStateLoading();
}

class ViewStateSuccess<T> extends ViewState<T> {
  final T? data;
  const ViewStateSuccess([this.data]);
}

class ViewStateError<T> extends ViewState<T> {
  final String message;
  const ViewStateError(this.message);
}
