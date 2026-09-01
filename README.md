# Gerenciador de Verificações

App Flutter feito pro teste técnico da Construmarket: uma tela só, pra criar, ver, editar e excluir "verificações", com suporte a uso offline.

## Como rodar

1. `flutter pub get`
2. Cria um arquivo `.env` na raiz do projeto (usa o `.env.example` como base) e cola a apiKey que você me mandou
3. `flutter run`

## Decisões sobre persistência local

Uso o `sqflite` com uma tabela só (`verificacoes`), com uma coluna a mais que não existe na API: `sync_status`. Ela guarda se aquele registro está `synced` (igual ao que tem no servidor) ou `pendingCreate` / `pendingUpdate` / `pendingDelete` (uma alteração feita offline que ainda não foi enviada).

Cheguei a pensar numa tabela separada só pra fila de sincronização, mas achei desnecessário pro tamanho desse projeto (uma entidade só). Com a coluna direto na tabela principal já dá pra saber o que está pendente sem duplicar dado em lugar nenhum.

## Decisões sobre sincronização offline

Toda vez que crio, edito ou excluo alguma verificação, salvo local primeiro (marcando como pendente) e já tento mandar pra API na hora. Se der certo, o status vira `synced`. Se não der (sem internet, erro da API, etc.), o registro fica pendente e não perde o dado — a tela continua mostrando o que já está salvo localmente.

Também fico escutando a conexão do aparelho (pacote `connectivity_plus`). Quando percebe que a internet voltou, o app tenta sincronizar os pendentes de novo sozinho, sem o usuário precisar fazer nada.

Se um item pendente falhar ao sincronizar, os outros continuam tentando — não trava a fila inteira por causa de um só.

## O que eu melhoraria com mais tempo

- Testes automatizados pra `database_service` e `api_service` — não fiz porque exigiria trazer dependências novas (mock/fake DB) só pra isso, e preferi manter o projeto enxuto
- Tratar conflito de verdade quando o mesmo registro muda local e no servidor ao mesmo tempo — hoje, quem sincroniza primeiro "ganha"
