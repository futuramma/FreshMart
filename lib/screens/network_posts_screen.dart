import 'package:flutter/material.dart';
import '../models/api_post.dart';
import '../utils/api_service.dart';
import '../utils/database_helper.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

/// Week 6 — Network Posts Screen
/// Demonstrates ALL Week 6 learning outcomes:
///
///   LO1: Networking concepts — client-server communication with JSONPlaceholder
///   LO2: Internet access — uses the http package over the configured INTERNET permission
///   LO3: HTTP requests — GET, POST, PUT, DELETE on /posts endpoint
///   LO4: REST APIs — full CRUD mapping (Create→POST, Read→GET, Update→PUT, Delete→DELETE)
///   LO5: Async networking + local storage — FutureBuilder, async/await, SQLite caching
///
/// Features:
///   - Loads posts from API, caches to SQLite for offline access
///   - Create new posts via FAB → dialog (POST)
///   - Edit posts via tap → dialog (PUT)
///   - Delete posts via swipe-to-dismiss (DELETE)
///   - Pull-to-refresh to re-fetch from API
///   - Online/offline status indicator
///   - Shows data source (Network vs Cache)
class NetworkPostsScreen extends StatefulWidget {
  const NetworkPostsScreen({super.key});

  @override
  State<NetworkPostsScreen> createState() => _NetworkPostsScreenState();
}

