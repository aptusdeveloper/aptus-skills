---
name: handoff
description: Cria um arquivo de contexto com tudo que foi feito na conversa atual e exibe um prompt pronto para iniciar um novo chat limpo com contexto preservado. Use quando o contexto do chat estiver muito longo e quiser continuar em sessão limpa sem perder o fio da meada.
license: MIT
metadata:
  author: APTUS
  version: "1.0.0"
  domain: workflow
  triggers: handoff, contexto longo, chat novo, sessão limpa
  role: workflow
  scope: meta
  output-format: markdown file + prompt
---

# Handoff — Transferência de Contexto

Seu trabalho é capturar tudo que importa desta conversa, salvar num arquivo de handoff e gerar
um prompt pronto para o usuário colar num novo chat limpo.

---

## Etapa 1 — Análise da conversa (silenciosa)

Revise **toda a conversa atual** e extraia:

1. **Objetivo geral da sessão** — o que o usuário veio fazer
2. **O que foi concluído** — decisões tomadas, arquivos criados/editados, tarefas finalizadas
3. **Ponto atual** — onde paramos exatamente (última ação, última decisão)
4. **Pendências** — o que ainda falta fazer (tarefas em aberto, próximos passos acordados)
5. **Contexto técnico crítico** — caminhos de arquivos relevantes, nomes de variáveis/funções/entidades discutidas, erros que foram encontrados, padrões acordados
6. **Decisões e preferências do usuário** — escolhas feitas que devem ser mantidas no próximo chat
7. **Avisos** — riscos conhecidos, coisas para não esquecer, coisas a evitar

Não interaja com o usuário durante esta etapa — apenas absorva.

---

## Etapa 2 — Gerar o arquivo de handoff

Determine o caminho do arquivo:
- Se existir `.claude/` no diretório atual, salve em `.claude/handoff.md`
- Caso contrário, salve em `handoff.md` no diretório de trabalho atual (nunca use `/tmp/`)

Crie o arquivo com esta estrutura:

```markdown
# Handoff — [título curto descrevendo o objetivo da sessão]

**Data:** [data/hora atual]
**Projeto:** [nome do projeto ou diretório de trabalho]

---

## Objetivo da sessão
[O que o usuário veio fazer neste chat — 1 a 3 frases]

## O que foi feito
[Lista clara e objetiva do que foi concluído — use bullets]
- ...

## Ponto atual
[Onde paramos — seja específico. Ex: "Implementamos X mas ainda não testamos. O último erro foi Y."]

## Pendências
[O que ainda falta — use bullets com prioridade se relevante]
- [ ] ...

## Contexto técnico
[Só o que é não-óbvio e seria difícil de redescobrir lendo o código]
- Arquivos relevantes: ...
- Variáveis/entidades discutidas: ...
- Padrões acordados: ...
- Erros conhecidos: ...

## Decisões e preferências
[Escolhas que o usuário fez e que devem ser respeitadas]
- ...

## Avisos
[Riscos, armadilhas ou coisas para não esquecer]
- ...

## Sugestão de continuação
[Uma pergunta curta e direta — máximo 1 linha — que o novo Claude deve fazer ao usuário após carregar o contexto. Deve sugerir a próxima ação mais óbvia com base nas pendências. Ex: "Continuar implementando o endpoint de X?" ou "Testar o fluxo de Y agora?"]
```

Substitua todos os placeholders com o conteúdo real extraído da conversa. Seja preciso e objetivo —
este arquivo vai ser lido por uma instância nova do Claude que não tem nenhuma memória desta conversa.

---

## Etapa 3 — Exibir o prompt de novo chat

Após salvar o arquivo, exiba o seguinte bloco ao usuário:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  HANDOFF PRONTO — abra um novo chat e cole este prompt:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Em seguida, exiba o prompt de handoff formatado como bloco de código copiável:

```
Leia o arquivo de contexto em [CAMINHO DO ARQUIVO SALVO], absorva todo o conteúdo silenciosamente e depois apague o arquivo. Quando terminar, responda apenas com a pergunta que está na seção "Sugestão de continuação" do arquivo — nada mais, nada menos.
```

Substitua `[CAMINHO DO ARQUIVO SALVO]` pelo caminho real onde salvou.

Depois do prompt, acrescente:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Este chat pode ser encerrado.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Regras importantes

- **Não pergunte nada** — apenas analise, escreva o arquivo e exiba o prompt. A skill inteira deve ser executada sem interação.
- **Seja específico**: o arquivo serve para uma instância de Claude sem memória alguma desta conversa. Se faltar contexto, ela vai errar.
- **Não filtre por importância** — inclua tudo que for não-óbvio, mesmo que pareça menor. Melhor sobrar do que faltar.
- **Não mencione "arquivo de handoff" no resumo da sessão** — o arquivo não faz parte do trabalho que estava sendo feito.
