/// Metadatos de paginación estandarizados de ManoLocal-Back.
class PaginationMeta {
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const PaginationMeta({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    final total = (json['total'] as num?)?.toInt() ?? 0;
    final page = (json['page'] as num?)?.toInt() ?? 1;
    final limit = (json['limit'] as num?)?.toInt() ?? 10;
    final rawTotalPages = (json['totalPages'] as num?)?.toInt();
    final computedTotalPages =
        rawTotalPages ?? (limit > 0 ? (total / limit).ceil() : 0);

    return PaginationMeta(
      total: total,
      page: page,
      limit: limit,
      totalPages: computedTotalPages,
      hasNext: (json['hasNext'] as bool?) ?? (page < computedTotalPages),
      hasPrev: (json['hasPrev'] as bool?) ?? (page > 1),
    );
  }
}

/// Respuesta paginada genérica compatible con `chat`, `wallet`, `jobs` y `search`.
class PaginatedResponse<T> {
  final List<T> items;
  final PaginationMeta meta;

  const PaginatedResponse({
    required this.items,
    required this.meta,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemParser, {
    String itemsKey = 'data',
    String metaKey = 'meta',
  }) {
    final rawItems = json[itemsKey];
    final items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(itemParser)
            .toList()
        : <T>[];

    final rawMeta = json[metaKey];
    final meta = rawMeta is Map<String, dynamic>
        ? PaginationMeta.fromJson(rawMeta)
        : PaginationMeta(
            total: items.length,
            page: 1,
            limit: items.isEmpty ? 10 : items.length,
            totalPages: 1,
            hasNext: false,
            hasPrev: false,
          );

    return PaginatedResponse<T>(
      items: items,
      meta: meta,
    );
  }
}
