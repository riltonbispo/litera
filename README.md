# Litera

Catálogo coletivo de leituras. Cada usuário cadastra os livros que leu; o catálogo é público e
compartilhado, e ninguém vê os cadastros dos outros como editáveis. A busca de metadados é
integrada com a [OpenLibrary](https://openlibrary.org), com cadastro manual como alternativa.

## Funcionalidades

- Busca por título na OpenLibrary com título, autor, ano, gênero e capa pré-preenchidos.
- Cadastro 100% manual quando a busca não serve, inclusive quando a OpenLibrary está fora do ar.
- Catálogo público com paginação, ordenado do mais recente para o mais antigo.
- Filtros por autor (parcial, sem diferenciar maiúsculas de minúsculas), gênero e ano.
- Controle de duplicidade por usuário: o mesmo usuário não repete o mesmo livro.
- Edição e remoção restritas ao dono do cadastro, via Pundit.
- Feedback de erro por campo e mensagens de sucesso em toast.

## Stack

| Camada | Tecnologia | Versão |
|---|---|---|
| Linguagem | Ruby | 4.0.5 |
| Framework | Rails | 8.1.4 |
| Banco | PostgreSQL (Docker/CI) · SQLite (local) | 16-alpine · 3.x |
| Assets | Vite + vite_ruby | 8.3.1 · 3.11.1 |
| Camada SPA | Inertia.js | 3.7.1 (cliente) · 3.22.0 (gem) |
| Frontend | React + TypeScript | 19.3.0 · 7.0.2 |
| UI | shadcn/ui sobre Radix + Tailwind CSS | radix-ui 1.6.7 · Tailwind 4.3.3 |
| Autenticação | Devise | 5.0.4 |
| Autorização | Pundit | 2.5.2 |
| Paginação | Kaminari | 1.2.2 |
| Cliente HTTP | Faraday | 2.14.4 |
| Testes | RSpec + WebMock + SimpleCov | 8.0.4 · 3.26.4 |

## Como rodar

### Com Docker (caminho verificado)

```bash
cp .env.example .env        # opcional: o repositório já traz um .env equivalente
docker compose up --build
```

| Serviço | URL |
|---|---|
| Aplicação | http://localhost:3100 |
| Vite (HMR) | http://localhost:3036 |
| PostgreSQL | `localhost:5433` |

O `bin/docker-entrypoint` executa `bin/rails db:prepare` antes de subir o Puma, então o schema é
criado no primeiro boot sem passo manual. Não há seed: **o primeiro uso exige criar uma conta** em
`/users/sign_up`.

[CONFIRMAR: não existe `db/seeds.rb` com dados de exemplo. Quer que eu adicione um usuário e alguns
livros de demonstração para facilitar a avaliação do desafio?]

### Rodando os testes, lint e typecheck

```bash
# Docker — forma verificada
docker compose exec -T app bundle exec rubocop
docker compose exec -T app npm run check

docker compose exec -T -e RAILS_ENV=test \
  -e DATABASE_URL=postgres://litera:litera_password@postgres:5432/litera_test \
  app bash -lc './bin/rails db:prepare && bundle exec rspec'
```

> **Atenção:** os dois `-e` são obrigatórios. O `docker-compose.yml` define `RAILS_ENV=development`,
> então `docker compose exec app bundle exec rspec` roda a suíte contra o banco de desenvolvimento e
> falha. E trocar apenas o `RAILS_ENV` resolve para `RAILS_ENV=test` com
> `DATABASE_URL=…/litera_development`, ou seja, a suíte passa a rodar `maintain_test_schema!`
> sobre o banco de desenvolvimento. Passe sempre os dois.

### Sem Docker (SQLite local)

```bash
bin/setup                 # bundle install, npm install, db:prepare, sobe o servidor
# ou, em outro terminal:
bundle exec rspec
bundle exec rubocop
npm run check             # tsc -p tsconfig.app.json && tsc -p tsconfig.node.json
```

`bin/dev` sobe Vite e Rails juntos via `Procfile.dev` (usa `overmind`, `hivemind` ou `foreman`).

## Arquitetura

O backend é a fonte da verdade: nenhuma regra de negócio — duplicidade, autorização, validação,
normalização de texto — existe no React. O React cuida de estado de formulário, fetch da API de
busca e renderização.

```
app/
├── controllers/
│   ├── application_controller.rb        # compartilha auth e flash; helper inertia_errors
│   ├── books_controller.rb             # CRUD, orquestra policy + query object + serializer
│   ├── book_searches_controller.rb     # API JSON da OpenLibrary (rate limited)
│   └── users/                          # controllers Devise customizados (sessions, registrations)
├── models/book.rb                      # validações, normalização, regra de duplicidade
├── policies/book_policy.rb             # autorização Pundit + Scope público
├── queries/
│   ├── book_filter.rb                  # filtros de autor/gênero/ano + ordenação
│   └── book_filter_options.rb          # facetas de gênero e ano para os selects
├── serializers/book_serializer.rb      # shape público do livro (inclui can_edit)
├── services/open_library/              # único lugar que fala com a API externa
└── frontend/
    ├── pages/                          # uma página por rota Inertia
    ├── components/books/               # BookCard, BookFilters
    ├── components/layout/AppLayout.tsx # header + Toaster + flash → toast
    ├── components/ui/                  # componentes shadcn
    ├── lib/errors.ts                   # leitura de erro de registro (base)
    └── types/index.ts                  # PageProps, Book, BookFilters, OpenLibrary*
```

**Props e tipos compartilhados.** O controller monta `props` com chaves snake_case; `app/frontend/types/index.ts`
declara o contrato correspondente (`Book`, `BookFilters`, `Pagination`, `OpenLibraryResult`). É a
única fronteira manual entre Ruby e TypeScript — não há geração de tipos.

**Errors e Inertia.** `inertia_rails` não deriva o prop `errors` do model. `ApplicationController#inertia_errors`
achata e prefixa as chaves (`"book.title"`, `"user.base"`), sem o que o cliente do Inertia trata um
422 como sucesso e nenhum erro de campo aparece. Ver `ai-notes.md`.

**flash.** `ApplicationController` compartilha `flash.notice`/`flash.alert` em todas as respostas;
`AppLayout` é o único ponto que os transforma em toast, o que evita mensagem duplicada.

### Fluxo de cadastro

```mermaid
sequenceDiagram
    autonumber
    actor U as Usuário
    participant N as Books/New.tsx
    participant S as BookSearchesController
    participant OL as OpenLibrary
    participant C as BooksController
    participant DB as PostgreSQL

    U->>N: digita o título (debounce 400 ms)
    N->>S: GET /book_search.json?title=…&limit=5
    Note over S: exige ≥ 2 caracteres<br/>rate limit 30/min por usuário
    S->>OL: GET /search.json (timeout 2s)
    alt sucesso
        OL-->>S: { docs: [...] }
        S-->>N: { results, status: "ok" }
        U->>N: seleciona um resultado
        Note over N: pré-preenche título, autor,<br/>ano, gênero, key e cover_id
    else vazio / timeout / indisponível
        OL-->>S: erro
        S-->>N: { results: [], status: { code, message } }
        Note over N: alerta explicativo;<br/>usuário preenche à mão
    end

    U->>N: Confirmar
    N->>C: POST /books
    C->>C: authorize @book (Pundit)
    C->>DB: INSERT books
    alt salvo
        DB-->>C: ok
        C-->>N: 303 → /books (flash notice)
        N->>N: toast de sucesso
    else duplicado / inválido
        C-->>N: 422 + errors["book.*"]
        N->>N: erros por campo + alerta de registro
    end
```

## Decisões técnicas

### a) Livro duplicado

**Decisão.** Um usuário não cadastra o mesmo livro duas vezes. A identidade do livro é
`(user_id, lower(title), lower(author), first_publish_year)` — dois usuários diferentes podem
cadastrar o mesmo livro livremente. Títulos e autores comparam sem diferenciar maiúsculas de
minúsculas; o ano é exato e anos nulos são normalizados com `COALESCE(…, -1)`.

**Alternativas.** (1) Índice único global em `(lower(title), lower(author), ano)` — impediria duas
pessoas com o mesmo livro no catálogo, o que contraria um catálogo coletivo. (2) Dois índices
parciais, um para cadastros vindos da OpenLibrary (`open_library_key` presente) e outro para os
manuais. (3) Sem índice, só validação em Ruby.

**Justificativa.** O catálogo é coletivo, então a restrição precisa ser por usuário, não por livro.
O par (validação + índice) foi escolhido porque cada um cobre uma falha do outro: a validação
devolve mensagem de erro por campo, o índice garante a invariante.

**Trade-off.** A validação é um `SELECT` e não enxerga insert concorrente, então duas requisições
simultâneas para o mesmo livro podem passar as duas. O índice funcional único
(`db/migrate/…_create_books.rb`) é o que fecha a janela, e o `RecordNotUnique` do perdedor é
convertido no mesmo erro de `:base` — sem isso, a corrida viraria 500. O custo é um `LOWER()` por
comparação, impagável no volume esperado.

**Nuance.** O ano entra na identidade: "Dom Casmurro" (1899) e "Dom Casmurro" (1900) coexistem
para o mesmo usuário. Isso é consequência de a regra ser por obra, não por título/autor.

[CONFIRMAR: você descreveu a regra como "o mesmo usuário não repete o livro". O código inclui o
ano na identidade, então um mesmo título/autor com anos diferentes passa. Era a intenção, ou a
regra deveria ser só por título+autor?]

### b) OpenLibrary indisponível ou resposta vazia

**Decisão.** A integração é opcional. A tela de cadastro sempre nasce com os campos vazios e
editáveis, e o usuário pode digitar tudo à mão. Falha da OpenLibrary nunca bloqueia o cadastro:
vira um `Alert` com código e mensagem, e a mão fica liberada.

**Alternativas.** (1) Falhar o cadastro quando a busca não resolve. (2) Tornar os campos da
OpenLibrary somente-leitura. (3) Cachear respostas bem-sucedidas para degradar com elegância.

**Justificativa.** O serviço é de terceiros e não tem SLA. O `Client` usa timeouts curtos (2 s de
leitura, 1 s de conexão) e converte tudo em `OpenLibrary::Error` com um código estável
(`timeout`, `unavailable`, `server_error`, `invalid_response`, `empty_results`) e uma mensagem já
em português que o front exibe diretamente. Campos ausentes na resposta viram `nil`/`[]` em vez de
erro, e o `timeout` de conexão é distinguido de "OpenLibrary fora do ar" por mensagem da exceção e
`Timeout::Error` na causa.

**Trade-offs.** (1) Não há cache: cada busca é uma chamada real, e o rate limit de 30/min por
usuário é o que protege a API externa e o app. (2) Não há circuit breaker: em uma indisponibilidade
prolongada o usuário vê a mensagem a cada tentativa, o que é honesto e simples de entender. (3) O
endpoint rejeita títulos com menos de 2 caracteres antes de chamar a API, mas a busca no front ainda
é feita a cada pausa de digitação.

### c) Nível de acesso ao `/books.json`

**Decisão.** O endpoint é **público e paginado**, igual à página HTML. `BookPolicy#index?` retorna
`true` mesmo para visitante, e `BookPolicy::Scope#resolve` devolve `scope.all`. A paginação é
obrigatória (`per_page` padrão 10, teto 50).

**Alternativas.** (1) Exigir autenticação — o navegador mostraria 401 para visitante anônimo, o que
quebra a proposta de catálogo compartilhado. (2) Devolver apenas os livros do visitante. (3) Manter
o escopo público no HTML e restringir o JSON.

**Justificativa.** Um catálogo coletivo que exige login para ser lido não é coletivo. O que é
privado é a *edição*, e isso é garantido por `can_edit` no serializer e por `authorize` em
`edit`/`update`/`destroy`. O JSON público não inclui e-mail nem associação `user` — só `owner_id`
— e isso é fixado em spec.

**Trade-offs.** (1) O `owner_id` é público: qualquer um pode enumerar e correlacionar cadastros.
Aceito porque o catálogo é público por definição. (2) `policy_scope(Book)` retornando `scope.all`
pode parecer um vazamento para quem lê rápido; a decisão está documentada em spec, não em comentário.
(3) `BookPolicy#show?` retorna `true` mas não existe action `show` — código morto.

### Autenticação

Devise com `:database_authenticatable, :registerable, :recoverable, :rememberable, :validatable`.
Dois controllers foram customizados porque o Devise renderiza views ERB e o app é Inertia:
`Users::SessionsController` e `Users::RegistrationsController`.

**Trade-off.** `:recoverable` gera 6 rotas de senha apontando para controllers Devise padrão, e
`app/views/devise` não existe — acessá-las dá 500. Nenhum link da UI aponta para lá, então é
latente. Fica em "Com mais tempo".

### Pundit

Toda autorização passa por policy; não há `if/else` de usuário no controller nem no React. A
consulta do índice usa `policy_scope`, e o serializer calcula `can_edit` chamando a policy, o que
mantém a regra em um lugar só. `update?`/`destroy?` exigem `record.user_id == user.id`.

### Inertia + shadcn/ui

Inertia v3 no cliente e `inertia_rails` 3.22, com `always_include_errors_hash = true` para que toda
resposta traga `errors`. Hotwire foi removido por completo (importmap, Turbo e Stimulus), e há um
spec (`spec/requests/inertia_stack_spec.rb`) que falha se qualquer um voltar a aparecer no shell.

A UI é shadcn/ui sobre Radix + Tailwind 4, com os tokens do tema (`bg-card`, `text-muted-foreground`,
`text-destructive`) e sem cor hardcoded. Vite e Rails rodam como processos separados
(`docker-compose.yml`), que é o que permite HMR sem reconstruir a imagem.

**Trade-off.** O `Button` do shadcn é usado com `asChild` para renderizar `Link` do Inertia. É o
caminho idiomático, mas exige cuidado: `asChild` com `type="button"` num `<a>` produz
`type="button"` inválido no anchor.

### Gênero como campo livre

**Decisão.** `genre` é uma string livre, obrigatória, com sugestões. Hoje a sugestão é um
`<datalist>` nativo do browser alimentado pelos gêneros **que já existem no banco**
(`BookFilterOptions`), e o filtro é um `Select` do shadcn.

[CONFIRMAR: você descreveu "gênero como campo livre com **combobox shadcn** e **sugestões curadas em
português**, sem migrar dados existentes". O código não tem combobox (não existe componente
`Combobox` em `components/ui/` e `git log -S Combobox` não retorna nada) e as sugestões não são
curadas nem em português: vêm de `subjects[0]` da OpenLibrary, que é em inglês ("Fiction",
"Fantasy"). Descrevi o que existe. Implemento o combobox com taxonomia curada, ou ajusto o README?]

