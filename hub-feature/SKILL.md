# hub-feature — Criar Componente/Página no aptus-hub

## Quando usar
Criar novo componente, página, rota ou feature no aptus-hub (Angular 21).

## Passo 0 — Injetar Contexto
Ler antes de qualquer ação:
- `aptus-hub/CLAUDE.md` — focar nas seções: **Autenticação**, **Padrões Angular 21**, **Serviços Principais**
- `aptus-hub/DECISIONS.md` — verificar decisões recentes que afetam a feature
- `aptus-hub/HUB.md` — rotas e componentes existentes (para não duplicar). Se o arquivo não existir ainda, criar a estrutura inicial antes de prosseguir

## Passo 1 — Entender o Escopo
Com base na solicitação, definir:
- Nome do componente e path da rota (se for página)
- Role mínimo de acesso: `público` | `authGuard` | `authGuard + roleGuard(['admin'])`
- Serviços necessários: `HubApiService`, `DashboardService`, `StudioApiService`, `BotpressEmbedService`
- Se será lazy-loaded (padrão: sim para páginas)

## Passo 2 — Invocar `/frontend-design`
Usar a skill `/frontend-design` para gerar a UI do componente.

## Passo 3 — Aplicar Padrões Angular 21 APTUS
Após geração, verificar e aplicar:
- `standalone: true` no decorator do componente — sem NgModule, sem CommonModule
- Estado local com `signal()` e `computed()` — não `BehaviorSubject`
- DI com `inject(ServicoNome)` — não constructor injection
- Se nova rota: adicionar em `routes.ts` com `loadComponent` (lazy loading)
- URLs do backend via `API_BASE_URL` — nunca hardcodado
- HTTP Interceptor já cuida do token de auth — não adicionar header manualmente

## Passo 4 — Verificação
- [ ] Componente tem `standalone: true`
- [ ] Nenhum `NgModule` ou `CommonModule` importado
- [ ] Estado reativo usa `signal()`, não `Subject`/`BehaviorSubject`
- [ ] DI usa `inject()`, não constructor
- [ ] URLs do backend não estão hardcodadas
- [ ] Guard correto aplicado na rota (se página)
- [ ] Resultado é coerente com o que foi solicitado

## Passo 5 — Atualizar Documentação
Atualizar `aptus-hub/HUB.md`:
- Adicionar seção da nova rota/componente com: path, componente, guard, lazy load, services, observações relevantes
