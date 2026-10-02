# Litera

Catálogo de livros onde todo mundo cadastra o que leu. A home é aberta: quem não tem conta
consegue ver e filtrar a coleção. Quem cria conta adiciona livros, edita e apaga só os que
cadastrou.

Para adicionar um livro, a pessoa digita o título e a aplicação busca na OpenLibrary. As opções
aparecem na tela, e ao escolher uma, autor, ano, gênero e capa vêm preenchidos. Se a busca não
sir (ou a OpenLibrary estiver fora do ar), dá para preencher na mão.

## Tecnologias

- Ruby 3.3+ / Rails 8
- React 19 + TypeScript, com Inertia.js e Vite
- Tailwind CSS + shadcn/ui
- PostgreSQL
- Pundit (permissões), Devise (login), Kaminari (paginação), Faraday (HTTP), RSpec + WebMock
- Docker e Docker Compose

## Como rodar

```bash
cp .env.example .env
docker compose up --build
```

A aplicação fica em http://localhost:3100 (o Postgres sobe em 5433 e o Vite em 3036, caso precise
mudar, é no `.env`).

O banco é criado no primeiro boot e não vem com dados de exemplo. Crie uma conta em
`/users/sign_up` e cadastre o primeiro livro.

### Lint, tipos e testes

```bash
# RuboCop
docker compose exec -T app bundle exec rubocop

# typecheck do frontend (script do próprio projeto)
docker compose exec -T app npm run check

# RSpec
docker compose exec -T -e RAILS_ENV=test \
  -e DATABASE_URL=postgres://litera:litera_password@postgres:5432/litera_test \
  app bash -lc './bin/rails db:prepare && bundle exec rspec'
```

Os dois `-e` do RSpec são obrigatórios: o compose sobe tudo em `development`, e sem eles a suíte
roda contra o banco de desenvolvimento em vez do de teste.

## O que a aplicação faz

- Lista paginada (10 por página, ordenada do cadastro mais novo para o mais antigo) com filtro por
  autor, gênero e ano.
- Cadastro, edição e remoção de livros. Os botões de editar/apagar só aparecem nos livros da própria
  pessoa, e o backend confere isso de novo.
- Busca na OpenLibrary, com os resultados abrindo na tela para a pessoa escolher.
- Endpoint JSON em `/books.json`, com os mesmos filtros e a mesma paginação da home.

## Organização

A ideia foi deixar cada coisa no lugar dela. O Rails decide as regras, o React cuida da tela.

- `app/controllers`: só orquestram. Os filtros estão em `app/queries`, o formato do JSON de cada
  livro em `app/serializers`, as permissões em `app/policies` e a integração com a OpenLibrary em
  `app/services/open_library`.
- `app/frontend`: páginas e componentes. Não existe regra de permissão aqui: o Rails manda um
  `can_edit` em cada livro e a tela só mostra ou esconde os botões.
- `app/frontend/types`: o contrato entre os dois lados. É o que o Rails promete entregar em cada
  página.

## Decisões técnicas

O desafio deixou três pontos em aberto. Foi assim que resolvi cada um.

### Livro duplicado

O mesmo usuário não cadastra o mesmo livro duas vezes. Duas pessoas diferentes podem, porque a
ideia do catálogo é registrar leituras: se a Ana e o João leram *Dom Casmurro*, os dois têm que
aparecer.

Considero repetido quando o mesmo usuário já tem um livro com o mesmo título, autor e ano. A
comparação ignora maiúsculas e minúsculas, e vale igual para livro vindo da OpenLibrary e para o
cadastrado na mão.

A garantia vem de dois lugares: uma validação no model, que mostra o erro no formulário, e um índice
único no banco. Só a validação não bastaria, porque duas requisições simultâneas podem passar pelas
duas e só uma grava. Quando isso acontece, o `RecordNotUnique` vira o mesmo erro de validação, em vez
de erro 500.

Um efeito colateral: como o ano entra na comparação, o mesmo título com anos diferentes é aceito.
Achei razoável, já que normalmente são edições diferentes.

### OpenLibrary fora do ar ou sem resultado

Não quis que um problema de um serviço de terceiro impedisse alguém de cadastrar um livro. A busca
é ajuda, não requisito: se ela falhar, demorar mais de 2 segundos ou voltar vazia, aparece um aviso
em português e o formulário continua liberado para preenchimento manual.

Por dentro, o cliente converte cada tipo de falha (timeout, erro 500, resposta quebrada, lista
vazia) num erro com código próprio, e a tela mostra a mensagem correspondente. Resultado sem autor ou
sem ano também não quebra nada. Para não abusar da API, a busca só começa com 2 letras e cada
usuário pode fazer 30 por minuto.

Não coloquei cache nem nada mais sofisticado de resiliência. Para o tamanho do projeto, o aviso
mais o cadastro manual resolvem.

### Acesso ao `/books.json`

Liberado para qualquer pessoa, com paginação e os mesmos filtros da home. Se a página inicial é
pública, não faria sentido o JSON do mesmo conteúdo pedir login. O que é protegido é a edição, e
ela sempre passa pela policy.