**Alternativas.** (1) Tabela `genres` com FK — modela a taxonomia, mas exige seeding, migração de
dados existentes e uma tela de administração. (2) Enum — rigidiza demais para dado vindo de
terceiro. (3) Campo livre puro, sem sugestão.

**Justificativa.** A fonte do dado é a OpenLibrary, cuja taxonomia é aberta e varia por edição. Um
campo livre com sugestão reduz o atrito sem criar um problema de migração.

**Trade-off.** O agravante real é o idioma: o gênero entra em inglês e o filtro fica em inglês numa
UI em português. Não há dicionário de tradução nem curadoria.

### Paginação

Kaminari com `per_page` padrão 10 e teto 50, normalizando parâmetros inválidos (`page` negativo vai
para 1, `per_page` acima do teto é limitado). A ordenação é `created_at DESC, id DESC` — o `id`
desempata, tornando a ordem total e o `OFFSET` estável entre páginas. O componente de paginação
mostra no máximo 7 itens com elipses, independentemente do tamanho do catálogo.

**Trade-off.** `OFFSET` degrada em profundidade. Com o volume de um desafio, `keyset pagination`
seria complexityidade sem retorno.

### Testes com WebMock

`WebMock.disable_net_connect!(allow_localhost: true)` em `spec/support/webmock.rb`: nenhum teste
faz HTTP real. A OpenLibrary é testada por status (200 com docs, 200 vazio, 200 com corpo inválido,
4xx, 5xx, timeout, conexão recusada) e o contrato é verificado tanto no service quanto na request.

