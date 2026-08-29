/// Quita un parámetro de consulta sin alterar el resto de la URL.
String stripQueryParameterFromUrl(String url, {required String parameterName}) {
  final uri = Uri.tryParse(url);
  if (uri == null) return url;

  final cleanedUri = _stripQueryParameterFromUri(uri, parameterName);
  final cleanedFragment = _stripQueryParameterFromFragment(
    uri.fragment,
    parameterName,
  );

  return _buildUrl(cleanedUri, fragment: cleanedFragment);
}

/// Lee un parámetro desde la URL principal o desde el fragmento usado por Web.
String? readQueryParameterFromUrl(String url, {required String parameterName}) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;

  final fromQuery = uri.queryParameters[parameterName];
  if (fromQuery != null && fromQuery.isNotEmpty) return fromQuery;

  if (uri.fragment.isEmpty) return null;

  final fragmentUri = Uri.tryParse(uri.fragment);
  return fragmentUri?.queryParameters[parameterName];
}

Uri _stripQueryParameterFromUri(Uri uri, String parameterName) {
  if (!uri.queryParametersAll.containsKey(parameterName)) return uri;

  return _buildUri(
    uri,
    query: _queryWithoutParameter(uri.queryParametersAll, parameterName),
    fragment: uri.fragment,
  );
}

String _stripQueryParameterFromFragment(String fragment, String parameterName) {
  if (fragment.isEmpty) return fragment;

  final fragmentUri = Uri.tryParse(fragment);
  if (fragmentUri == null) return fragment;
  if (!fragmentUri.queryParametersAll.containsKey(parameterName)) {
    return fragment;
  }

  return _buildUrl(
    _buildUri(
      fragmentUri,
      query: _queryWithoutParameter(
        fragmentUri.queryParametersAll,
        parameterName,
      ),
      fragment: fragmentUri.fragment,
    ),
  );
}

Uri _buildUri(Uri source, {required String query, required String fragment}) {
  final effectiveQuery = query.isEmpty ? null : query;
  final effectiveFragment = fragment.isEmpty ? null : fragment;

  // Las rutas hash son relativas; reconstruirlas como absolutas agrega `///`.
  if (source.scheme.isEmpty && !source.hasAuthority) {
    return Uri(
      path: source.path,
      query: effectiveQuery,
      fragment: effectiveFragment,
    );
  }

  if (source.hasPort) {
    return Uri(
      scheme: source.scheme,
      userInfo: source.userInfo,
      host: source.host,
      port: source.port,
      path: source.path,
      query: effectiveQuery,
      fragment: effectiveFragment,
    );
  }

  return Uri(
    scheme: source.scheme,
    userInfo: source.userInfo,
    host: source.host,
    path: source.path,
    query: effectiveQuery,
    fragment: effectiveFragment,
  );
}

String _buildUrl(Uri uri, {String? fragment}) {
  return _buildUri(
    uri,
    query: uri.query,
    fragment: fragment ?? uri.fragment,
  ).toString();
}

String _queryWithoutParameter(
  Map<String, List<String>> queryParameters,
  String parameterName,
) {
  final pairs = <String>[];
  for (final entry in queryParameters.entries) {
    if (entry.key == parameterName) continue;

    for (final value in entry.value) {
      pairs.add(
        '${Uri.encodeQueryComponent(entry.key)}='
        '${Uri.encodeQueryComponent(value)}',
      );
    }
  }

  return pairs.join('&');
}
