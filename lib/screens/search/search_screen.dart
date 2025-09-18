import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:team_25_app/services/api_service.dart';
import 'package:team_25_app/theme/app_colors.dart';

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
  
  // 検索が実行されたかどうかを管理するフラグ
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
      // クエリが空になったら、検索結果もクリアする
      if (newQuery.isEmpty && _searchQuery.isNotEmpty) {
        setState(() {
          _searchResults = [];
          _hasSearched = false; // 検索状態をリセット
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
      _hasSearched = true; // 検索が実行されたことを記録
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
      // "Invalid element" が含まれるエラーは、UI上で「見つかりませんでした」と表示されるので、SnackBarは出さない
      if (errorMessage.contains('Invalid element')) {
        // 何もしない
        return;
      }

      // それ以外の予期せぬエラー（ネットワークエラーなど）はSnackBarで表示する
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 90.0, // AppBar の高さを明示的に設定
        title: const Text('物体名で検索', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false, // 自動生成を無効化
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // iOS風の矢印
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/'); // pop できない場合はホームへ
            }
          },
          tooltip: '前の画面に戻る',
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, const Color(0xFF2A93D5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(90.0),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 20.0),
            child: _buildSearchBar(),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

// 検索バーのウィジェット
  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      textInputAction: TextInputAction.search, // キーボードのアクションボタンを「検索」に
      decoration: InputDecoration(
        hintText: '元素名を入力してください（例：酸素）',
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.9)),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.9)),
                onPressed: () {
                  _searchController.clear();
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.8), width: 1.5),
        ),
      ),
      onSubmitted: _performSearch, // エンターキーで検索を実行
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 検索が実行されて、かつ結果が0件の場合のみ「見つかりませんでした」を表示
    if (_hasSearched && _searchResults.isEmpty) {
      return _buildNoResults();
    }

    // 検索結果があれば表示
    if (_searchResults.isNotEmpty) {
      return _buildResultsList();
    }

    // 上記以外（初期状態や、検索前）はクイック検索を表示
    return _buildQuickSearch();
  }

  Widget _buildQuickSearch() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  side: BorderSide(color: AppColors.primary.withOpacity(0.7)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

// 検索結果が1件以上ある場合に表示するウィジェット
  Widget _buildResultsList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 8.0),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => Divider(
        color: AppColors.primary.withOpacity(0.3),
        height: 1,
      ),
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
                  color: AppColors.textPrimary.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

// 検索結果が0件の場合に表示するウィジェット
  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          const Text(
            '見つかりませんでした',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '元素名を確認してもう一度検索してください。',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}