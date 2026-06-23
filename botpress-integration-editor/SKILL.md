---
name: botpress-integration-editor
description: Edição de integração Botpress existente. Lê o estado atual dos arquivos, aplica as mudanças solicitadas (nova action, novo campo, novo endpoint) e valida o build. Use quando o usuário pedir para modificar uma integração Botpress já existente.
license: MIT
metadata:
  author: APTUS
  version: "1.0.0"
  domain: botpress
  triggers: editar integração, modificar integração, adicionar action, remover action
  role: specialist
---
# Skill: Editar Integração Botpress Existente

## Quando usar esta skill
Use quando o usuário pedir para **modificar** uma integração Botpress já existente. Exemplos de gatilho:
- "adicionar uma action na integração X"
- "modificar a action Y da integração X"
- "remover a action Z"
- "adicionar um campo novo no input/output"
- "mudar o endpoint que a integração usa"

**Não use** esta skill para criar integrações do zero — use a skill `botpress-integration`.

---

## Informações necessárias antes de começar

Se o usuário não informar, pergunte:

1. **Nome da integração** (ex: `asaas`, `kommo`) — deve corresponder ao diretório em `bp-integrations/`
2. **O que exatamente deve ser alterado** — nova action, campo novo, endpoint diferente, etc.
3. **Se a mudança envolve um novo endpoint de API** — se sim, precisará da documentação

---

## Fluxo de execução

### PASSO 0 — Injetar Contexto
Ler antes de qualquer ação:
- `bp-integrations/CLAUDE.md` — focar nas seções: **Padrões Obrigatórios**, **Dependências**
- `bp-integrations/DECISIONS.md` — verificar decisões recentes que afetam a integração
- `bp-integrations/INTEGRATIONS.md` — estado atual das integrações. Se o arquivo não existir ainda, criar a estrutura inicial antes de prosseguir

### PASSO 1 — Ler o estado atual da integração

Leia os três arquivos principais antes de qualquer edição:

```
bp-integrations/<nome>/integration.definition.ts
bp-integrations/<nome>/src/index.ts
bp-integrations/<nome>/src/<nome>.service.ts
```

Entenda:
- Quais actions já existem
- Quais campos de configuração já estão definidos
- Como o service está estruturado (padrão de imports, nomenclatura)

### PASSO 2 — Pesquisar documentação (somente se necessário)

Se a mudança envolve um endpoint de API novo ou desconhecido, use o subagente `api-doc-reader`:

> "Use o subagente api-doc-reader para ler a documentação em [URL/caminho] e extrair o endpoint [nome do endpoint]. Preciso dos campos obrigatórios/opcionais do request e do schema do response."

Se os endpoints já são conhecidos (o usuário descreveu tudo), pule este passo.

### PASSO 3 — Aplicar as edições

Edite **apenas o necessário** nos arquivos afetados. Regras:

**Para adicionar uma action:**
- `integration.definition.ts`: adicionar o bloco da nova action dentro de `actions: { ... }`
- `src/<nome>.service.ts`: adicionar a função exportada da nova action
- `src/index.ts`: adicionar o import e o registro da action em `actions: { ... }`

**Para modificar uma action existente:**
- Identificar exatamente o campo/bloco a mudar
- Editar cirurgicamente com `Edit` — não reescrever o arquivo inteiro

**Para remover uma action:**
- Remover o bloco em `integration.definition.ts`
- Remover a função em `src/<nome>.service.ts`
- Remover o import e a entrada em `src/index.ts`

**Regras invariáveis:**
- Nunca colocar lógica HTTP no `index.ts` — sempre no service
- O `index.ts` só importa e delega
- Manter o padrão de nomenclatura dos arquivos existentes
- Manter tratamento de erro no padrão `error?.response?.data?.errors?.[0]?.description || error?.response?.data?.message || error.message`
- Campos de output que a API pode retornar como `null` devem usar `.nullable()` — nunca `z.string()` puro para campos opcionais/suplementares. O SDK valida outputs estritamente e lança `code_execution_exception` se receber `null` num campo `z.string()`.

### PASSO 4 — Validar e buildar

Use o subagente `botpress-integration-tester`:

> "Use o subagente botpress-integration-tester para validar e buildar a integração em bp-integrations/<nome>/. Dependências já estão instaladas — rode apenas bp build e corrija erros TypeScript se houver."

### PASSO 5 — Atualizar Documentação
- Se ação foi adicionada/modificada/removida: atualizar tabela de Ações em `bp-integrations/docs/<nome>.md`
- Se schema de configuração mudou: atualizar tabela de Configuração em `bp-integrations/docs/<nome>.md`
- Se integração foi adicionada/removida: atualizar `bp-integrations/INTEGRATIONS.md`

### PASSO 6 — Confirmação final

Após o tester reportar sucesso, informe ao usuário:

- ✅ O que foi alterado (ex: "Action `createCharge` adicionada")
- Arquivos modificados
- Para fazer deploy: `cd bp-integrations/<nome> && bp deploy`

---

## Regras gerais
- Nunca fazer deploy automaticamente — apenas build
- Nunca reescrever arquivos inteiros para fazer uma mudança pequena — use `Edit` cirúrgico
- Nunca alterar `handlerRegister` ou `handlerUnregister` a menos que o usuário solicite explicitamente
- Sempre ler os arquivos antes de editar — nunca supor o estado atual
- Nunca adicionar dependências no `package.json` da integração — deps são gerenciadas na raiz do workspace em `bp-integrations/package.json` e acessadas via symlink
- Ao revisar ou adicionar campos de output: aplicar `.nullable()` em campos opcionais/suplementares (URLs, observações, identificadores externos como RENAVAM/chassi/placa, timestamps de modificação). Manter `z.string()` apenas para campos essenciais e sempre presentes.