class _NetworkPostsScreenState extends State<NetworkPostsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<ApiPost> _posts = [];
  bool _isLoading = true;
  bool _isFromCache = false;
  String? _errorMessage;
  int _cachedCount = 0;
  String? _lastCacheTime;

  late AnimationController _fabAnimController;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadPosts();
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DATA LOADING — Async networking + local storage integration (LO5)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Load posts using an offline-first strategy:
  /// 1. Try to fetch from the REST API (network-first)
  /// 2. On success: cache to SQLite, display from network
  /// 3. On failure: fall back to SQLite cache
  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Step 1: Attempt to fetch from REST API (LO3 — HTTP GET request)
      final posts = await _apiService.fetchPosts();

      // Step 2: Cache the fetched posts to SQLite (LO5 — local storage integration)
      await _dbHelper.cachePosts(posts);

      // Step 3: Update UI with network data
      final cachedCount = await _dbHelper.getCachedPostCount();
      final lastTime = await _dbHelper.getLastCacheTime();

      if (mounted) {
        setState(() {
          _posts = posts;
          _isFromCache = false;
          _isLoading = false;
          _cachedCount = cachedCount;
          _lastCacheTime = lastTime;
        });
      }
    } catch (e) {
      // Network failed — fall back to local SQLite cache (LO5)
      try {
        final cachedPosts = await _dbHelper.getCachedPosts();
        final cachedCount = await _dbHelper.getCachedPostCount();
        final lastTime = await _dbHelper.getLastCacheTime();

        if (mounted) {
          setState(() {
            _posts = cachedPosts;
            _isFromCache = true;
            _isLoading = false;
            _cachedCount = cachedCount;
            _lastCacheTime = lastTime;
            if (cachedPosts.isEmpty) {
              _errorMessage = e.toString().replaceFirst('Exception: ', '');
            }
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = e.toString().replaceFirst('Exception: ', '');
          });
        }
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CREATE — HTTP POST request (LO3, LO4)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _createPost(String title, String body) async {
    try {
      final newPost = ApiPost(userId: 1, title: title, body: body);

      // Send POST request to REST API
      final created = await _apiService.createPost(newPost);

      // Also save to local cache
      await _dbHelper.insertCachedPost(created);

      if (mounted) {
        setState(() {
          _posts.insert(0, created);
          _cachedCount++;
        });
        _showSnackBar('Post created successfully!', AppColors.success,
            Icons.check_circle_outline);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
            'Failed to create post: ${e.toString().replaceFirst("Exception: ", "")}',
            AppColors.error,
            Icons.error_outline);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UPDATE — HTTP PUT request (LO3, LO4)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _updatePost(ApiPost post, String title, String body) async {
    try {
      final updated = post.copyWith(title: title, body: body);

      // Send PUT request to REST API
      await _apiService.updatePost(updated);

      // Also update local cache
      await _dbHelper.updateCachedPost(updated);

      if (mounted) {
        setState(() {
          final index = _posts.indexWhere((p) => p.id == post.id);
          if (index != -1) {
            _posts[index] = updated;
          }
        });
        _showSnackBar(
            'Post updated!', AppColors.info, Icons.edit_outlined);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
            'Failed to update: ${e.toString().replaceFirst("Exception: ", "")}',
            AppColors.error,
            Icons.error_outline);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DELETE — HTTP DELETE request (LO3, LO4)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _deletePost(ApiPost post) async {
    try {
      // Send DELETE request to REST API
      await _apiService.deletePost(post.id!);

      // Also remove from local cache
      await _dbHelper.deleteCachedPost(post.id!);

      if (mounted) {
        setState(() {
          _posts.removeWhere((p) => p.id == post.id);
          _cachedCount--;
        });
        _showSnackBar(
            'Post deleted', AppColors.warning, Icons.delete_outline);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
            'Failed to delete: ${e.toString().replaceFirst("Exception: ", "")}',
            AppColors.error,
            Icons.error_outline);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFAB(),
    );
  }

  // ─── App Bar ───────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Network Posts'),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        // Refresh button
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadPosts,
          tooltip: 'Refresh from API',
        ),
        // Cache info button
        IconButton(
          icon: const Icon(Icons.storage_outlined, color: Colors.white),
          onPressed: _showCacheInfo,
          tooltip: 'Cache Info',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Icon(
                _isFromCache ? Icons.cloud_off_outlined : Icons.cloud_outlined,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _isFromCache
                    ? 'Source: Local SQLite Cache'
                    : 'Source: jsonplaceholder.typicode.com',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.8), fontSize: 12),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (_isFromCache
                          ? AppColors.warning
                          : AppColors.success)
                      .withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isFromCache ? 'OFFLINE' : 'ONLINE',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'CRUD /posts',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_isLoading) return _buildLoadingState();
    if (_errorMessage != null && _posts.isEmpty) {
      return _buildErrorState(_errorMessage!);
    }
    if (_posts.isEmpty) return _buildEmptyState();
    return _buildPostList();
  }

  // ─── Loading State ─────────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 20),
          Text(
            'Fetching posts from API...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'GET ${AppConstants.apiPostsUrl}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textHint,
                  fontFamily: 'monospace',
                ),
          ),
        ],
      ),
    );
  }

  // ─── Error State ───────────────────────────────────────────────────────────

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  size: 52, color: AppColors.error),
            ),
            const SizedBox(height: 20),
            Text(
              'Network Error',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'No cached data available.\nConnect to the internet and try again.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textHint),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPosts,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Empty State ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.article_outlined,
              size: 72, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('No posts available',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Tap + to create your first post',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textHint)),
        ],
      ),
    );
  }

  // ─── Post List (with pull-to-refresh) ──────────────────────────────────────

  Widget _buildPostList() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadPosts,
      child: Column(
        children: [
          // Source & count banner
          _buildSourceBanner(),
          // Offline cache banner (if applicable)
          if (_isFromCache) _buildOfflineBanner(),
          // Post list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildPostCard(_posts[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: AppColors.surfaceVariant,
      child: Row(
        children: [
          Icon(
            _isFromCache
                ? Icons.storage_outlined
                : Icons.check_circle_outline,
            size: 14,
            color: _isFromCache ? AppColors.warning : AppColors.success,
          ),
          const SizedBox(width: 6),
          Text(
            _isFromCache
                ? '${_posts.length} posts from cache'
                : '${_posts.length} posts loaded • HTTP 200 OK',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const Spacer(),
          // HTTP method badges
          _buildMethodBadge('GET', AppColors.success),
          const SizedBox(width: 4),
          _buildMethodBadge('POST', AppColors.info),
          const SizedBox(width: 4),
          _buildMethodBadge('PUT', AppColors.warning),
          const SizedBox(width: 4),
          _buildMethodBadge('DEL', AppColors.error),
        ],
      ),
    );
  }

  Widget _buildMethodBadge(String method, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        method,
        style: TextStyle(
            color: color, fontSize: 9, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: AppColors.warning.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              size: 14, color: AppColors.warning),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Showing cached data. Pull down to refresh from network.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Post Card (Dismissible for DELETE) ────────────────────────────────────

  Widget _buildPostCard(ApiPost post, int index) {
    final colors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.info,
      const Color(0xFF7C3AED),
      const Color(0xFFDB2777),
      const Color(0xFF0891B2),
      const Color(0xFFD97706),
      const Color(0xFF059669),
      const Color(0xFFDC2626),
      const Color(0xFF2563EB),
    ];
    final cardColor = colors[(post.id ?? index) % colors.length];

    return Dismissible(
      key: ValueKey(post.id ?? index),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_outline, color: AppColors.error, size: 28),
            const SizedBox(height: 4),
            Text('DELETE',
                style: TextStyle(
                    color: AppColors.error,
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      confirmDismiss: (_) => _confirmDelete(post),
      onDismissed: (_) => _deletePost(post),
      child: GestureDetector(
        onTap: () => _showEditDialog(post),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Colored top accent bar
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row: ID badge + title
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Post ID badge
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: cardColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '#${post.id}',
                              style: TextStyle(
                                color: cardColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            post.title,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  height: 1.3,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Action buttons
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => _showEditDialog(post),
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(Icons.edit_outlined,
                                    size: 18,
                                    color: AppColors.textSecondary),
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () async {
                                final confirmed = await _confirmDelete(post);
                                if (confirmed == true) _deletePost(post);
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(Icons.delete_outline,
                                    size: 18, color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Body text
                    Text(
                      post.body,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    // Footer: User ID + actions
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 12, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          'User ${post.userId}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppColors.textHint,
                                fontSize: 11,
                              ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.swipe_left_outlined,
                            size: 12, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          'Swipe to delete',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppColors.textHint,
                                fontSize: 11,
                              ),
                        ),
                        const Spacer(),
                        Text(
                          'Tap to edit',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: cardColor.withOpacity(0.6),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── FAB ───────────────────────────────────────────────────────────────────

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _showCreateDialog,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('New Post'),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DIALOGS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Show dialog to create a new post (triggers POST request)
  void _showCreateDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.post_add,
                  color: AppColors.success, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create Post',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                Text('POST /posts',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                        fontFamily: 'monospace')),
              ],
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter post title...',
                  prefixIcon: Icon(Icons.title),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(
                  labelText: 'Body',
                  hintText: 'Enter post content...',
                  prefixIcon: Icon(Icons.article_outlined),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty &&
                  bodyController.text.trim().isNotEmpty) {
                Navigator.pop(ctx);
                _createPost(
                    titleController.text.trim(), bodyController.text.trim());
              }
            },
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Create'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  /// Show dialog to edit an existing post (triggers PUT request)
  void _showEditDialog(ApiPost post) {
    final titleController = TextEditingController(text: post.title);
    final bodyController = TextEditingController(text: post.body);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_outlined,
                  color: AppColors.info, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Edit Post',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  Text('PUT /posts/${post.id}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                          fontFamily: 'monospace')),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.title),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(
                  labelText: 'Body',
                  prefixIcon: Icon(Icons.article_outlined),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty &&
                  bodyController.text.trim().isNotEmpty) {
                Navigator.pop(ctx);
                _updatePost(post, titleController.text.trim(),
                    bodyController.text.trim());
              }
            },
            icon: const Icon(Icons.save_outlined, size: 16),
            label: const Text('Update'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
            ),
          ),
        ],
      ),
    );
  }

  /// Confirm deletion with a dialog
  Future<bool?> _confirmDelete(ApiPost post) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline,
                  color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Delete Post?',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  Text('DELETE /posts/${post.id}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                          fontFamily: 'monospace')),
                ],
              ),
            ),
          ],
        ),
        content: Text(
          'This will send a DELETE request to the API and remove the post from local cache.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  /// Show cache info dialog
  void _showCacheInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.storage_outlined,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('SQLite Cache Info',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInfoRow(Icons.table_chart_outlined, 'Table',
                AppConstants.tablePostsCache),
            _buildInfoRow(Icons.numbers, 'Cached Posts', '$_cachedCount'),
            _buildInfoRow(
                Icons.access_time,
                'Last Updated',
                _lastCacheTime != null
                    ? _formatTime(_lastCacheTime!)
                    : 'Never'),
            _buildInfoRow(
                Icons.cloud_outlined,
                'Data Source',
                _isFromCache ? 'Local Cache' : 'Network API'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Posts are cached locally in SQLite after each '
                'successful API fetch. When offline, the app serves '
                'data from this cache.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _dbHelper.clearPostsCache();
              if (mounted) {
                Navigator.pop(ctx);
                _showSnackBar('Cache cleared', AppColors.warning,
                    Icons.delete_sweep_outlined);
                _loadPosts();
              }
            },
            child: const Text('Clear Cache',
                style: TextStyle(color: AppColors.error)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  )),
          const Spacer(),
          Text(value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  )),
        ],
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _showSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return isoString;
    }
  }
}
