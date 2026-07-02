# label_serialization

Codec entre o formato `.label` (JSON) e `LabelDocument`, com pipeline de migração versionada (Chain of Responsibility). Ver [docs/ARCHITECTURE.md](../../docs/ARCHITECTURE.md), seção 12.

Não lê nem escreve arquivos — apenas converte `String`/`Map` ⇄ `LabelDocument`. A leitura/escrita em disco é responsabilidade do projeto que consome o framework (mantém o pacote utilizável em Flutter Web).

## Uso

```dart
const codec = LabelDocumentCodec();

final json = codec.encode(document);       // LabelDocument -> String
final document = codec.decode(json);       // String -> LabelDocument (migra se necessário)
```

Para suportar uma versão antiga do schema, implemente `LabelDocumentMigration` e registre-a em `defaultMigrations` (`lib/src/migrations/migrations.dart`) — nenhum outro ponto do código precisa mudar.

## Testes

```
dart test
```
