# Teste Técnico — Flutter

Desenvolva um aplicativo Flutter simples para gerenciamento de verificações.

## Objetivo

O aplicativo deverá possuir uma única tela que exibe uma lista de verificações obtidas de uma API. Também deve permitir criar, visualizar, editar e excluir verificações, com suporte a funcionamento offline.

## API

Base URL:

```text
https://gahjnpeomhmkengufdrb.supabase.co/rest/v1/teste_tecnico
```

A `apiKey` necessária para autenticação será enviada via WhatsApp. Todas as requisições devem incluir essa chave nos headers:

```http
apikey: SUA_API_KEY
Authorization: Bearer SUA_API_KEY
Content-Type: application/json
```

## Estrutura da verificação

Cada registro possui o seguinte formato:

```json
{
  "id": 1,
  "created_at": "2026-08-31T21:13:49.341778+00:00",
  "title": "teste",
  "status": 1,
  "motivo": null
}
```

### Status e regras de validação

Os únicos valores permitidos para `status` são:

| Status | Descrição |
|---:|---|
| `0` | Aguardando verificação |
| `1` | Aprovado |
| `2` | Reprovado |

Regras para o campo `motivo`:

- Quando `status` for `2` (**Reprovado**), o campo `motivo` é obrigatório.
- Quando `status` for `1` (**Aprovado**), o campo `motivo` não deve ser enviado ou deve ser `null`.
- Para `status` `0` (**Aguardando verificação**), o motivo não é obrigatório.

Essas validações devem ser aplicadas antes de salvar localmente e antes de enviar dados à API.

## Requisitos funcionais

- Exibir em uma única tela a lista de verificações.
- Buscar os dados da API ao iniciar o aplicativo.
- Implementar as operações CRUD:
  - Criar uma verificação;
  - Listar verificações;
  - Editar uma verificação;
  - Excluir uma verificação.
- Exibir estados apropriados de carregamento, lista vazia e erro.
- Atualizar a interface após cada operação realizada.

## Gerenciamento de estado

Utilize o pacote `provider` para gerenciar o estado da tela.

A solução deve manter, de forma clara e organizada, os estados de lista, carregamento, erros e operações pendentes de sincronização.

## Suporte offline

Utilize `sqflite` para persistência local.

Quando o dispositivo estiver sem conexão:

- As verificações e alterações devem ser salvas localmente;
- Criações, edições e exclusões devem ficar pendentes de sincronização;
- A aplicação deve continuar exibindo os dados disponíveis localmente.

Quando a conexão for restabelecida:

- As operações pendentes devem ser enviadas para a API;
- Após a sincronização, os dados locais devem refletir o estado mais recente da API;
- Falhas na sincronização devem ser tratadas sem perda dos dados locais.

## Comunicação com a API

| Operação | Método | Endpoint |
|---|---:|---|
| Listar | `GET` | `/teste_tecnico` |
| Criar | `POST` | `/teste_tecnico` |
| Atualizar | `PATCH` | `/teste_tecnico?id=eq:{id}` |
| Excluir | `DELETE` | `/teste_tecnico?id=eq:{id}` |

Para operações de criação e atualização, envie os dados no formato JSON.

## Encoding e decoding

A aplicação deve tratar corretamente a conversão dos dados entre API, banco local e interface:

- Decodificar respostas JSON em modelos Dart;
- Codificar modelos Dart em JSON para envio à API;
- Tratar corretamente campos nulos, datas em ISO 8601 e caracteres especiais;
- Persistir e recuperar os dados do SQLite sem corrupção de encoding.

## Organização esperada

```text
lib/
├── models/
│   └── verificacao.dart
├── services/
│   ├── api_service.dart
│   └── database_service.dart
├── providers/
│   └── verificacao_provider.dart
├── screens/
│   └── verificacoes_screen.dart
└── main.dart
```

## Critérios de avaliação

- Funcionamento correto do CRUD e das regras de status;
- Uso adequado do `provider`;
- Persistência local com `sqflite`;
- Sincronização de operações pendentes quando houver conexão;
- Organização e legibilidade do código;
- Tratamento de erros e estados da interface;
- Qualidade na conversão de dados entre JSON, Dart e SQLite.
