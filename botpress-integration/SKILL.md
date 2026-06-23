---
name: botpress-integration
description: Criação de nova integração Botpress action-only. Copia o template, lê a documentação da API via subagente, gera os arquivos da integração e valida o build. Use quando o usuário pedir para criar uma nova integração Botpress.
license: MIT
metadata:
  author: APTUS
  version: "1.0.0"
  domain: botpress
  triggers: criar integração, nova integração botpress, integrar API
  role: specialist
---
# Skill: Criar Nova Integração Botpress

## Quando usar esta skill
Use quando o usuário pedir para criar uma nova integração Botpress do tipo **action-only** (integração que executa ações numa API externa — buscar, criar, atualizar dados).

## ⚠️ Fora do escopo desta skill
Esta skill **não cobre** integrações do tipo canal/webhook (integrações que recebem mensagens de plataformas externas como WhatsApp, Telegram, etc). Se o usuário pedir esse tipo, informe que não está coberto e interrompa.

---

## Informações necessárias antes de começar

Se o usuário não informar, pergunte:

1. **Nome da integração** em kebab-case (ex: `kommo`, `asaas`, `rd-station`) — será o nome do diretório e dos arquivos
2. **URL ou caminho da documentação da API** a ser integrada
3. **Esta integração recebe mensagens ou webhooks de entrada?** — se sim, esta skill não se aplica

---

## Fluxo de execução

### PASSO 0 — Injetar Contexto
Ler antes de qualquer ação:
- `bp-integrations/CLAUDE.md` — focar nas seções: **Padrões Obrigatórios**, **Dependências**, **Template de Nova Integração**
- `bp-integrations/DECISIONS.md` — verificar decisões recentes que afetam a integração
- `bp-integrations/INTEGRATIONS.md` — integrações existentes. Se o arquivo não existir ainda, criar a estrutura inicial antes de prosseguir

### PASSO 1 — Copiar o template base e remover o service do template
```bash
cp -r bp-integrations/integracao-modelo bp-integrations/<nome-da-integracao>
rm bp-integrations/<nome-da-integracao>/src/integracao-modelo.service.ts
```

O arquivo `integracao-modelo.service.ts` deve ser removido após a cópia — o service correto (`<nome>.service.ts`) será gerado no PASSO 4.

### PASSO 2 — Atualizar o package.json da nova integração
Abra `bp-integrations/<nome-da-integracao>/package.json` e atualize:
- Campo `name` → `<nome-da-integracao>`
- Campo `integrationName` (se existir) → `aptus/<nome-da-integracao>`

**Não declare dependências.** `axios`, `@botpress/sdk`, `@botpress/client` e demais libs são herdadas da raiz do workspace via symlink — declarar localmente causaria duplicação. Os campos `dependencies` e `devDependencies` devem permanecer `{}`.

Após atualizar o `package.json`, adicione o nome da integração no campo `workspaces` do arquivo `bp-integrations/package.json` da raiz e rode `./setup.sh` para criar os symlinks.

### PASSO 3 — Delegar leitura da documentação
Use o subagente `api-doc-reader` para extrair os endpoints da API. Informe o diretório da integração para que o agente salve o arquivo `api-analysis.md`:

> "Use o subagente api-doc-reader para ler a documentação em [URL/caminho] e extrair todos os endpoints, métodos HTTP, schemas de request/response e campos de configuração necessários. Salve o resultado em bp-integrations/<nome-da-integracao>/api-analysis.md."

Aguarde o retorno em JSON antes de prosseguir.

### PASSO 4 — Delegar geração dos arquivos
Com o JSON retornado pelo `api-doc-reader`, use o subagente `botpress-integration-writer`:

> "Use o subagente botpress-integration-writer para gerar os arquivos da integração '<nome>' com base neste JSON: [JSON]. Os arquivos devem ser escritos em bp-integrations/<nome-da-integracao>/."

Arquivos que serão gerados/substituídos:
- `integration.definition.ts`
- `src/index.ts`
- `src/<nome-da-integracao>.service.ts`
- `src/<nome-da-integracao>.test.ts`
- `hub.md`
- `package.json` (adicionadas devDependencies de teste: vitest, axios-mock-adapter)

### PASSO 5 — Delegar validação e build
Use o subagente `botpress-integration-tester`:

> "Use o subagente botpress-integration-tester para validar e buildar a integração em bp-integrations/<nome-da-integracao>/."

### PASSO 6 — Atualizar Documentação
- Atualizar `bp-integrations/INTEGRATIONS.md`: adicionar linha da nova integração na tabela (nome, tipo, API externa, ações)
- Criar `bp-integrations/docs/<nome>.md` com:
  - Tipo (actions only / canal bidirecional)
  - API Externa (URL base, método de auth)
  - Tabela de Configuração (campos do config schema Zod)
  - Tabela de Ações (nome → descrição)
  - Canal `webhook` se aplicável (mensagens suportadas, tags)

### PASSO 7 — Confirmação final
Após o tester reportar sucesso, informe ao usuário:

- ✅ Integração `<nome>` criada com sucesso
- Arquivos gerados: `integration.definition.ts`, `src/index.ts`, `src/<nome>.service.ts`, `src/<nome>.test.ts`, `hub.md`
- Para fazer deploy: `cd bp-integrations/<nome-da-integracao> && bp deploy`

---

## Estrutura esperada ao final

```
bp-integrations/
  <nome-da-integracao>/
    integration.definition.ts   ← contrato: actions, configuration
    src/
      index.ts                  ← registra handlers, delega ao service
      <nome>.service.ts         ← lógica HTTP isolada + handlers de register/unregister
    hub.md                      ← nome e descrição para o Botpress Hub
    package.json
    tsconfig.json
    .botpress/                  ← gerado pelo bp build
```

---

## Regras de schema Zod — campos nullable

O Botpress SDK valida outputs de actions estritamente: um campo definido como `z.string()` que receba `null` da API lança `code_execution_exception` em runtime.

**Ao instruir o `botpress-integration-writer` a gerar os schemas de output:**

- Campos que representam dados **essenciais e sempre presentes** (ex: IDs, nomes de classificação, timestamps de criação): `z.string()`
- Campos que representam dados **suplementares ou opcionais** que a API pode não preencher: `z.string().nullable()`

Exemplos de campos que tipicamente devem ser `.nullable()` em APIs de terceiros:
- URLs (vídeo, imagem, link externo)
- Campos de observação/descrição livre
- Identificadores de registro externo (RENAVAM, chassi, CPF, placa)
- Timestamps de modificação/atualização (ausentes quando o registro nunca foi editado)
- Qualquer campo marcado como "opcional" na documentação da API

Ao passar o JSON do `api-doc-reader` para o `botpress-integration-writer`, instruir explicitamente:
> "Campos opcionais ou que a API pode retornar como null devem usar `.nullable()` no schema Zod de output. Prefira `.nullable()` a `.string()` para quaisquer campos de texto não essenciais."

---

## Regras gerais
- Nunca fazer deploy automaticamente — apenas build
- Sempre usar `integracao-modelo` como base, nunca criar do zero
- Nunca colocar lógica HTTP direta no `index.ts` — sempre no service
- O `index.ts` deve apenas importar e delegar — igual ao template
- **Não customizar `handlerRegister` nem `handlerUnregister`** a menos que seja estritamente necessário (ex: a API exige registro de webhook na ativação) ou que o usuário solicite explicitamente — use a implementação mínima do template (log simples / no-op)
