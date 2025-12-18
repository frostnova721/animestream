enum LoadingState {
  loading,
  loaded,
  error;

  bool get isLoading => this == LoadingState.loading;
  bool get isLoaded => this == LoadingState.loaded;
  bool get isError => this == LoadingState.error;
}