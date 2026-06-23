# backend-editor — Editar Feature no aws-backend

## Quando usar
Editar, modificar ou excluir endpoint, rota, service, guard ou módulo existente no aws-backend (NestJS 11).

## Passo 0 — Injetar Contexto
Ler antes de qualquer ação:
- `aws-backend/CLAUDE.md` — focar nas seções: **Guards**, **Firestore**, **Padrões Obrigatórios**
- `aws-backend/DECISIONS.md` — verificar decisões recentes que afetam a feature
- `aws-backend/BACKEND.md` — localizar o módulo alvo, entender rotas e guards atuais. Se o arquivo não existir ainda, criar a estrutura inicial antes de prosseguir

## Passo 1 — Ler Estado Atual
Ler TODOS os arquivos do módulo alvo antes de editar:
- `src/{modulo}/{modulo}.module.ts`
- `src/{modulo}/{modulo}.controller.ts`
- `src/{modulo}/{modulo}.service.ts`
- DTOs relevantes

Nunca supor o estado atual — sempre ler primeiro.

## Passo 2 — Analisar Impacto
Antes de editar, verificar:
- A mudança remove ou altera algum guard? (proibido sem análise de segurança)
- A mudança de DTO pode quebrar chamadas do aptus-hub?
- Se excluindo módulo: `grep -r "NomeModule" src/` para encontrar dependências

## Passo 3 — Aplicar Edição Cirúrgica
- Usar `Edit` para mudanças pontuais — nunca reescrever arquivo inteiro para mudança pequena
- Se excluindo módulo: remover do `AppModule` + deletar pasta `src/{modulo}/`
- Manter guards existentes salvo instrução explícita em contrário

## Passo 4 — Verificação
- [ ] `npm run build` passa sem erros de tipo
- [ ] Guards não foram removidos inadvertidamente
- [ ] Nenhum `process.env` direto inserido
- [ ] Nenhum `admin.firestore()` direto inserido
- [ ] Resultado é coerente com o que foi solicitado

## Passo 5 — Atualizar Documentação
Atualizar `aws-backend/BACKEND.md`:
- Se adicionou rota: incluir na tabela do módulo correspondente
- Se removeu rota: remover da tabela
- Se mudou guard: atualizar campo Auth do módulo
- Se excluiu módulo: remover a seção inteira

Se a mudança afeta arquitetura global (novo guard, nova collection Firestore), atualizar também `aws-backend/CLAUDE.md`.
