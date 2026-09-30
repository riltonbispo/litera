# Projeto

Catálogo coletivo de leituras. Rails 7+ (Ruby 3.3+), PostgreSQL, React + TypeScript via Inertia.js (inertia_rails + Vite), RSpec, WebMock, Pundit, Kaminari, Docker Compose.

# Regras

- Seguir convenções Rails (REST, strong params, fat model/skinny controller com service objects só onde há integração externa).
- Controllers apenas orquestram; lógica de busca/filtro em scopes/query objects; integração OpenLibrary em app/services/open_library/.
- Autorização exclusivamente via Pundit (policies), nunca if/else de user no controller ou no React.
- Frontend: TypeScript estrito (sem any), componentes pequenos em app/frontend, props tipadas, sem lógica de negócio no React.
- Todo código novo vem com testes RSpec (models, requests, service com WebMock). Nenhuma chamada HTTP real nos testes.
- Antes de encerrar qualquer tarefa: rodar `bundle exec rspec` e `bundle exec rubocop` e `npx tsc --noEmit`; só finalize se passarem.
- Commits pequenos, Conventional Commits, um por unidade lógica.
- Não adicionar gems/libs sem justificar em uma linha.
- Não escrever README sem eu pedir.
- Quando houver decisão ambígua, listar as opções com trade-offs e perguntar antes de implementar.
- UI: usar exclusivamente shadcn/ui (componentes em app/frontend/components/ui, adicionados via `npx shadcn@latest add <componente>`) com Tailwind CSS. Não criar componentes de UI do zero quando existir equivalente no shadcn. Não usar outras bibliotecas de componentes (MUI, Chakra, Bootstrap etc.). Usar os tokens/variáveis CSS do tema do shadcn para cores, sem valores hardcoded.