### Docker

Imagem única com estágios `node` e `ruby`, `bundle install` e `npm ci` em camadas antes do código,
`jemalloc` via `LD_PRELOAD`. Três serviços: `postgres`, `vite` e `app`. O entrypoint roda
`db:prepare`. Healthcheck do Postgres com `pg_isready`.

**Trade-off.** `docker compose up --build` leva alguns minutos na primeira vez (`bundle install` +
`npm ci`); iterações seguintes aproveitam o cache de camadas. Em desenvolvimento, o workflow é
`bin/setup` + `bin/dev` com SQLite, que é mais rápido para quem não precisa do Postgres.

## Testes

101 exemplos, 14 arquivos, sem HTTP real.

| Área | Arquivo | O que cobre |
|---|---|---|
| Model | `spec/models/book_spec.rb` | presença, normalização de texto, ano numérico e não-futuro, `cover_id`, duplicidade (inclusive auto-atualização) |
| Model | `spec/models/user_spec.rb` | Devise |
| Policy | `spec/policies/book_policy_spec.rb` | catálogo público, criação autenticada, edição só do dono, Scope |
| Policy | `spec/policies/application_policy_spec.rb` | defaults |
| Query | `spec/queries/book_filter_spec.rb` | filtros, escape de `%`/`_`, ano inválido, ordem total, filtros aplicados |
| Query | `spec/queries/book_filter_options_spec.rb` | facetas distintas e ordenadas, respeitando o escopo |
| Serializer | `spec/serializers/book_serializer_spec.rb` | shape público, `can_edit`, `cover_url` |
| Request | `spec/requests/books_index_spec.rb` | acesso anônimo, paginação, normalização de params, filtros, JSON sem e-mail |
| Request | `spec/requests/books_create_spec.rb` | criação, erros por campo, duplicidade, corrida de insert |
| Request | `spec/requests/books_manage_spec.rb` | update/destroy, IDOR (não-dono), JSON 403, flash |
| Request | `spec/requests/auth_spec.rb` | sign up, sign in, sign out, erros de registro |
| Request | `spec/requests/book_searches_spec.rb` | normalização, timeouts, vazio, título curto, rate limit |
| Request | `spec/requests/inertia_stack_spec.rb` | shell Inertia e ausência de Turbo/Stimulus/importmap |
| Service | `spec/services/open_library/search_spec.rb` | mapeamento, campos ausentes, todos os erros do client |

