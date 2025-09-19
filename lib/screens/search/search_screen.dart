import 'package:flutter/material.dart';
import 'package:team_25_app/services/api_service.dart';
import 'package:team_25_app/theme/app_colors.dart';
import 'package:team_25_app/widgets/common_bottom_navigation_bar.dart';

import '/widgets/common_app_bar.dart';

// 元素情報のデータモデル（クイック検索用）
class ElementInfo {
  final String symbol;
  final String name;
  final String nameEn;
  final int number;

  ElementInfo({
    required this.symbol,
    required this.name,
    required this.nameEn,
    required this.number,
  });
}

// 化合物情報のデータモデル（検索結果用）
class CompoundInfo {
  final String name;
  final String description;

  CompoundInfo({required this.name, required this.description});

  factory CompoundInfo.fromJson(Map<String, dynamic> json) {
    return CompoundInfo(
      name: json['name'] as String? ?? '名前なし',
      description: json['description'] as String? ?? '説明がありません',
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String _searchQuery = '';

  bool _hasSearched = false;

  final List<ElementInfo> _quickSearchElements = [
    ElementInfo(symbol: 'O', name: '酸素', nameEn: 'Oxygen', number: 8),
    ElementInfo(symbol: 'H', name: '水素', nameEn: 'Hydrogen', number: 1),
    ElementInfo(symbol: 'C', name: '炭素', nameEn: 'Carbon', number: 6),
    ElementInfo(symbol: 'N', name: '窒素', nameEn: 'Nitrogen', number: 7),
    ElementInfo(symbol: 'Fe', name: '鉄', nameEn: 'Iron', number: 26),
    ElementInfo(symbol: 'Ca', name: 'カルシウム', nameEn: 'Calcium', number: 20),
  ];

  List<CompoundInfo> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final newQuery = _searchController.text;
      if (newQuery.isEmpty && _searchQuery.isNotEmpty) {
        setState(() {
          _searchResults = [];
          _hasSearched = false;
          _isLoading = false;
        });
      }
      setState(() {
        _searchQuery = newQuery;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    FocusScope.of(context).unfocus();

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _searchResults = [];
    });

    try {
      final results = await ApiService.searchCompoundsByQuery(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      if (!mounted) return;

      final errorMessage = e.toString();
      if (errorMessage.contains('Invalid element')) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage.replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CommonAppBar(),
      body: Column(
        children: [
          // 検索バーをbodyの先頭に移動
          Padding(
            padding: const EdgeInsets.fromLTRB(
              24.0,
              20.0,
              24.0,
              20.0,
            ), // 上部のパディングを調整
            child: _buildSearchBar(),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
      bottomNavigationBar: const CommonBottomNavigationBar(
        currentIndex: 1, // 検索画面のインデックス
      ),
    );
  }

  // 検索バーのウィジェット
  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      style: const TextStyle(color: Colors.black, fontSize: 16), // テキスト色を黒に変更
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: '元素名を入力してください（例：酸素）',
        hintStyle: TextStyle(
          color: Colors.black.withValues(alpha: 0.7),
          fontSize: 12,
        ), // ヒント色を黒に変更
        prefixIcon: Icon(
          Icons.search,
          color: Colors.black.withValues(alpha: 0.9),
        ), // アイコン色を黒に変更
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: Colors.black.withValues(alpha: 0.9),
                ), // アイコン色を黒に変更
                onPressed: () {
                  _searchController.clear();
                },
              )
            : null,
        filled: true,
        fillColor: Colors.grey.withValues(alpha: 0.2), // 塗りつぶし色を調整
        contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(
            color: Colors.grey.withValues(alpha: 0.8),
            width: 1.5,
          ),
        ),
      ),
      onSubmitted: _performSearch,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasSearched && _searchResults.isEmpty) {
      return _buildNoResults();
    }

    if (_searchResults.isNotEmpty) {
      return _buildResultsList();
    }

    return _buildQuickSearch();
  }

  Widget _buildQuickSearch() {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        const Text(
          'よく検索される元素',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12.0,
          runSpacing: 12.0,
          children: _quickSearchElements.map((element) {
            return ActionChip(
              onPressed: () {
                _searchController.text = element.name;
                _performSearch(element.name);
              },
              avatar: CircleAvatar(
                backgroundColor: AppColors.primaryDark,
                child: Text(
                  element.symbol,
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              label: Text(
                element.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: AppColors.surface,
              shape: StadiumBorder(
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.7),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResultsList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 8.0),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) =>
          Divider(color: AppColors.primary.withValues(alpha: 0.3), height: 1),
      itemBuilder: (context, index) {
        final compound = _searchResults[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                compound.name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                compound.description,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 20),
          const Text(
            '見つかりませんでした',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '元素名を確認してもう一度検索してください。',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