O JSON não traz e-mail nem nada da conta, só o `owner_id`. Dá para perceber quais livros são da
mesma pessoa, mas como o catálogo já é público, achei aceitável.

### Outras escolhas

**Gênero é texto livre.** Quando o livro vem da OpenLibrary, o gênero é preenchido com o primeiro
assunto do livro e pode ser editado antes de salvar. Pensei em tabela de gêneros ou lista fixa, mas
isso exigiria cadastrar e migrar dados, e a fonte dos assuntos não é padronizada. O custo é que os
gêneros chegam em inglês.

**Inertia no lugar do Turbo.** O Rails já vem com Hotwire no boilerplate, e ele briga com o Inertia
(as duas camadas interceptam o mesmo clique). Removi o Turbo, o Stimulus e o importmap, e deixei um
spec que falha se algum deles voltar.

**Paginação com Kaminari**, ordenando por `created_at` e depois por `id`, para dois livros criados no
mesmo segundo não trocarem de lugar entre uma página e outra.

**Controller não conhece regra.** Ele só monta a resposta. Filtro é `BookFilter`, formato do JSON é
`BookSerializer`, permissão é `BookPolicy`. Isso deixa mais arquivos, mas cada um tem uma
responsabilidade só, e dá para testar cada parte isolada.

## Testes

101 exemplos, todos passando, cobrindo models, policies, queries, serializer, requests (incluindo
autenticação) e o serviço da OpenLibrary. Cobertura de linhas em 97%.

Nenhum teste toca a internet: a OpenLibrary é simulada com WebMock, incluindo sucesso, lista vazia,
erro 500, timeout e resposta inválida.

O frontend não tem testes próprios, só o typecheck (`npm run check`).

## Com mais tempo

**Deploy.** É o que mais falta hoje: subir a imagem no ECR e rodar em ECS/Fargate, com RDS para o
Postgres e um ALB na frente. Tem mais de uma forma de fazer isso e eu ainda não tenho prática com
essas ferramentas, então não quis subir algo que eu não conseguiria manter. Kubernetes entrou na
lista de possibilidades, mas preferi não colocar manifestos no repositório sem saber rodá-los: um
yaml que nunca subiu não vale como entrega.

**Serviços de apoio.** Cache da OpenLibrary (evita chamar a API de novo para o mesmo título) e logs
estruturados foram os diferenciais que ficaram de fora. Priorizei terminar o fluxo de cadastro com
testes em cima, que é o que é avaliado primeiro.

**Gênero em português.** Uma lista curada de gêneros com combobox no formulário e um mapeamento dos
assuntos da OpenLibrary. Deixei de fora porque dá trabalho decidir a lista e o que fazer com os dados
já cadastrados.

**Testes do frontend**, principalmente da paginação e dos formulários. Consigo garantir o contrato
entre Rails e React pelo typecheck e pelos specs de request, mas o comportamento da tela em si só foi
testado na mão.

**Mensagens de validação em português** pelo I18n do Rails. Algumas ainda aparecem em inglês.

**Recuperação de senha.** O Devise já está configurado para isso, faltam as telas.

## Uso de IA

Usei IA em todas as etapas: para pensar a arquitetura, para montar os prompts e para investigar bugs
a partir do que eu via no navegador. A implementação foi feita principalmente pelo Codex, seguindo
um `AGENTS.md` com as regras do projeto, uma etapa por vez. Eu revisei cada etapa, rodei na mão e
decidi o que entrava. O código entregue é de minha responsabilidade e eu consigo explicar qualquer
parte dele.

O registro completo dos erros que a IA cometeu e de como eu corrigi está em
[`ai-notes.md`](./ai-notes.md). Os três que maisvaleram:

**Tela em branco ao paginar.** O Turbo do boilerplate continuou ativo junto com o Inertia. Ao clicar
na página 2 a tela ficava branca, e só voltava com F5. Achei olhando a aba Network do DevTools: os
requests saíam com headers do Turbo (`x-turbo-request-id`) em vez dos do Inertia. Removi o Hotwire e
escrevi um spec para não voltar.

**"Cadastrado com sucesso" numa falha.** Ao cadastrar um livro repetido, o servidor respondia 422
mas sem a lista de erros, e o Inertia entende isso como sucesso: o usuário via o toast de sucesso e o
livro não era salvo. O mesmo bug estava no cadastro de conta, e ali nem havia toast. Passei a montar
os erros no formato que o Inertia espera e criei specs que falhavam antes da correção.

**"O typecheck passou" que não passou.** O agente rodava `npx tsc --noEmit` na raiz, que usa outro
`tsconfig` e é mais frouxo que o script do projeto. Quando rodei `npm run check`, apareceram 12 erros
de tipo que já estavam em commits anteriores. O CI tinha o mesmo furo; passei a usar `npm run check`
nos dois lugares.

Também descartei uma sugestão da IA de criar dois índices parciais de unicidade (um para livros da
OpenLibrary, outro para os manuais). Do jeito que ela sugeriu, o mesmo livro entraria duas vezes
para a mesma pessoa: uma pela busca e outra pelo cadastro manual, que é justamente o caminho de quem
não acha o livro na OpenLibrary. Ficou uma regra só, sem olhar a origem do cadastro.