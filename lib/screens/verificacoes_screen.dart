import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/verificacao.dart';
import '../providers/verificacao_provider.dart';

class VerificacoesScreen extends StatefulWidget {
  const VerificacoesScreen({super.key});

  @override
  State<VerificacoesScreen> createState() => _VerificacoesScreenState();
}

class _VerificacoesScreenState extends State<VerificacoesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VerificacaoProvider>().carregarInicial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VerificacaoProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificações'),
        actions: [
          if (provider.offline)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.cloud_off),
            ),
          if (provider.pendentes > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Chip(
                  label: Text(
                    '${provider.pendentes} pendente${provider.pendentes > 1 ? 's' : ''}',
                  ),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.08),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset('assets/images/logo.png', height: 22),
          ),
        ],
      ),
      body: _buildBody(context, provider),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova verificação'),
      ),
    );
  }

  Widget _buildBody(BuildContext context, VerificacaoProvider provider) {
    if (provider.carregando && provider.verificacoes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.erro != null && provider.verificacoes.isEmpty) {
      return _ErroView(
        mensagem: provider.erro!,
        onTentarNovamente: provider.carregarInicial,
      );
    }

    if (provider.verificacoes.isEmpty) {
      return _EstadoVazio(onAdicionar: () => _abrirFormulario(context));
    }

    return RefreshIndicator(
      onRefresh: provider.carregarInicial,
      child: Column(
        children: [
          if (provider.aviso != null) _AvisoBanner(mensagem: provider.aviso!),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.verificacoes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final verificacao = provider.verificacoes[index];
                return _VerificacaoCard(
                  verificacao: verificacao,
                  onTap: () =>
                      _abrirFormulario(context, verificacao: verificacao),
                  onExcluir: () => _confirmarExclusao(context, verificacao),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarExclusao(
    BuildContext context,
    Verificacao verificacao,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir verificação'),
        content: Text('Deseja excluir "${verificacao.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      await context.read<VerificacaoProvider>().excluir(verificacao);
    }
  }

  void _abrirFormulario(BuildContext context, {Verificacao? verificacao}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _VerificacaoFormSheet(verificacao: verificacao),
    );
  }
}

class _ErroView extends StatelessWidget {
  final String mensagem;
  final VoidCallback onTentarNovamente;

  const _ErroView({required this.mensagem, required this.onTentarNovamente});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(mensagem, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onTentarNovamente,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  final VoidCallback onAdicionar;

  const _EstadoVazio({required this.onAdicionar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fact_check_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary
                  .withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            const Text('Nenhuma verificação cadastrada'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdicionar,
              icon: const Icon(Icons.add),
              label: const Text('Nova verificação'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvisoBanner extends StatelessWidget {
  final String mensagem;

  const _AvisoBanner({required this.mensagem});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(mensagem, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

extension _StatusVisual on StatusVerificacao {
  Color get cor {
    switch (this) {
      case StatusVerificacao.aguardando:
        return const Color(0xFFB8860B);
      case StatusVerificacao.aprovado:
        return const Color(0xFF2E7D32);
      case StatusVerificacao.reprovado:
        return const Color(0xFFC62828);
    }
  }

  IconData get icone {
    switch (this) {
      case StatusVerificacao.aguardando:
        return Icons.schedule;
      case StatusVerificacao.aprovado:
        return Icons.check_circle;
      case StatusVerificacao.reprovado:
        return Icons.cancel;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final StatusVerificacao status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.cor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icone, size: 14, color: status.cor),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: status.cor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificacaoCard extends StatelessWidget {
  final Verificacao verificacao;
  final VoidCallback onTap;
  final VoidCallback onExcluir;

  const _VerificacaoCard({
    required this.verificacao,
    required this.onTap,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    final pendente = verificacao.syncStatus != SyncStatus.synced;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: verificacao.status.cor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    verificacao.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                                if (pendente)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Icon(
                                      Icons.sync,
                                      size: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _StatusChip(status: verificacao.status),
                            if (verificacao.motivo != null &&
                                verificacao.motivo!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                verificacao.motivo!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onExcluir,
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerificacaoFormSheet extends StatefulWidget {
  final Verificacao? verificacao;

  const _VerificacaoFormSheet({this.verificacao});

  @override
  State<_VerificacaoFormSheet> createState() => _VerificacaoFormSheetState();
}

class _VerificacaoFormSheetState extends State<_VerificacaoFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _motivoController;
  late StatusVerificacao _status;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.verificacao?.title);
    _motivoController = TextEditingController(text: widget.verificacao?.motivo);
    _status = widget.verificacao?.status ?? StatusVerificacao.aguardando;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _salvando = true;
      _erro = null;
    });

    final provider = context.read<VerificacaoProvider>();
    final motivo = _motivoController.text.trim().isEmpty
        ? null
        : _motivoController.text.trim();

    try {
      if (widget.verificacao == null) {
        await provider.criar(
          title: _titleController.text.trim(),
          status: _status,
          motivo: motivo,
        );
      } else {
        await provider.editar(
          widget.verificacao!,
          title: _titleController.text.trim(),
          status: _status,
          motivo: motivo,
        );
      }

      if (mounted) Navigator.pop(context);
    } on VerificacaoValidationException catch (e) {
      setState(() => _erro = e.message);
    } catch (_) {
      setState(() => _erro = 'Não foi possível salvar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.verificacao != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              editando ? 'Editar verificação' : 'Nova verificação',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Informe um título'
                  : null,
            ),
            const SizedBox(height: 20),
            SegmentedButton<StatusVerificacao>(
              showSelectedIcon: false,
              expandedInsets: EdgeInsets.zero,
              style: const ButtonStyle(
                padding: WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 4),
                ),
                visualDensity: VisualDensity.compact,
                minimumSize: WidgetStatePropertyAll(Size(0, 40)),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              segments: StatusVerificacao.values
                  .map(
                    (status) => ButtonSegment(
                      value: status,
                      label: Text(switch (status) {
                        StatusVerificacao.aguardando => 'Aguardando',
                        StatusVerificacao.aprovado => 'Aprovado',
                        StatusVerificacao.reprovado => 'Reprovado',
                      }, style: const TextStyle(fontSize: 13)),
                    ),
                  )
                  .toList(),
              selected: {_status},
              onSelectionChanged: (selecionados) {
                setState(() => _status = selecionados.first);
              },
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _status == StatusVerificacao.reprovado
                  ? Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: TextFormField(
                        controller: _motivoController,
                        decoration: const InputDecoration(labelText: 'Motivo'),
                        maxLines: 2,
                        validator: (value) {
                          if (_status == StatusVerificacao.reprovado &&
                              (value == null || value.trim().isEmpty)) {
                            return 'Motivo é obrigatório quando reprovado';
                          }
                          return null;
                        },
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            if (_erro != null) ...[
              const SizedBox(height: 12),
              Text(
                _erro!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _salvando ? null : _salvar,
                child: _salvando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salvar'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