**Cobertura.** SimpleCov com branch coverage, relatório em `coverage/index.html`:
**97,47% de linhas e 86,66% de branches** (`cover "app/**/*.rb"`, excluindo `bin/`, `config/` e `spec/`).

```bash
bundle exec rspec                     # local, SQLite
bundle exec rspec spec/requests/      # só requests
```

Não há suíte de testes de frontend (sem Vitest/Jest). A lógica de janela da paginação e o helper de
`baseError` são os pontos de frontend mais passíveis de regressão.

## Com mais tempo

Cada item abaixo é uma lacuna real encontrada no código, com o motivo da priorização.

1. **Taxonomia de gênero em português.** Hoje o gênero entra em inglês direto da OpenLibrary
   (`subjects[0]`) numa UI em português, e o `<datalist>` só sugere o que já existe no banco.
   Adiei porque curadoria e migração de dados são trabalho de produto, não de código: exige decidir
   a lista, mapear o que já está gravado e tratar o que não tiver tradução. O
   [CONFIRMAR] do item "Gênero" lista as opções.
2. **Suíte de testes de frontend.** Não existe. Adiei porque não há um runner no projeto e adicionar
   Vitest traz uma dependência nova; a cobertura de frontend está hoje a cargo de revisão e do
   typecheck. Custo real: a janela da paginação entrou sem teste automatizado.
