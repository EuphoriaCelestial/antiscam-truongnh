import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config/api_config.dart';
import '../models/models.dart';

class DocumentProvider extends ChangeNotifier {
  List<Document> _documents = [];
  Document? _currentDocument;
  bool _isLoading = false;
  String? _error;

  List<Document> get documents => _documents;
  Document? get currentDocument => _currentDocument;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchDocuments({String? category}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String url = ApiConfig.documents;
      if (category != null) {
        url += '?category=$category';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _documents = data.map((doc) => Document.fromJson(doc)).toList();
        _isLoading = false;
        notifyListeners();
      } else {
        _error = 'Failed to load documents';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Network error: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDocument(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.documents}/$id'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentDocument = Document.fromJson(data);
        _isLoading = false;
        notifyListeners();
      } else {
        _error = 'Document not found';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Network error: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCurrentDocument() {
    _currentDocument = null;
    notifyListeners();
  }
}
