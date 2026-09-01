import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/verificacao.dart';

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  String get _baseUrl => dotenv.env['SUPABASE_BASE_URL']!;
  String get _apiKey => dotenv.env['SUPABASE_API_KEY']!;

  Map<String, String> get _headers => {
    'apikey': _apiKey,
    'Authorization': 'Bearer $_apiKey',
    'Content-Type': 'application/json',
  };

  Future<List<Verificacao>> listar() async {
    final response = await http.get(Uri.parse(_baseUrl), headers: _headers);

    if (response.statusCode != 200) {
      throw ApiException('Erro ao buscar verificações (${response.statusCode})');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as List;
    return data
        .map((json) => Verificacao.fromApiJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Verificacao> criar(Verificacao verificacao) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {..._headers, 'Prefer': 'return=representation'},
      body: jsonEncode(verificacao.toApiJson()),
    );

    if (response.statusCode != 201) {
      throw ApiException('Erro ao criar verificação (${response.statusCode})');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as List;
    return Verificacao.fromApiJson(data.first as Map<String, dynamic>);
  }

  Future<Verificacao> atualizar(int id, Verificacao verificacao) async {
    final uri = Uri.parse('$_baseUrl?id=eq.$id');
    final response = await http.patch(
      uri,
      headers: {..._headers, 'Prefer': 'return=representation'},
      body: jsonEncode(verificacao.toApiJson()),
    );

    if (response.statusCode != 200) {
      throw ApiException('Erro ao atualizar verificação (${response.statusCode})');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as List;
    if (data.isEmpty) {
      throw ApiException('Verificação não encontrada na API');
    }

    return Verificacao.fromApiJson(data.first as Map<String, dynamic>);
  }

  Future<void> excluir(int id) async {
    final uri = Uri.parse('$_baseUrl?id=eq.$id');
    final response = await http.delete(uri, headers: _headers);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException('Erro ao excluir verificação (${response.statusCode})');
    }
  }
}
