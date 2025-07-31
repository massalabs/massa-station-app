// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:mug/service/local_storage_service.dart';
import 'package:mug/service/provider.dart';

enum SearchType { address, block, operation, mns, unknown }

// We could also use packages like Freezed to help with the implementation.
@immutable
class Search {
  final SearchType searchType;
  final String searchTitle;
  const Search({
    required this.searchType,
    required this.searchTitle,
  });

  Search copyWith({
    SearchType? searchType,
  }) {
    return Search(searchType: searchType ?? this.searchType, searchTitle: searchTitle);
  }
}

class SearchProvider extends StateNotifier<Search> {
  final LocalStorageService localStorageService;

  SearchProvider({
    required this.localStorageService,
  }) : super(const Search(searchType: SearchType.unknown, searchTitle: "No Result")) {}

  SearchType getSearchType(String searchString) {
    var searchType = SearchType.unknown;
    var searchTitle = "No Result";
    final prefix1 = searchString.substring(0, 1);
    final prefix2 = searchString.substring(0, 2);
    final length = searchString.length;

    if ((prefix2 == 'AU' || prefix2 == 'AS') && (length > 50)) {
      searchType = SearchType.address;
      searchTitle = "Address Details";
    }
    if ((prefix1 == 'B') && (length > 50)) {
      searchType = SearchType.block;
      searchTitle = "Block Details";
    }
    if ((prefix1 == 'O') && (length > 50)) {
      searchType = SearchType.operation;
      searchTitle = "Operation Details";
    }
    if (searchString.contains('.massa')) {
      searchType = SearchType.mns;
      searchTitle = "MNS Details";
    }
    state = Search(searchType: searchType, searchTitle: searchTitle);
    return searchType;
  }
}

final searchProvider = StateNotifierProvider<SearchProvider, Search>((ref) {
  return SearchProvider(localStorageService: ref.watch(localStorageServiceProvider));
});