3. **Recuperação de senha.** `:recoverable` está habilitado e as 6 rotas resultantes dão 500, porque
   `app/views/devise` não existe. Adiei porque é uma feature (duas páginas + controller + views de
   e-mail), não um bug, e nada na UI aponta para lá.
4. **Cache das consultas à OpenLibrary.** Não há cache. Adiei porque o rate limit já limita o dano e
   cachear resposta de terceiro introduz invalidação sem benefício no volume esperado.
5. **Logging estruturado.** Não há `lograge` nem equivalente; o log é o padrão do Rails. Adiei
   porque não havia requisito de observabilidade, e adicionar uma gem de logging é decisão de
   operação, não de aplicação.
6. **CI desalinhado do typecheck.** `.github/workflows/ci.yml:54` roda `npx tsc --noEmit`, que é mais
   frouxo que o `npm run check` do `package.json` — foi exatamente por isso que erros de tipo
   entraram no repositório (ver `ai-notes.md`). [CONFIRMAR: corrijo o workflow?]
7. **`config/ci.rb` desatualizado.** Roda `bin/rails test` e `db:seed:replant`, boilerplate de
   Minitest, num projeto que usa RSpec; `bin/ci` está na prática quebrado e o CI real é o GitHub
   Actions. [CONFIRMAR: corrijo ou removo `bin/ci`?]
