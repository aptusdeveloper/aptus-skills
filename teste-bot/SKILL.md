---
name: teste-bot
description: Executa testes automatizados de bot via Chat API (bot-tests), interpreta falhas, sugere e aplica correções no prompt, e re-executa. Sempre abre a UI em localhost:4444 para visualização. Use quando o usuário pedir para testar um bot, rodar os testes, verificar se o bot está correto, ou checar regressão após editar um prompt.
license: MIT
metadata:
  author: APTUS
  version: "1.0.0"
  domain: bot-testing
  triggers: testar bot, rodar testes, teste automatico, verificar bot, checar regressao, npm run test
  role: automation
  scope: qa-validation
  output-format: inline report
allowed-tools: Bash, Read, Edit, Write
---

# Skill — Teste Automatizado de Bot (bot-tests)

Você é o responsável por rodar testes automatizados, interpretar resultados e fechar o ciclo de qualidade.

---

## Contexto do projeto

- Diretório: `/Users/ederambrosio/Projetos/Aptus/bot-tests`
- Bots disponíveis: `gurgel` (único por enquanto)
- Cenários do Gurgel: `fotos`, `handoff`, `canais`, `opcionais`, `buscarVeiculos`
- Prompts dos bots: `/Users/ederambrosio/Projetos/Aptus/prompts/clientes/`
- A UI abre automaticamente em `http://localhost:4444` a cada execução interativa

---

## Etapa 1 — Interpretar o pedido

Antes de rodar qualquer coisa, identificar:

| O que o usuário pediu | Comando a usar |
|-----------------------|----------------|
| "testar tudo" / "todos os cenários" | `npm run test:gurgel` |
| "testar fotos" / cenário específico | `npm run test:gurgel:fotos` |
| "testar X e Y" (múltiplos) | rodar em lote: um comando por cenário, paralelamente se possível |
| Sem especificar bot | assumir `gurgel` |
| Sem especificar cenário | rodar todos |

Se o usuário especificou um **filtro por substring** que não bate exatamente com um script do package.json, usar:
```bash
cd /Users/ederambrosio/Projetos/Aptus/bot-tests && npx tsx src/index.ts --bot gurgel --scenario "texto do filtro"
```

---

## Etapa 2 — Rodar os testes

```bash
cd /Users/ederambrosio/Projetos/Aptus/bot-tests && npm run test:<bot>[:<cenário>]
```

- A UI abre automaticamente no browser. Informar ao usuário: "UI aberta em http://localhost:4444"
- Aguardar o processo terminar (pode levar até 2–3 minutos por cenário, pois o bot tem timeout de 25s por resposta)
- Capturar stdout completo para análise

**Formato de saída do runner:**
```
⏳  nome do cenário        ← iniciando
✅  nome do cenário        ← passou
❌  nome do cenário        ← falhou
     ✗ label da asserção  ← detalhe da falha
🎉  3/3 passou             ← resumo final
⚠️  2/3 passou — 1 falhou  ← resumo com falha
```

---

## Etapa 3 — Interpretar resultado

### Se todos passaram

Reportar succinctamente:
```
✅ Todos os cenários passaram (N/N).
```

Não adicionar análise extra se não foi pedida.

### Se algum falhou

Para cada cenário que falhou:

**3a. Ler o arquivo do cenário:**
```
/Users/ederambrosio/Projetos/Aptus/bot-tests/src/bots/gurgel/scenarios/<nome>.ts
```

**3b. Ler o prompt do bot:**
```
/Users/ederambrosio/Projetos/Aptus/prompts/clientes/Gurgel-Veiculos/
```
Listar arquivos e ler o prompt mais recente (ou o que o usuário indicar).

**3c. Analisar a causa da falha:**

| Tipo de asserção que falhou | Onde investigar |
|-----------------------------|-----------------|
| `bot respondeu` = false | bot não respondeu — verificar webhookId no .env, ou timeout muito curto |
| `recebeu >= N imagens` | prompt não manda imagens na situação testada |
| `menciona X` (hasKeyword) | bot não está mencionando a palavra/padrão esperado |
| `handoff ocorreu` | bot não está transferindo quando deveria |
| Erro de timeout | bot demorou >25s — pode ser API lenta; tentar aumentar `initialTimeout` |

**3d. Formular hipótese:**

Antes de sugerir qualquer mudança, explicar em 2-3 frases:
- O que o cenário esperava
- O que provavelmente está acontecendo no prompt
- Se é um problema de prompt ou de cenário (asserção errada)

---

## Etapa 4 — Propor e aplicar correção

### Se o problema é no prompt

Perguntar ao usuário se pode editar o prompt. Se confirmado (ou se o usuário pediu autonomia):

1. Ler o arquivo do prompt
2. Aplicar a correção cirúrgica (sem mexer no que não foi pedido)
3. Salvar
4. Informar o que foi alterado

> **Nunca** alterar o prompt sem confirmar com o usuário, a menos que ele tenha dado autonomia explícita.

### Se o problema é no cenário (asserção muito restritiva)

Explicar por que a asserção pode ser inadequada e sugerir a correção. Perguntar antes de editar.

### Se é timeout

Sugerir aumentar `initialTimeout` no cenário específico:
```typescript
const r1 = await session.waitForResponses({ initialTimeout: 40_000 })
```

---

## Etapa 5 — Re-executar após correção

Após aplicar qualquer correção, re-rodar **apenas o(s) cenário(s) que falharam**:

```bash
cd /Users/ederambrosio/Projetos/Aptus/bot-tests && npm run test:gurgel:<cenário>
```

Reportar se a correção resolveu. Se ainda falhar, repetir o ciclo a partir da Etapa 3 — mas **no máximo 2 tentativas por cenário** sem pedir orientação ao usuário.

---

## Etapa 6 — Relatório final

Após todos os ciclos, reportar:

```
## Resultado dos testes — <bot> (<data>)

| Cenário        | Resultado | Ação tomada            |
|----------------|-----------|------------------------|
| fotos          | ✅ passou  | —                      |
| handoff        | ✅ passou  | —                      |
| canais         | ❌ falhou  | corrigido no prompt    |
| canais (retry) | ✅ passou  | —                      |
```

Se houver falhas que não foram resolvidas, listar com a hipótese e o que impede a correção.

---

## Regras gerais

- **Sempre rodar com a UI** (`npm run test:*`, nunca `npm run ci:*`) exceto se o usuário pedir modo headless.
- **Respostas do bot são não-determinísticas** (LLM): uma falha isolada pode ser fluke. Se um cenário falhar por uma asserção de texto exato, considerar rodar uma segunda vez antes de concluir que é bug.
- **Nunca inventar causa de falha** — sempre ler o cenário e o prompt antes de formular hipótese.
- **Nunca editar cenários para fazer os testes passarem artificialmente** — o cenário reflete o comportamento esperado do bot. Se o cenário estiver errado, deixar claro e pedir confirmação.
- **Timeout de 25s por resposta** é o padrão. Bots que chamam APIs externas (buscar veículos, etc.) podem precisar de 40s.
