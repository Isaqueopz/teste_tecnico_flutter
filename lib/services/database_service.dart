import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/verificacao.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  Database? _database;

  Future<Database> get _db async {
    _database ??= await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'verificacoes.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE verificacoes (
            local_id INTEGER PRIMARY KEY AUTOINCREMENT,
            remote_id INTEGER,
            created_at TEXT NOT NULL,
            title TEXT NOT NULL,
            status INTEGER NOT NULL,
            motivo TEXT,
            sync_status TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<List<Verificacao>> listarTodas() async {
    final db = await _db;
    final maps = await db.query('verificacoes', orderBy: 'created_at DESC');
    return maps.map((map) => Verificacao.fromDbMap(map)).toList();
  }

  Future<Verificacao> inserir(Verificacao verificacao) async {
    final db = await _db;
    final localId = await db.insert('verificacoes', verificacao.toDbMap());
    return verificacao.copyWith(localId: localId);
  }

  Future<void> atualizar(Verificacao verificacao) async {
    final db = await _db;
    await db.update(
      'verificacoes',
      verificacao.toDbMap(),
      where: 'local_id = ?',
      whereArgs: [verificacao.localId],
    );
  }

  Future<void> excluir(int localId) async {
    final db = await _db;
    await db.delete('verificacoes', where: 'local_id = ?', whereArgs: [localId]);
  }

  Future<void> substituirComDadosDaApi(List<Verificacao> verificacoesDaApi) async {
    final db = await _db;

    await db.transaction((txn) async {
      final pendentes = await txn.query(
        'verificacoes',
        where: 'sync_status != ?',
        whereArgs: [SyncStatus.synced.name],
      );
      final remoteIdsPendentes = pendentes
          .map((map) => map['remote_id'] as int?)
          .whereType<int>()
          .toSet();

      await txn.delete(
        'verificacoes',
        where: 'sync_status = ?',
        whereArgs: [SyncStatus.synced.name],
      );

      for (final verificacao in verificacoesDaApi) {
        if (remoteIdsPendentes.contains(verificacao.remoteId)) continue;
        await txn.insert('verificacoes', verificacao.toDbMap());
      }
    });
  }
}
