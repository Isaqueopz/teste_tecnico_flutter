enum StatusVerificacao {
  aguardando(0),
  aprovado(1),
  reprovado(2);

  final int value;
  const StatusVerificacao(this.value);

  static StatusVerificacao fromValue(int value) {
    return StatusVerificacao.values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw ArgumentError('Status inválido: $value'),
    );
  }

  String get label {
    switch (this) {
      case StatusVerificacao.aguardando:
        return 'Aguardando verificação';
      case StatusVerificacao.aprovado:
        return 'Aprovado';
      case StatusVerificacao.reprovado:
        return 'Reprovado';
    }
  }
}

enum SyncStatus { synced, pendingCreate, pendingUpdate, pendingDelete }

class VerificacaoValidationException implements Exception {
  final String message;
  const VerificacaoValidationException(this.message);

  @override
  String toString() => message;
}

class Verificacao {
  final int? localId;
  final int? remoteId;
  final DateTime createdAt;
  final String title;
  final StatusVerificacao status;
  final String? motivo;
  final SyncStatus syncStatus;

  Verificacao({
    this.localId,
    this.remoteId,
    required this.createdAt,
    required this.title,
    required this.status,
    this.motivo,
    this.syncStatus = SyncStatus.synced,
  });

  String? get _motivoNormalizado =>
      status == StatusVerificacao.aprovado ? null : motivo;

  void validar() {
    if (status == StatusVerificacao.reprovado &&
        (motivo == null || motivo!.trim().isEmpty)) {
      throw const VerificacaoValidationException(
        'Motivo é obrigatório quando o status é Reprovado.',
      );
    }
  }

  factory Verificacao.fromApiJson(Map<String, dynamic> json) {
    return Verificacao(
      remoteId: json['id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      title: json['title'] as String,
      status: StatusVerificacao.fromValue(json['status'] as int),
      motivo: json['motivo'] as String?,
      syncStatus: SyncStatus.synced,
    );
  }

  Map<String, dynamic> toApiJson() {
    return {
      'title': title,
      'status': status.value,
      'motivo': _motivoNormalizado,
    };
  }

  factory Verificacao.fromDbMap(Map<String, dynamic> map) {
    return Verificacao(
      localId: map['local_id'] as int,
      remoteId: map['remote_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      title: map['title'] as String,
      status: StatusVerificacao.fromValue(map['status'] as int),
      motivo: map['motivo'] as String?,
      syncStatus: SyncStatus.values.byName(map['sync_status'] as String),
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      if (localId != null) 'local_id': localId,
      'remote_id': remoteId,
      'created_at': createdAt.toIso8601String(),
      'title': title,
      'status': status.value,
      'motivo': _motivoNormalizado,
      'sync_status': syncStatus.name,
    };
  }

  Verificacao copyWith({
    int? localId,
    int? remoteId,
    DateTime? createdAt,
    String? title,
    StatusVerificacao? status,
    String? motivo,
    SyncStatus? syncStatus,
  }) {
    return Verificacao(
      localId: localId ?? this.localId,
      remoteId: remoteId ?? this.remoteId,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
      status: status ?? this.status,
      motivo: motivo ?? this.motivo,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
