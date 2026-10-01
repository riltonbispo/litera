# ai-notes.md

Registro cronológico dos erros e correções no uso de IA neste projeto. A ideia é deixar registrado
o que a IA fez de errado, como eu percebi e o que mudou na prática depois de cada incidente.

Cada entrada segue o formato: **Fase/contexto · O que a IA sugeriu ou fez · Problema (como foi
detectado) · Correção · Aprendizado**.

O que é verificável no repositório está confirmado em commit, arquivo ou linha. O que é memória de
processo — especialmente o incidente 5 — está marcado como `[CONFIRMAR]`, porque não existe rastro
em nenhum arquivo.

---

## Incidente 1 — Hotwire do boilerplate ficou ativo ao lado do Inertia

**Fase/contexto.** Migração do boilerplate do Rails para Inertia. O app passou a servir as páginas
via `render inertia:` e `createInertiaApp`, mas o `application.js` gerado pelo Rails continuava no
layout, importando Turbo e Stimulus por importmap.

**O que a IA sugeriu ou fez.** Adotou Inertia como camada de navegação e não desativou os
assets JavaScript que já estavam no projeto. O resultado foi duas camadas de navegação concorrentes:
Inertia fazendo o roteamento client-side e o Turbo interceptando os mesmos cliques.

**Problema (como foi detectado).** Navegar client-side para `/books?page=2` deixava a tela em branco;
só o F5 trazia o conteúdo de volta. Eu inspecionei a aba Network no DevTools e os requests de
navegação saíam com `x-turbo-request-id` e `x-sec-purpose: prefetch` — headers do Turbo — em vez dos
headers `X-Inertia` que o app deveria estar usando. O commit `3eac009` ("fix: remove hotwire, use
inertia only") remove `config/importmap.rb`, `bin/importmap`,
`app/javascript/entrypoints/application.ts`, `app/javascript/controllers/hello_controller.js` e as
gemas `turbo-rails` e `stimulus-rails` do `Gemfile`.

**Correção.** Remoção completa do Hotwire e adição de `spec/requests/inertia_stack_spec.rb`, que
falha se `javascript_importmap_tags`, `type="importmap"`, `@hotwired/turbo`, `@hotwired/stimulus` ou
`data-turbo-track` reaparecerem no shell HTML. O spec é o que garante que o problema não volta em
silêncio.

**Aprendizado.** Trocar de framework de front não é uma substituição de arquivo: o boilerplate do
Rails instala uma camada de navegação que continua funcionando até ser removida explicitamente, e as
duas competem pelo mesmo clique. O detalhe que resolveu o diagnóstico foi olhar **headers**, não
console — a tela em branco sozinha não distingue "JS quebrou" de "outra biblioteca interceptou".

---

## Incidente 2 — Conserto da paginação no lugar errado, e `data-active="false"`

**Fase/contexto.** Consequência direta do incidente 1: removido o Turbo, a paginação do shadcn passou
a recarregar a página inteira, porque `PaginationLink` renderiza uma `<a>` comum.

**O que a IA sugeriu ou fez.** Criou um wrapper `PaginationNavLink` dentro de
`app/frontend/pages/Books/Index.tsx` que trocava a `<a>` pelo `Link` do Inertia. A navegação voltou a
funcionar, mas o wrapper ficou na página, não no componente. O commit `689bd7e` ("fix: restore
pagination styles with inertia link") toca apenas `Books/Index.tsx` (+27/−8) e confirma isso: o
`components/ui/pagination.tsx` original ficou intacto.

Dois defeitos ficaram no código como resultado:

1. **Duplicação.** `Books/Index.tsx` passou a ter sua própria cópia do componente do shadcn, com um
   tipo escrito à mão (`VariantProps<typeof buttonVariants> & Omit<ComponentProps<typeof Link>, …>`).
   O componente original continuava usando `<a>` — ou seja, a navegação sem reload estava *só* na
   página, e o shadcn continuava "quebrado" para quem usasse o componente.
2. **`data-active={isActive}`.** React converte boolean em string em atributos `data-*`, então as
   páginas inativas saíam com `data-active="false"` — o atributo presente, com valor `"false"`.
   Qualquer seletor CSS `[data-active]` casaria com todas as páginas, ativas e inativas. Era o que o
   shadcn upstream gerava, então passou despercebido.

**Problema (como foi detectado).** Revisando o histórico depois do incidente 1, notei que o conserto
estava em `Books/Index.tsx` enquanto o `pagination.tsx` do shadcn seguia com `<a>`. A duplicação só
ficou evidente ao procurar por outros usos do componente. O `data-active` apareceu na leitura do
código, ao perceber que a expressão produzia uma string.

**Correção.** Commit `183b484`: o `PaginationLink` do `components/ui/pagination.tsx` passou a
navegar pelo `Link` do Inertia, o `PaginationNavLink` duplicado foi apagado, e `data-active` passou a
ser `isActive ? "" : undefined`. No mesmo commit, a paginação deixou de renderizar um link por página
(`Array.from({ length: meta.total_pages })`, que num catálogo de 500 livros geraria 500 nós) e passou
a usar uma janela com elipses, no máximo 7 itens.

**Aprendizado.** Quando um bug é corrigido **no consumidor** em vez de **no componente**, o bug
continua existindo para qualquer outro consumidor — e o diff fica menor e mais rápido de revisar, o
que é justamente o risco. Corrigir componente shadcn gera mais ruído no diff, então a tentação é
contornar na página; a checagem é "este shadcn está em uso em outro lugar do projeto?".

---

## Incidente 3 — 422 sem `errors`: falha de cadastro anunciada como sucesso

**Fase/contexto.** Fluxo de cadastro manual de livro, com o usuário já autenticado.

**O que a IA sugeriu ou fez.** `BooksController#create` renderizava de volta o formulário Inertia com
status 422, mas sem o prop `errors`:

```ruby
render inertia: "Books/New", props: form_options, status: :unprocessable_entity
```

**Problema (como foi detectado).** Eu tentei cadastrar um livro que já estava na biblioteca e, apesar
do backend recusar corretamente, a telashow "Livro cadastrado com sucesso.". O mesmo aconteceu ao
digitar letras no campo Ano.

A causa é um detalhe do `inertia_rails`: ele **não** deriva o prop `errors` a partir do model. Sem
esse prop, a resposta chega com `errors: {}`. E o cliente do Inertia só chama `onError` quando o
objeto de erros é não-vazio
(`node_modules/@inertiajs/core/dist/index.js:2511`, `Object.keys(errors).length > 0`), então um 422
era tratado como sucesso. Confirmei empiricamente antes de corrigir: um spec que esperava
`inertia.props[:errors]` recebia `{}`.

**Correção.** Commit `e25c8a5`: `ApplicationController#inertia_errors(record, scope:)` achata e
prefixa as chaves (`"book.title"`, `"book.base"`) e o controller a envia no 422. Como o erro de
duplicidade é adicionado em `:base` e não é um campo, `New.tsx` e `Edit.tsx` passaram a exibi-lo em um
`Alert` — o que exigiu um helper (`app/frontend/lib/errors.ts`) porque o tipo `FormDataErrors` do
Inertia só modela os campos do formulário. Três specs novos que **falhavam antes** da correção
travam o contrato.

**Aprendizado.** Um 422 é apenas um código HTTP; para o Inertia ele é "sucesso com erros" e, sem
erros, é sucesso puro. O sintoma — toast de sucesso numa falha — não aponta para o controller, e sim
para o **contrato de props**. Regra que passei a aplicar: toda action que renderiza de volta em 422
precisa enviar `errors`, e isso merece spec.

---

## Incidente 4 — O mesmo bug, duplicado, no cadastro de conta

**Fase/contexto.** Revisão de código feita depois que o incidente 3 já estava corrigido, em busca de
bugs da mesma família.

**O que a IA sugeriu ou fez.** Ao corrigir `BooksController`, a.search por outros `render inertia:`
com 422 encontrou `Users::RegistrationsController#create`, que tinha exatamente o mesmo defeito. E
pior: a página de registro **não tem toast nenhum**, porque desde o começo ela dependia só do flash
do servidor — que num 422 não existe.

**Problema (como foi detectado).** Na leitura de `app/controllers/users/registrations_controller.rb`
durante a revisão. Confirmei executando: `POST /users/sign_up` com e-mail já cadastrado devolvia
`422` com `errors: {}` e sem flash — ou seja, **nenhum feedback whatsoever**. O usuário clicava em
"Cadastrar" e nada acontecia. Agravante: não havia **nenhum spec de autenticação** em `spec/requests`,
o que explica por que isso passou: dois controllers Devise customizados, sem cobertura.

**Correção.** Commit `5c41e0a`: `errors: inertia_errors(resource, scope: "user")` no 422, mais
`spec/requests/auth_spec.rb` (sign up, sign in, sign out, erros de registro, página de login) — a
cobertura que faltava.

**Aprendizado.** Corrigir um bug por família exige caçar os **outros membros da família**, não só o
que foi reportado. E "a página não tem toast" é um sinal de que o caminho de erro nunca foi
exercitado: se a única fonte de feedback é o flash, um 422 é um beco sem saída silencioso. Cobertura
de auth era o requisito, não o.extra.

---

## Incidente 5 — O agente rodou a suíte contra o banco de desenvolvimento

**Fase/contexto.** Diagnóstico do incidente 3, quando a causa ainda não estavaisolate.

[CONFIRMAR: o incidente que vivi foi o agente criar e remover registros no meu banco de desenvolvimento
sem eu pedir. Não existe rastro disso no repositório — nenhum seed, nenhum script, nenhuma linha de
spec toca o banco de desenvolvimento — então não consigo ancorar em commit. Registro abaixo a versão
verificável e mecanicamente idêntica do problema, que encontrei ao executar o stack nesta rodada.]

**O que a IA fez.** Executou a suíte RSpec com o `RAILS_ENV` padrão do container, que é
`development` (`docker-compose.yml:22`). Numa iteração anterior, usando a configuração padrão, o
agente chegou a criar e apagar registros no banco de desenvolvimento durante o diagnóstico.

**Problema (como foi detectado).** Pelo resultado: `docker compose exec app bundle exec rspec` falha
com `expected Book::ActiveRecord_Associations_CollectionProxy#count to have changed by 1, but was
changed by 0`, porque a suíte roda contra o banco de desenvolvimento, onde o schema e os dados não
são os de teste. Verifiquei o caso mais perigoso:

```
$ docker compose exec -e RAILS_ENV=test app ./bin/rails runner \
    'puts "ambiente=#{Rails.env} db=#{ActiveRecord::Base.connection_db_config.database}"'
ambiente=test db=litera_development
```

Trocar só o `RAILS_ENV` deixa o `DATABASE_URL` apontando para `litera_development`: a suíte passa a
rodar `maintain_test_schema!` sobre o banco de desenvolvimento.

**Correção.** Passos a exigir `RAILS_ENV=test` **e** `DATABASE_URL` apontando para um banco separado,
e a documentar isso no README com o comando verificado:

```bash
docker compose exec -T -e RAILS_ENV=test \
  -e DATABASE_URL=postgres://litera:litera_password@postgres:5432/litera_test \
  app bash -lc './bin/rails db:prepare && bundle exec rspec'
```

Com os dois, `101 examples, 0 failures`.

**Aprendizado.** `RAILS_ENV` e `DATABASE_URL` são knobs independentes e o segundo tem precedência
sobre o `config/database.yml`. Em ambiente com o compose, "rodar os testes" não é um comando, é um
contrato de duas variáveis. Regra que passei a adotar: nenhum comando que escreva no banco sem
`RAILS_ENV` e `DATABASE_URL` explícitos e verificados.

---

## Incidente 6 — Typecheck verificado com o comando errado

**Fase/contexto.** Revisão de código, logo após a correção do incidente 3.

**O que a IA fez.** Reportou "tsc OK" em vários commits, usando `tsc --noEmit` na raiz. O projeto tem
um script próprio: `npm run check` → `tsc -p tsconfig.app.json && tsc -p tsconfig.node.json`, que é
mais estrito. Verifiquei depois com `git stash` + `git checkout 689bd7e`: o baseline do `npm run
check` estava limpo, e o meu trabalho tinha **12 erros de tipo** acumulados em três commits.

Dois tipos de erro, ambos introduzidos por mim:

1. `errors['book.base']` — o Inertia tipa `FormDataErrors<T>` como um mapped type sobre os campos do
   formulário, então a chave de registro não existe no tipo.
2. `PaginationLink` — ao intersectar `ComponentProps<typeof Link>` com `VariantProps<typeof
   buttonVariants>` sem `Omit`, o `size` colapsava para `never` e o `children` para `undefined`.

**Problema (como foi detectado).** Ao rodar `npm run check` por conta própria, ao verificar o gate antes
de documentar os comandos do README.

**Correção.** Commit `89045c6`: helper `baseError(errors, scope)` em `app/frontend/lib/errors.ts`, com
`Omit<React.ComponentProps<typeof Link>, "size">` no `PaginationLink`. O corpo do commit registra que
o gate estava quebrado e por quê.

**Aprendizado.** Quando o projeto tem um script próprio para o gate, o gate é o script. `tsc --noEmit`
na raiz parece equivalente e não é — usa o `tsconfig.json`, que é uma configuração diferente da
aplicação. E o `.github/workflows/ci.yml:54` **também** usa `tsc --noEmit`, ou seja, o CI do projeto
tem o mesmo furo: um erro de tipo como o do `book.base` passaria no CI.

---

## Incidente 7 — Sugestão de índices parciais rejeitada

[CONFIRMAR: não existe nenhum índice parcial em `db/migrate/` — confirmei com `add_index`/`where:` e
com `git log -S`. A história abaixo é a da decisão, conforme você a descreveu, e não de um código que
chegou a existir.]

**Fase/contexto.** Modelagem da regra de duplicidade.

**O que a IA sugeriu.** Separar a duplicidade em dois índices parciais: um para cadastros com
`open_library_key` presente (vindos da OpenLibrary) e outro para cadastros manuais. O argumento era
que são Origens diferentes e poderiam ter identidades diferentes.

**Problema.** A regra combinada passaria a permitir o mesmo livro duas vezes para o mesmo usuário: uma
vez pela busca da OpenLibrary e outra pelo cadastro manual. Como a OpenLibrary nem sempre tem o livro,
esse é exatamente o caminho que um usuário real toma — busca, não encontra, cadastra à mão.

**Correção.** Regra única por usuário, sem condição de origem:
`(user_id, lower(title), lower(author), COALESCE(first_publish_year, -1))`, com
`open_library_key` fora da identidade. A coluna é removida da definição de "mesmo livro" justamente
para que a via manual não seja um buraco.

**Aprendizado.** Critérios de unicidade precisam ser testados contra os **caminhos de escrita
possíveis**, não contra o caminho principal. Uma regra que só funciona no fluxo feliz e é furada pelo
fallback é pior do que não existir, porque parece proteção.

---

## Resumo do que mudou na prática

| Antes | Depois |
|---|---|
| `npx tsc --noEmit` como verificação de tipo | `npm run check` (e o CI ainda usa o comando frouxo) |
| Sem spec de autenticação | `spec/requests/auth_spec.rb` com sign up/in/out e erros |
| Erros de validação não chegavam ao front | `inertia_errors` em Books e Users, com specs que falhavam antes |
| `POST /users` inválido era silencioso | Erro por campo renderizado |
| Conserto de paginação na página | Componente do shadcn corrigido na origem, cópia apagada |
| `data-active={false}` | `data-active` omitido quando inativo |
| Um link de paginação por página | Janela de 7 itens com elipses |
| Sem proteção de corrida no índice único | `RecordNotUnique` convertido no mesmo erro de `:base` |
| Rate limit da OpenLibrary inexistente | 30/min por usuário + título mínimo de 2 letras |
| Nenhum teste verificava a configuração real | CI e README com os comandos executados de verdade |

O padrão que mais se repetiu: **a IA escrevia código plausível que o repositório não exerciseva** —
um 422 sem `errors`, um `data-active` com valor errado, um typecheck que nunca rodou no comando
certo. Nenhum desses aparecia em erro de sintaxe ou em tela quebrada de forma óbvia; apareciam no
comportamento, ou seja, só um spec ou uma execução manual revela.
