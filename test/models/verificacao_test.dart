import 'package:flutter_test/flutter_test.dart';
import 'package:teste_tecnico_flutter/models/verificacao.dart';

void main() {
  group('Verificacao.validar', () {
    test('reprovado sem motivo lança exceção', () {
      final v = Verificacao(
        createdAt: DateTime.now(),
        title: 'teste',
        status: StatusVerificacao.reprovado,
      );

      expect(v.validar, throwsA(isA<VerificacaoValidationException>()));
    });

    test('reprovado com motivo em branco também lança exceção', () {
      final v = Verificacao(
        createdAt: DateTime.now(),
        title: 'teste',
        status: StatusVerificacao.reprovado,
        motivo: '   ',
      );

      expect(v.validar, throwsA(isA<VerificacaoValidationException>()));
    });

    test('reprovado com motivo é válido', () {
      final v = Verificacao(
        createdAt: DateTime.now(),
        title: 'teste',
        status: StatusVerificacao.reprovado,
        motivo: 'Documento ilegível',
      );

      expect(v.validar, returnsNormally);
    });

    test('aguardando e aprovado não exigem motivo', () {
      final aguardando = Verificacao(
        createdAt: DateTime.now(),
        title: 'teste',
        status: StatusVerificacao.aguardando,
      );
      final aprovado = Verificacao(
        createdAt: DateTime.now(),
        title: 'teste',
        status: StatusVerificacao.aprovado,
      );

      expect(aguardando.validar, returnsNormally);
      expect(aprovado.validar, returnsNormally);
    });
  });

  group('Verificacao serialização', () {
    test('toApiJson normaliza motivo para null quando aprovado', () {
      final v = Verificacao(
        createdAt: DateTime.now(),
        title: 'teste',
        status: StatusVerificacao.aprovado,
        motivo: 'texto que não deveria ser enviado',
      );

      expect(v.toApiJson()['motivo'], isNull);
    });

    test('fromApiJson -> toApiJson mantém os dados', () {
      final json = {
        'id': 1,
        'created_at': '2026-08-31T21:13:49.341778+00:00',
        'title': 'Verificação de acesso à obra',
        'status': 2,
        'motivo': 'Documentação incompleta',
      };

      final v = Verificacao.fromApiJson(json);

      expect(v.remoteId, 1);
      expect(v.title, 'Verificação de acesso à obra');
      expect(v.status, StatusVerificacao.reprovado);
      expect(v.toApiJson()['motivo'], 'Documentação incompleta');
    });

    test('fromDbMap -> toDbMap mantém os dados, incluindo caracteres especiais', () {
      final map = {
        'local_id': 5,
        'remote_id': 10,
        'created_at': '2026-08-31T21:13:49.341778Z',
        'title': 'Inspeção de instalação elétrica – bloco C',
        'status': 0,
        'motivo': null,
        'sync_status': 'pendingUpdate',
      };

      final v = Verificacao.fromDbMap(map);
      final result = v.toDbMap();

      expect(v.localId, 5);
      expect(v.syncStatus, SyncStatus.pendingUpdate);
      expect(result['title'], 'Inspeção de instalação elétrica – bloco C');
      expect(result['sync_status'], 'pendingUpdate');
    });
  });
}