8. **`components.json` desalinhado.** Aponta `utils` para `@/lib/utils`, arquivo removido no commit
   `ed1b172`. O próximo `npx shadcn add` recriaria um `cn` divergente do import direto que os 13
   componentes fazem. [CONFIRMAR: corrijo?]
9. **Recuperação de `RecordNotUnique` no modelo.** Hoje o `rescue` está nos dois actions do
   controller. Um `Book.save` chamado de outro lugar não teria a mesma proteção.
10. **Mensagens de validação em inglês.** `"can't be blank"`, `"is not a number"` e
    `"Book already exists in your catalog"` numa UI em português. Adiei por decisão registrada em
    revisão anterior.
11. **Acentuação ausente na UI.** "Titulo", "Genero", "Voce nao tem permissao". Cosmético; adiei para
    não poluir os commits de correção.

## Uso de IA

[CONFIRMAR: a atribuição abaixo (Codex como agente de implementação com `AGENTS.md` e prompts por
fase; Claude no planejamento e na revisão) vem de você, não do repositório — o git log registra
autoria e mensagens, não qual modelo escreveu cada linha.]

O `AGENTS.md` do repositório define as regras do projeto (Rails, Inertia, shadcn/ui, Pundit, RSpec
com WebMock, TypeScript estrito) e funciona como contrato para o agente. O trabalho foi dividido em
fases prompts curtos, com revisão e teste manual entre elas. **Sou responsável por todo o código
entregue**: revisei cada fase, rodei a suíte e o typecheck, e descartei sugestões que não se
sustentavam.

O registro detalhado está em [`ai-notes.md`](./ai-notes.md). Resumo dos erros que a IA cometeu e que
precisei corrigir:

1. **Deixou o Hotwire do boilerplate ativo ao lado do Inertia** — a navegação client-side para
   `/books?page=2` deixava a tela em branco. Detectei pelos headers `x-turbo-request-id` e
   `x-sec-purpose: prefetch` na aba Network. Correção: remover importmap, Turbo e Stimulus e
   cobrir com spec.
2. **Ao remover o Turbo, consertou a navegação da paginação no lugar errado** — o wrapper
   `PaginationNavLink` com `Link` do Inertia resolveu o recarregamento, mas ficou em
   `Books/Index.tsx` duplicando o componente do shadcn, e `data-active={isActive}` passou a renderizar
   `data-active="false"` (React stringifica boolean em `data-*`). Correção: corrigir
   `components/ui/pagination.tsx` e apagar a cópia.
3. **Renderizou o formulário sem `errors` no 422** — o `POST /books` devolvia 422 com `errors: {}`, o
   front disparava `onSuccess` e mostrava "Livro cadastrado com sucesso" mesmo com falha de
   duplicidade. Correção: helper `inertia_errors` + specs que falhavam antes.
4. **Repetiu o mesmo bug no cadastro de conta** — `Users::RegistrationsController` também renderizava
   422 sem `errors`, e como a página de registro não tem toast, o erro era totalmente silencioso.
   Descobri ao revisar, meses de commits depois. [CONFIRMAR: descrevo aqui ou movo para uma seção
   de revisão posterior?]
5. **Verificou o typecheck com o comando errado** — reportou "tsc OK" usando `tsc --noEmit`, que é
   mais frouxo que o `npm run check` do projeto, e assim deixou 12 erros de tipo entrarem em três
   commits. Só percebi quando rodei o script de verdade.

[ai-notes.md](./ai-notes.md) traz cada incidente com contexto, como foi detectado, a correção e o
aprendizado.
