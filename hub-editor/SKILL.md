# hub-editor — Editar Componente/Página no aptus-hub

## Quando usar
Editar, modificar ou excluir componente, página ou rota existente no aptus-hub (Angular 21).

## Passo 0 — Injetar Contexto
Ler antes de qualquer ação:
- `aptus-hub/CLAUDE.md` — focar nas seções: **Autenticação**, **Padrões Angular 21**, **Serviços Principais**
- `aptus-hub/DECISIONS.md` — verificar decisões recentes que afetam a feature
- `aptus-hub/HUB.md` — localizar o componente/rota alvo, entender guard e services atuais. Se o arquivo não existir ainda, criar a estrutura inicial antes de prosseguir

## Passo 1 — Ler Estado Atual
Ler os arquivos do componente/feature alvo antes de editar:
- Arquivo `.component.ts` do alvo
- `routes.ts` correspondente (se a rota está sendo alterada)
- Service relevante (se a lógica está sendo movida)

Nunca supor o estado atual — sempre ler primeiro.

## Passo 2 — Analisar Impacto
Antes de editar, verificar:
- A mudança altera o guard da rota? Confirmar com o usuário se necessário
- Se excluindo rota: buscar `routerLink` e referências ao componente em outros templates

## Passo 3 — Aplicar Edição Cirúrgica
- Usar `Edit` para mudanças pontuais — nunca reescrever arquivo inteiro para mudança pequena
- Preferir `signal()` ao refatorar estado
- Manter `standalone: true` e padrões Angular 21

## Passo 4 — Verificação
- [ ] Componente ainda tem `standalone: true`
- [ ] Nenhum `NgModule` ou `CommonModule` foi introduzido
- [ ] URLs do backend não foram hardcodadas
- [ ] Resultado é coerente com o que foi solicitado

## Passo 5 — Atualizar Documentação
Atualizar `aptus-hub/HUB.md`:
- Se rota foi adicionada: criar nova seção
- Se rota foi removida: remover a seção
- Se guard ou role de acesso mudou: atualizar campo Guard
- Se componente ou service responsável mudou: atualizar campos correspondentes
