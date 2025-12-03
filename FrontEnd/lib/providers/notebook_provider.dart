import 'package:flutter/material.dart';
import '../models/notebook.dart';
import '../services/notebook_service.dart';

class NotebookProvider extends ChangeNotifier {
  final NotebookService _notebookService = NotebookService();

  List<Notebook> _notes = [];
  Notebook? _selectedNote;
  bool _isLoading = false;
  String? _error;

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  final int _itemsPerPage = 20;

  // Filter
  String? _selectedType;
  String _searchQuery = '';

  // Getters
  List<Notebook> get notes => _notes;
  Notebook? get selectedNote => _selectedNote;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  String? get selectedType => _selectedType;
  String get searchQuery => _searchQuery;
  bool get hasNextPage => _currentPage < _totalPages;
  bool get hasPrevPage => _currentPage > 1;

  /// Load danh sách ghi chú
  Future<void> loadNotes({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _notes = [];
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _notebookService.getNotes(
        page: _currentPage,
        limit: _itemsPerPage,
        type: _selectedType,
        search: _searchQuery,
      );

      _notes = result['data'];
      _totalPages = result['totalPages'];
      _totalItems = result['totalItems'];
      _currentPage = result['currentPage'];
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tìm kiếm ghi chú
  Future<void> searchNotes(String keyword) async {
    _searchQuery = keyword;
    await loadNotes(refresh: true);
  }

  /// Lọc theo type
  Future<void> filterByType(String? type) async {
    _selectedType = type;
    await loadNotes(refresh: true);
  }

  /// Load chi tiết ghi chú
  Future<void> loadNoteDetail(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedNote = await _notebookService.getNoteById(id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tạo ghi chú mới
  Future<bool> createNote({
    required String title,
    required String content,
    String type = 'general',
    String? relatedItemId,
    String? relatedItemType,
    List<String>? tags,
  }) async {
    try {
      final data = {
        'title': title,
        'content': content,
        'type': type,
        if (relatedItemId != null) 'related_item_id': relatedItemId,
        if (relatedItemType != null) 'related_item_type': relatedItemType,
        if (tags != null) 'tags': tags,
      };

      final newNote = await _notebookService.createNote(data);
      _notes.insert(0, newNote);
      _totalItems++;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Cập nhật ghi chú
  Future<bool> updateNote(
    String id, {
    String? title,
    String? content,
    String? type,
    List<String>? tags,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (content != null) data['content'] = content;
      if (type != null) data['type'] = type;
      if (tags != null) data['tags'] = tags;

      final updatedNote = await _notebookService.updateNote(id, data);
      
      final index = _notes.indexWhere((note) => note.id == id);
      if (index != -1) {
        _notes[index] = updatedNote;
      }
      
      if (_selectedNote?.id == id) {
        _selectedNote = updatedNote;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Xóa ghi chú
  Future<bool> deleteNote(String id) async {
    try {
      await _notebookService.deleteNote(id);
      _notes.removeWhere((note) => note.id == id);
      _totalItems--;
      
      if (_selectedNote?.id == id) {
        _selectedNote = null;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Xóa nhiều ghi chú
  Future<int> deleteMultipleNotes(List<String> ids) async {
    try {
      final deletedCount = await _notebookService.deleteMultipleNotes(ids);
      _notes.removeWhere((note) => ids.contains(note.id));
      _totalItems = _totalItems - deletedCount;
      notifyListeners();
      return deletedCount;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return 0;
    }
  }

  /// Chuyển trang tiếp theo
  Future<void> nextPage() async {
    if (hasNextPage) {
      _currentPage++;
      await loadNotes();
    }
  }

  /// Chuyển trang trước
  Future<void> previousPage() async {
    if (hasPrevPage) {
      _currentPage--;
      await loadNotes();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reset filter
  Future<void> resetFilter() async {
    _selectedType = null;
    _searchQuery = '';
    await loadNotes(refresh: true);
  }

  /// Clear all state
  void clear() {
    _notes = [];
    _selectedNote = null;
    _isLoading = false;
    _error = null;
    _currentPage = 1;
    _totalPages = 1;
    _totalItems = 0;
    _selectedType = null;
    _searchQuery = '';
    notifyListeners();
  }
}
