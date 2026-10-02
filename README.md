# Litera

[![CI](https://github.com/riltonbispo/litera/actions/workflows/ci.yml/badge.svg)](https://github.com/riltonbispo/litera/actions/workflows/ci.yml)

Um catálogo coletivo de leituras. Qualquer pessoa pode ver e filtrar os livros cadastrados; quem cria
uma conta adiciona os seus e só consegue editar ou apagar o que ela mesma cadastrou.

Para cadastrar, basta digitar o título: a aplicação busca na OpenLibrary, mostra as opções e, ao
escolher uma, autor, ano, gênero e capa já vêm preenchidos. Se a busca não ajudar (ou a OpenLibrary
estiver fora do ar), dá para preencher tudo na mão.

Feito com Rails, React + TypeScript (via Inertia.js), shadcn/ui, PostgreSQL e RSpec.

## Como rodar

```bash
cp .env.example .env
docker compose up --build
```

Depois é só abrir http://localhost:3100. O banco é criado no primeiro boot, mas não há dados de
exemplo: crie uma conta em `/users/sign_up` para começar.

Para rodar lint, typecheck e testes:

```bash
docker compose exec -T app bundle exec rubocop
docker compose exec -T app npm run check

docker compose exec -T -e RAILS_ENV=test \
  -e DATABASE_URL=postgres://litera:litera_password@postgres:5432/litera_test \
  app bash -lc './bin/rails db:prepare && bundle exec rspec'
```

Os dois `-e` do último comando são necessários. O compose sobe tudo em `development`, e sem eles o
RSpec acabaria rodando contra o banco de desenvolvimento.

## Como o código está organizado

Procurei deixar cada coisa no seu lugar. O Rails decide as regras (quem pode editar, o que é
duplicado, o que é válido) e o React só cuida da tela.

- Os controllers só coordenam. Os filtros ficam em `app/queries`, o formato do JSON de cada livro em
  `app/serializers`, as permissões em `app/policies` (Pundit) e a conversa com a OpenLibrary em
  `app/services/open_library`.
- O React não tem regra de permissão. O Rails manda um `can_edit` em cada livro e a tela apenas
  mostra ou esconde os botões.
- Os tipos que o React espera estão em `app/frontend/types`, e é nesse arquivo que fica combinado o
  que o Rails entrega para cada página.

## Decisões que o desafio deixou em aberto

### Livro duplicado

Cada usuário não pode cadastrar o mesmo livro duas vezes, mas duas pessoas diferentes podem ter o
mesmo livro. Isso porque a ideia do catálogo é registrar leituras: se a Ana e o João leram *Dom
Casmurro*, os dois devem aparecer. Um livro é considerado repetido quando o mesmo usuário já tem outro
com o mesmo título, autor e ano (sem diferenciar maiúsculas de minúsculas), não importa se veio da
OpenLibrary ou foi digitado.

Garanto isso de duas formas: uma validação no model, que gera a mensagem de erro no campo certo, e um
índice único no banco, que segura o caso de duas requisições simultâneas. Sem o índice, a validação
sozinha deixaria passar as duas.

Uma consequência: como o ano entra na comparação, o mesmo título com anos diferentes é aceito. Achei
razoável, já que costumam ser edições diferentes.

### OpenLibrary fora do ar ou sem resultado

Não quis que um problema num serviço de terceiros impedisse alguém de cadastrar um livro. Então a
busca é só uma ajuda: se ela falha, demora mais de 2 segundos ou volta vazia, aparece um aviso em
português e o formulário continua liberado para preenchimento manual.

Por dentro, o cliente da OpenLibrary transforma cada tipo de falha (timeout, erro 500, resposta
quebrada, lista vazia) num erro com código próprio, e a tela mostra a mensagem certa para cada um.
Livros que vêm sem autor ou sem ano também não quebram nada. Para não sobrecarregar a API, a busca só
começa com 2 letras e cada usuário pode fazer até 30 por minuto.

Não coloquei cache nem nada mais sofisticado de resiliência. Para o tamanho do projeto, o aviso e o
cadastro manual resolvem.

### Quem pode acessar `/books.json`

Qualquer pessoa, igual à página inicial, e com paginação (10 por página, no máximo 50). Se a home é
pública, não faria sentido o JSON do mesmo conteúdo exigir login. O que é protegido é a edição, que
passa sempre pela policy.

O JSON não traz e-mail nem dados da conta, só o `owner_id`. Sei que isso permite ver quais livros são
da mesma pessoa, mas como o catálogo já é público, achei aceitável.

## Outras escolhas

**Gênero.** É um campo de texto livre. Ao escolher um resultado da OpenLibrary ele vem preenchido com o
primeiro assunto do livro, e dá para editar antes de salvar. Considerei uma tabela de gêneros ou uma
lista fixa, mas isso exigiria cadastrar e migrar dados, e o gênero vem de uma fonte que não é
padronizada. O custo é que os gêneros chegam em inglês.

**Inertia no lugar do Turbo.** O Rails já vem com o Hotwire, mas ele briga com o Inertia, então removi
o Turbo, o Stimulus e o importmap. Existe um teste que falha se algum deles voltar.

**Paginação.** Uso Kaminari, ordenando por data e depois por `id`, para a ordem não mudar entre uma
página e outra.

**Testes.** Nenhum teste chama a internet: a OpenLibrary é simulada com WebMock em todos os casos
(sucesso, vazio, 500, timeout, resposta inválida). São mais de 100 testes e a cobertura de linhas fica
em torno de 97%. O frontend não tem testes próprios, só o typecheck.

## Com mais tempo

- **Gênero em português.** Faria uma lista curada de gêneros, com um combobox no formulário, e um
  mapeamento dos assuntos da OpenLibrary. Deixei de fora porque envolve decidir a lista e o que fazer
  com os dados já cadastrados, e preferi deixar o fluxo principal bem redondo.
- **Testes do frontend**, principalmente da paginação e dos formulários. Priorizei o backend porque é
  onde estão as regras.
- **Mensagens de validação em português** pelo I18n do Rails. Algumas ainda aparecem em inglês.
- **Recuperação de senha.** O Devise está configurado para isso, mas não fiz as telas.
- **Cache da OpenLibrary, logs estruturados e manifests de Kubernetes.** Eram diferenciais e preferi
  gastar o tempo em testes e na qualidade do fluxo de cadastro.

## Como usei IA

Usei o Claude para planejar: pensar a arquitetura, discutir as três decisões acima, escrever os
prompts de cada etapa e me ajudar a entender bugs a partir do que eu via no navegador. A implementação
foi feita principalmente com o Codex, que seguia um arquivo `AGENTS.md` com as regras do projeto e
recebia uma etapa por vez. Eu revisei cada etapa, testei na mão e decidi o que entrava. Sou
responsável por todo o código, e consigo explicar qualquer parte dele.

Os erros da IA que mais deram trabalho (o registro completo está em [`ai-notes.md`](./ai-notes.md)):

**A tela em branco na paginação.** O Turbo do Rails ficou ativo junto com o Inertia. Ao clicar na
página 2 a tela ficava em branco, e só funcionava com F5. Descobri olhando a aba Network, que mostrava
cabeçalhos do Turbo (`x-turbo-request-id`) em vez dos do Inertia. Removi o Hotwire e escrevi um teste
para isso não voltar.

**O "Livro cadastrado com sucesso" que aparecia mesmo com erro.** Ao tentar cadastrar um livro
repetido, o servidor respondia 422 mas sem a lista de erros, e o Inertia entende isso como sucesso.
Resultado: o usuário via a mensagem de sucesso e o livro não era salvo. A correção foi montar os erros
no formato que o Inertia espera, e o mesmo problema também existia no cadastro de conta.

**O "tsc OK" que não era.** O Codex me disse que o typecheck passava, mas ele rodava um comando mais
frouxo do que o do projeto. Quando rodei o `npm run check`, apareceram erros de tipo que já estavam em
commits anteriores. Passei a conferir sempre com o script oficial.

**Dois erros do próprio Claude.** Ao investigar por que o cadastro manual falhava, ele suspeitou de
strings vazias, mas o problema real era duplicidade com um livro já cadastrado pela OpenLibrary. Em
outro momento, sugeriu duas regras de duplicidade separadas (manual e OpenLibrary), o que deixaria o
mesmo livro entrar duas vezes. Descartei e mantive uma regra só.
