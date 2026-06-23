# backend-feature — Criar Feature no aws-backend

## Quando usar
Criar novo módulo, feature, endpoint, controller ou service no aws-backend (NestJS 11).

## Passo 0 — Injetar Contexto
Ler antes de qualquer ação:
- `aws-backend/CLAUDE.md` — focar nas seções: **Guards**, **Firestore**, **Padrões Obrigatórios**
- `aws-backend/DECISIONS.md` — verificar decisões recentes que afetam a feature
- `aws-backend/BACKEND.md` — módulos e rotas existentes (para não duplicar). Se o arquivo não existir ainda, criar a estrutura inicial antes de prosseguir

## Passo 1 — Entender o Escopo
Com base na solicitação, definir:
- Nome do módulo e prefixo de rota
- Tipo de autenticação necessária: consulte `aws-backend/CLAUDE.md` (seções **Guards** e **Padrões Obrigatórios**) para identificar o guard correto para a rota
- Coleções Firestore que serão acessadas (se houver)
- Novas variáveis de ambiente necessárias (se houver)

## Passo 2 — Invocar `/nestjs-expert`
Usar a skill `/nestjs-expert` para gerar a estrutura base:
- `{nome}.module.ts`
- `{nome}.controller.ts` com decorators Swagger (`@ApiTags`, `@ApiBearerAuth`, `@ApiResponse`)
- `{nome}.service.ts`
- DTOs com `class-validator`

## Passo 3 — Aplicar Padrões APTUS
Após geração, verificar e aplicar:
- Guard correto no controller (conforme Passo 1)
- Acesso ao Firestore SOMENTE via `FirestoreService` injetado — nunca `admin.firestore()` direto
- Acesso ao Redis SOMENTE via `RedisService`
- Novas env vars: adicionar ao schema Joi em `src/core/` antes de usar no código
- Registrar módulo no `AppModule`
- Injeção de dependência via constructor — sem `new ServiceName()`

## Passo 4 — Verificação
- [ ] `npm run build` passa sem erros de tipo
- [ ] Guard correto está aplicado no controller
- [ ] Nenhum `process.env` direto no código novo
- [ ] Nenhum `admin.firestore()` direto no código novo
- [ ] DTOs com `class-validator` em todos os endpoints que aceitam body
- [ ] Decorators Swagger presentes no controller

## Passo 5 — Atualizar Documentação
Atualizar `aws-backend/BACKEND.md`:
- Adicionar seção do novo módulo com: prefixo de rota, guard aplicado, coleções Firestore, tabela de rotas

Se a feature altera o comportamento de autenticação ou estrutura global, atualizar também `aws-backend/CLAUDE.md`.
