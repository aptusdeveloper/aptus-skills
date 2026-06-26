---
name: gurgel
description: Contextualização silenciosa completa do cliente Gurgel Veículos — lê todos os arquivos relevantes do cliente (CLAUDE.md, prompt, integrações, backend) e retorna apenas OK para prosseguir.
license: MIT
metadata:
  author: APTUS
  version: "1.0.0"
  domain: context
  triggers: gurgel, contexto gurgel, cliente gurgel
  role: specialist
  scope: context-loading
  output-format: OK
---

# Gurgel — Contextualização do Cliente

Você é um especialista da APTUS com conhecimento completo do projeto Gurgel Veículos.
Sua única tarefa agora é absorver silenciosamente o contexto completo do cliente.

---

## Etapa 1 — Ler contexto do cliente (silenciosamente)

Leia os arquivos abaixo sem comentar, sem resumir, sem interagir. Apenas absorva.

### Contexto principal
1. `/Users/ederambrosio/Projetos/Aptus/clientes/Gurgel/CLAUDE.md`

### Prompt do bot
2. `/Users/ederambrosio/Projetos/Aptus/prompts/clientes/Gurgel-Veiculos/prompt_gurgel.md`
3. `/Users/ederambrosio/Projetos/Aptus/prompts/clientes/Gurgel-Veiculos/guia-prompt-gurgel.md`

### Integração autocerto (exclusiva Gurgel)
4. `/Users/ederambrosio/Projetos/Aptus/bp-integrations/autocerto/integration.definition.ts`
5. `/Users/ederambrosio/Projetos/Aptus/bp-integrations/autocerto/src/autocerto.service.ts`

### Módulo aws-backend
6. `/Users/ederambrosio/Projetos/Aptus/aws-backend/src/message-manager/client-endpoints/gurgel-veiculos/gurgel-veiculos.controller.ts`
7. `/Users/ederambrosio/Projetos/Aptus/aws-backend/src/message-manager/client-endpoints/gurgel-veiculos/gurgel-veiculos.service.ts`

---

## Etapa 2 — Responder

Após ler todos os arquivos acima, responda **apenas**:

```
OK
```

Nada mais. Sem resumos, sem listas, sem comentários. Apenas `OK`.
