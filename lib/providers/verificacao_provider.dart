import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../models/verificacao.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';

class VerificacaoProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final DatabaseService _databaseService = DatabaseService.instance;
  StreamSubscription<List<ConnectivityResult>>? _conexaoSubscription;

  List<Verificacao> _verificacoes = [];
  bool _carregando = false;
  bool _offline = false;
  String? _erro;
  String? _aviso;

  VerificacaoProvider() {
    _inicializarConexao();
  }

  List<Verificacao> get verificacoes => _verificacoes
      .where((v) => v.syncStatus != SyncStatus.pendingDelete)
      .toList();

  bool get carregando => _carregando;
  bool get offline => _offline;
  String? get erro => _erro;
  String? get aviso => _aviso;

  int get pendentes =>
      _verificacoes.where((v) => v.syncStatus != SyncStatus.synced).length;

  Future<void> _inicializarConexao() async {
    final resultado = await Connectivity().checkConnectivity();
    _offline = resultado.contains(ConnectivityResult.none);
    notifyListeners();

    _conexaoSubscription = Connectivity().onConnectivityChanged.listen((
      resultados,
    ) {
      final estavaOffline = _offline;
      _offline = resultados.contains(ConnectivityResult.none);
      notifyListeners();

      if (estavaOffline && !_offline) {
        sincronizarPendentes();
      }
    });
  }

  @override
  void dispose() {
    _conexaoSubscription?.cancel();
    super.dispose();
  }

  Future<void> carregarInicial() async {
    _carregando = true;
    _erro = null;
    _aviso = null;
    notifyListeners();

    _verificacoes = await _databaseService.listarTodas();

    try {
      final daApi = await _apiService.listar();
      await _databaseService.substituirComDadosDaApi(daApi);
      _verificacoes = await _databaseService.listarTodas();
    } catch (_) {
      if (_verificacoes.isEmpty) {
        _erro = 'Não foi possível carregar as verificações.';
      } else {
        _aviso = 'Sem conexão. Exibindo dados salvos localmente.';
      }
    }

    _carregando = false;
    notifyListeners();
  }

  Future<void> criar({
    required String title,
    required StatusVerificacao status,
    String? motivo,
  }) async {
    final verificacao = Verificacao(
      createdAt: DateTime.now(),
      title: title,
      status: status,
      motivo: motivo,
      syncStatus: SyncStatus.pendingCreate,
    );
    verificacao.validar();

    final salva = await _databaseService.inserir(verificacao);
    _verificacoes = [salva, ..._verificacoes];
    notifyListeners();

    await sincronizarPendentes();
  }

  Future<void> editar(
    Verificacao original, {
    required String title,
    required StatusVerificacao status,
    String? motivo,
  }) async {
    final editada = original.copyWith(
      title: title,
      status: status,
      motivo: motivo,
      syncStatus: original.remoteId == null
          ? SyncStatus.pendingCreate
          : SyncStatus.pendingUpdate,
    );
    editada.validar();

    await _databaseService.atualizar(editada);
    _substituirNaLista(editada);
    notifyListeners();

    await sincronizarPendentes();
  }

  Future<void> excluir(Verificacao verificacao) async {
    if (verificacao.remoteId == null) {
      await _databaseService.excluir(verificacao.localId!);
      _verificacoes.removeWhere((v) => v.localId == verificacao.localId);
    } else {
      final marcada = verificacao.copyWith(syncStatus: SyncStatus.pendingDelete);
      await _databaseService.atualizar(marcada);
      _substituirNaLista(marcada);
    }
    notifyListeners();

    await sincronizarPendentes();
  }

  void _substituirNaLista(Verificacao verificacao) {
    final index = _verificacoes.indexWhere((v) => v.localId == verificacao.localId);
    if (index != -1) {
      _verificacoes[index] = verificacao;
    }
  }

  Future<void> sincronizarPendentes() async {
    final pendentes = _verificacoes
        .where((v) => v.syncStatus != SyncStatus.synced)
        .toList();

    for (final verificacao in pendentes) {
      try {
        verificacao.validar();

        switch (verificacao.syncStatus) {
          case SyncStatus.pendingCreate:
            final criada = await _apiService.criar(verificacao);
            final sincronizada = criada.copyWith(localId: verificacao.localId);
            await _databaseService.atualizar(sincronizada);
            _substituirNaLista(sincronizada);
            break;

          case SyncStatus.pendingUpdate:
            final atualizada = await _apiService.atualizar(
              verificacao.remoteId!,
              verificacao,
            );
            final sincronizada = atualizada.copyWith(localId: verificacao.localId);
            await _databaseService.atualizar(sincronizada);
            _substituirNaLista(sincronizada);
            break;

          case SyncStatus.pendingDelete:
            await _apiService.excluir(verificacao.remoteId!);
            await _databaseService.excluir(verificacao.localId!);
            _verificacoes.removeWhere((v) => v.localId == verificacao.localId);
            break;

          case SyncStatus.synced:
            break;
        }
      } catch (_) {
        continue;
      }
    }

    notifyListeners();
  }
}
