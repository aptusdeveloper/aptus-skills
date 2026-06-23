---
name: teste-bot-gurgel
description: Executa testes automatizados do bot Agner (Gurgel Veículos) via CUA computer-use, atuando como personas de lead no emulador Botpress Webchat. Suporta dry-run (1 persona) e full-run (todas pendentes). Pré-requisito: emulador aberto no browser numa tela secundária.
license: MIT
metadata:
  author: APTUS
  version: "1.0.0"
  domain: bot-testing
  triggers: testar bot, rodar teste, teste das personas, dry-run, full-run, testar agner, testar gurgel
  role: automation
  scope: qa-validation
  output-format: markdown file (leads-teste.md atualizado)
allowed-tools: mcp__cua-computer-use__*
---

# Teste Automatizado — Bot Agner (Gurgel Veículos)

Executa testes do bot contra as personas definidas em `leads-teste.md`, atuando como o lead via computer-use no emulador Botpress Webchat aberto no browser.

## Pré-requisitos

- Emulador do bot aberto no browser numa tela secundária: `cdn.botpress.cloud/webchat/v3.6/shareable.html?...`
- Arquivo de personas: `/Users/ederambrosio/Projetos/Aptus/prompts/clientes/Gurgel-Veiculos/leads-teste.md`
- MCP server `cua-computer-use` ativo (binário `cua-driver` em `/Users/ederambrosio/.local/bin/cua-driver`)

## Modos de execução

- **dry-run** (padrão — usar sempre na primeira vez): executa apenas a primeira persona com `resumo teste:` vazio, do início ao fim, e para. Reporta tempos, indicador de digitando descoberto, comportamento de fragmentação e condição de parada.
- **full-run**: executa todas as personas pendentes em sequência.

Se o usuário não especificou nada, usar **dry-run**.

## Arquivo de estado persistente

`/Users/ederambrosio/.claude/skills/teste-bot-gurgel/typing-selector.txt`

Contém o seletor CSS do indicador de "digitando" do emulador, descoberto no primeiro dry-run. Conteúdo: o seletor CSS encontrado, ou a string literal `ausente` se o emulador não tiver indicador. Este arquivo persiste entre invocações — não apagar.

---

## Etapa 0 — Setup

**0a. Ler argumento e verificar seletor persistente**

Verificar se `/Users/ederambrosio/.claude/skills/teste-bot-gurgel/typing-selector.txt` existe:
- Se existe: ler e guardar o seletor (ou a flag `ausente`). Ir direto para 0b. A Etapa 2 será ignorada.
- Se não existe: executar a Etapa 2 depois de encontrar o browser, e gravar o resultado antes de continuar para a Etapa 1.

**0b. Localizar o emulador no browser**

Usar `list_windows` para listar todas as janelas abertas. Identificar a janela do browser pela URL contendo `cdn.botpress.cloud` ou pelo título contendo "Gurgel Veículos". Anotar `pid` e `window_id` — esses valores serão passados em TODAS as chamadas subsequentes.

Usar `bring_to_front` com o `pid` para trazer o browser ao foco na tela secundária.

Usar `get_window_state` (pid + window_id) para confirmar que a UI do emulador está visível. Se o chat não aparecer, parar e pedir ao usuário para verificar se o browser está aberto.

**0c. Verificar JS Apple Events (OBRIGATÓRIO antes de qualquer coisa)**

Executar via `page` (action: `execute_javascript`):
```javascript
document.title
```
- Se retornar o título da página (ex: "Gurgel Veículos") → JS Apple Events está ativo. Continuar.
- Se retornar erro "A execução do JavaScript por AppleScript está desativada" → **PARAR IMEDIATAMENTE** e instruir o usuário:
  > "Preciso que você habilite o JavaScript via AppleScript no Chrome. Acesse a barra de menus do macOS (não o menu interno do Chrome) → Visualização → Desenvolvedor → Permitir o JavaScript do Eventos da Apple. Depois feche e reabra o Chrome completamente, e rode a skill novamente."
  
  ⚠️ **Atenção ao perfil do Chrome:** a configuração é por perfil. Certifique-se de habilitar no mesmo perfil que está com o Botpress Webchat aberto. Após habilitar, Chrome reinicia automaticamente — verifique se a aba com o emulador foi restaurada.

**0d. Confirmar selector do input**

Executar via `page` (action: `execute_javascript`):
```javascript
document.querySelector('.bpComposerInput') ? 'found' : 'not-found'
```
- Se retornar `found` → seletor `.bpComposerInput` confirmado para este emulador.
- Se retornar `not-found` → descobrir o seletor correto:
  ```javascript
  Array.from(document.querySelectorAll('textarea, [contenteditable="true"]')).map(e => e.className).join(' | ')
  ```
  Usar o `className` retornado como seletor nas chamadas subsequentes.

---

## Etapa 1 — Carregar persona (resumível)

Ler o arquivo de personas:
```
/Users/ederambrosio/Projetos/Aptus/prompts/clientes/Gurgel-Veiculos/leads-teste.md
```

Localizar a **primeira persona cujo campo `**resumo teste:**` está vazio** — ou seja, onde após os dois-pontos e a quebra de linha não há texto algum antes do próximo `---` ou `###`.

Extrair e internalizar completamente:
- Nome, grupo (COMPRADOR ou FORA-DO-SDR), tipo de contato
- Todas as 8 dimensões de personalidade (tom, escrita, cooperatividade, clareza, nível técnico, objeção, fragmentação, tendência a descarrilar)
- Fatos de compra (se COMPRADOR): orçamento, veículo de interesse, urgência, troca, pagamento
- Comportamento no teste descrito no perfil
- Primeira mensagem sugerida

Construir internamente o "character sheet" do ATOR — a partir deste ponto, você é o lead. Não saia do personagem durante o loop de conversa.

**Resumibilidade:** se a skill foi interrompida durante um teste anterior e o `resumo teste:` daquela persona não foi gravado, ela será a primeira da lista e o teste será refeito.

---

## Etapa 2 — Descoberta do indicador "digitando" (somente se `typing-selector.txt` não existe)

Esta etapa identifica como o emulador sinaliza que o bot está processando.

**2a.** Usar `page` (action: `get_text`, pid + window_id) para obter o snapshot textual inicial do chat.

**2b.** Usar `page` (action: `query_dom`, css_selector: `[class*='typing'], [class*='loading'], [data-testid*='typing'], [class*='is-typing'], [aria-label*='typing']`, pid + window_id) para verificar o baseline — esperado: zero resultados.

**2c.** Enviar "oi" usando o padrão JS (ver Etapa 4b):
```javascript
var el = document.querySelector('.bpComposerInput'); var s = Object.getOwnPropertyDescriptor(window.HTMLTextAreaElement.prototype, 'value').set; s.call(el, 'oi'); el.dispatchEvent(new Event('input', {bubbles: true})); el.dispatchEvent(new KeyboardEvent('keydown', {key: 'Enter', code: 'Enter', keyCode: 13, which: 13, bubbles: true, cancelable: true})); 'sent'
```
Aguardar ~3s.

**2d.** Repetir o `query_dom` da etapa 2b para detectar o indicador que aparece enquanto o bot processa.

**2e.** Gravar `typing-selector.txt`:
- Se o `query_dom` retornou elementos: gravar o seletor CSS mais específico que funcionou.
- Se nenhum seletor funcionou após 5s de polling: gravar a string literal `ausente`.

**2f.** Registrar internamente (para o relatório do dry-run) o que foi encontrado.

Após gravar o arquivo, aguardar a resposta completa do bot (usando a lógica da Etapa 4d com o seletor recém-descoberto) e então iniciar nova conversa antes de continuar.

---

## Etapa 3 — Iniciar nova conversa

**3a.** Clicar no botão "nova conversa" (ícone ✏️) via JavaScript:

```javascript
// Descobrir qual botão é o de nova conversa
Array.from(document.querySelectorAll('button')).map((b,i) => i + '|' + b.getAttribute('aria-label') + '|' + b.title + '|' + b.textContent.trim().substring(0,20)).join('; ')
```

Com o índice do botão correto, clicar:
```javascript
document.querySelectorAll('button')[INDEX_DO_BOTAO].click(); 'clicked'
```

Se não houver botão de nova conversa visível (chat já está limpo), pular esta etapa.

> ⚠️ **NÃO usar** `page action=click_element` — não está implementado no macOS (retorna "not implemented on this platform's page backend"). Usar sempre `execute_javascript` com `.click()` diretamente no elemento DOM.

**3b.** Usar `page` (action: `get_text`) para confirmar que o chat está zerado — nenhuma mensagem de conversa anterior visível, apenas a mensagem de abertura do bot (ou tela vazia).

Se não confirmar em 3 tentativas → registrar erro com descrição e parar.

---

## Etapa 4 — Loop de conversa (ATOR)

**Limite máximo: 15 turnos.** Manter um transcript em memória: array de `{ turno, role, texto }`.

### 4a. Compor mensagem como o lead

Você é o lead. Aplicar o estilo de escrita da persona sem exceção:

| Estilo | Como escrever |
|--------|--------------|
| Gírias | "cara", "mano", "daora", "show demais", "top", "vlw" |
| Erros de digitação | "voce" → "voce", "carro" → "caroo", "está" → "ta". Introduzir erros plausíveis, não corrigir |
| Tudo minúsculo | sem maiúsculas, pontuação mínima ou ausente |
| Áudio transcrito | frases corridas sem pontuação, como texto ditado sem pausas |
| Formal | linguagem culta, pontuação correta, tratamento de você/senhor |

Aplicar cooperatividade da persona:

| Cooperatividade | Como agir |
|----------------|-----------|
| Responde direto | Fornecer o que o bot pede sem resistência |
| Foge da pergunta | Quando o bot fizer a pergunta de qualificação, mudar de assunto ou responder algo não relacionado |
| Resp. c/ outra pergunta | Antes de dar qualquer informação, responder com uma contrapergunta |
| Se recusa | Resistir explicitamente: "pra que precisa disso?", "não vou falar meu nome não" |

**Regra fundamental:** não suavize o personagem. Se a persona é ríspida, seja ríspido. Se é evasiva, seja evasivo. A qualidade do teste depende disso.

**Nunca revelar que é um teste ou que é IA** dentro da conversa com o bot.

### 4b. Enviar mensagem(s) — MÉTODO ÚNICO VIA JAVASCRIPT

> ⚠️ **NÃO usar** `type_text` + `press_key` para enviar mensagens no Botpress Webchat. O textarea é controlado pelo React e CGEvent não aciona o onChange do React. O único método confiável é via `execute_javascript`.

**Padrão de envio de uma mensagem** (copiar e substituir `MENSAGEM_AQUI`):

```javascript
var el = document.querySelector('.bpComposerInput');
var s = Object.getOwnPropertyDescriptor(window.HTMLTextAreaElement.prototype, 'value').set;
s.call(el, 'MENSAGEM_AQUI');
el.dispatchEvent(new Event('input', {bubbles: true}));
el.dispatchEvent(new KeyboardEvent('keydown', {key: 'Enter', code: 'Enter', keyCode: 13, which: 13, bubbles: true, cancelable: true}));
'sent'
```

- `s.call(el, ...)` usa o setter nativo do HTMLTextAreaElement para que o React detecte a mudança.
- `dispatchEvent('input')` aciona o `onChange` do React para atualizar o estado interno.
- `dispatchEvent('keydown' Enter)` aciona o handler de submit do React.
- Terminar com `'sent'` (string literal) garante retorno não-vazio para confirmar execução.

**Regra crítica sobre `execute_javascript`:** NÃO usar a palavra-chave `return`. A última expressão do script é automaticamente o valor retornado pelo AppleScript. Se usar `return`, o AppleScript retorna "missing value" em vez do valor real.

**Verificação de envio** (opcional, fazer se houver dúvida):
```javascript
document.querySelector('.bpComposerInput').value
```
Deve retornar string vazia — confirma que o textarea foi limpo após o envio.

**Se persona tem fragmentação "mensagens picadas":**
- Dividir a mensagem em 2-4 fragmentos curtos e naturais.
- Enviar cada fragmento com o padrão JS acima + aguardar ~1.5s antes do próximo (basta chamar o próximo tool call — o delay natural de processamento já cobre os 1.5s).
- O Stage 1/Stage 2 de espera só começa **após o último fragmento** enviado.

> ⚠️ **Nota:** o dry-run deve observar e reportar se o bot agrupou todos os fragmentos numa resposta única ou se respondeu cada um individualmente. Não assumir comportamento — observar.

**Se persona tem fragmentação "textão único":**
- Usar o padrão JS acima com toda a mensagem de uma vez.

### 4c. Aguardar resposta — Stage 1 (bot começar, timeout 45s)

Após o último fragmento enviado:

1. Snapshot: `page` (action: `get_text`) → salvar como `texto_antes`.
2. Poll a cada ~3s: `page` (action: `get_text`) → comparar com `texto_antes`.
3. Quando o texto mudar (nova bolha apareceu ou indicador surgiu) → entrar no Stage 2.
4. Se 45s completos sem nenhuma mudança → registrar condição `timeout_stage1`, encerrar este teste da persona.

### 4d. Aguardar resposta — Stage 2 (bot terminar)

Usar o seletor do `typing-selector.txt`:

**Se seletor existe (não é `ausente`):**
- Poll a cada ~2s: `page` (action: `query_dom`, css_selector: [seletor]).
- Se retorna elementos → bot ainda está digitando. Resetar o contador de estabilidade para zero.
- Se não retorna → incrementar contador. Quando contador ≥ 2 (~4s consecutivos sem indicador) → resposta completa.
- Entre uma bolha e outra o indicador pode sumir e voltar — se voltar, resetar o contador.

**Se `ausente` (fallback de estabilidade pura):**
- Poll a cada ~2s: `page` (action: `get_text`).
- Quando o texto ficar estável (sem mudança) por ~10s seguidos → resposta completa.

**Segurança:** se passar 90s no Stage 2 sem fechar → capturar o estado atual e prosseguir de qualquer forma.

### 4e. Ler resposta do bot

`page` (action: `get_text`) → texto completo do chat atual.

Identificar o **delta** desde o último snapshot: as linhas/parágrafos novos que não existiam antes. Adicionar ao transcript como `{ turno, role: 'bot', texto: [delta] }`.

### 4f. Verificar condições de parada

| Condição | Como detectar |
|----------|---------------|
| Handoff confirmado | Texto do bot contém "transferindo", "vou te conectar", "atendente humano", "equipe de vendas", ou a UI muda para estado de "conversa encerrada" |
| Objetivo cumprido (COMPRADOR) | Bot coletou os dados principais de qualificação (nome, pagamento, veículo) e fez handoff |
| Objetivo cumprido (FORA-DO-SDR) | Bot reconheceu o fora de escopo, foi cordial, e encerrou ou transferiu |
| Loop real | Ver critério abaixo |
| Bot não respondeu | Condição `timeout_stage1` |
| Teto de turnos | turno ≥ 15 |

**Critério de loop real — ler com atenção:**

Só declarar loop quando **ambas** as condições forem verdadeiras:
1. O bot repetiu a mesma resposta pela **3ª vez consecutiva**, E
2. O lead também está repetindo o mesmo padrão de desvio/conteúdo sem introduzir nenhum dado novo.

**NÃO é loop** quando:
- O bot re-pergunta a mesma qualificação porque o lead desviou → isso é comportamento correto sob resistência
- O lead está variando as respostas (mesmo que evasivas) → há progresso na conversa; continuar

Se condição de parada atingida: registrar qual condição disparou. Não continuar o loop.

### 4g. Próxima mensagem

Se nenhuma condição de parada: incrementar turno, voltar ao passo 4a com a próxima mensagem da persona.

---

## Etapa 5 — Avaliar (subagent retorna; agente principal grava)

**O ATOR terminou. Agora é o AVALIADOR.**

O contexto do ATOR não é passado ao subagent — o subagent opera com contexto limpo para evitar viés de confirmação. Ele não grava nada no arquivo; apenas retorna o texto do resumo.

**Disparar um subagent** com o prompt abaixo, substituindo os campos em colchetes:

---

```
Você é um avaliador de qualidade de bot de atendimento. Analise a conversa abaixo e produza uma avaliação objetiva.

CONTEXTO DO BOT:
Este é um bot SDR (Sales Development Representative) de uma concessionária de veículos usados chamada
Gurgel Veículos. O bot se chama Agner e tem como objetivo: (1) identificar o veículo de interesse do
cliente, (2) qualificar a intenção de compra (forma de pagamento, urgência, possibilidade de troca),
(3) coletar nome e dados de contato, e então (4) encaminhar o lead para o time de vendas humano.

Quando o bot não consegue avançar (cliente fora do escopo, conversa travada, cliente não é um comprador),
ele deve encerrar de forma cordial e transferir para atendimento humano. Isso é chamado de "encerramento
por fallback" e é o comportamento CORRETO para essas situações — não é uma falha.

PERSONA DO LEAD QUE FOI SIMULADA:
Nome: [nome]
Grupo: [COMPRADOR | FORA-DO-SDR]
Tipo de contato: [tipo]
Tom/emoção: [valor]
Estilo de escrita: [valor]
Cooperatividade: [valor]
Clareza do objetivo: [valor]
Nível técnico: [valor]
Objeção principal: [valor]
[Se COMPRADOR] Orçamento: [valor] | Veículo: [valor] | Urgência: [valor] | Troca: [sim/não + dados] | Pagamento: [valor]

CRITÉRIO DE SUCESSO para este tipo de persona:

Para COMPRADOR quente:
  ✓ Bot identificou o veículo de interesse
  ✓ Bot perguntou e registrou a forma de pagamento
  ✓ Bot coletou nome e cidade do cliente
  ✓ Bot encaminhou para o time de vendas humano ao final

Para COMPRADOR pesquisando / morno:
  ✓ Bot tentou qualificar sem forçar ou perder o cliente
  ✓ Bot ofereceu informações úteis do estoque
  ✓ Se o cliente ficou muito evasivo, bot encerrou cordialmente (encerramento por fallback é correto)

Para COMPRADOR quer trocar:
  ✓ Bot coletou dados do veículo atual (marca, modelo, ano, km)
  ✓ Bot também qualificou a intenção de compra do novo veículo
  ✓ Bot encaminhou para o time ao final

Para COMPRADOR de anúncio (OLX / Instagram / Facebook):
  ✓ Bot identificou o veículo do anúncio
  ✓ Bot qualificou pagamento e coletou dados
  ✓ Bot encaminhou para o time ao final

Para COMPRADOR comparando concorrente:
  ✓ Bot apresentou informações do estoque de forma útil
  ✓ Bot não inventou descontos ou condições não previstas
  ✓ Bot encaminhou para o time ao final

Para FORA-DO-SDR (qualquer tipo — alguém querendo vender o próprio carro, pós-venda/problema com carro
já comprado, dúvida sobre documentação/transferência, pergunta de localização/horário, número errado,
spam/fornecedor, procurando emprego, ou tentando provocar/quebrar o bot):
  ✓ Bot reconheceu que o assunto está fora do escopo de vendas de veículos
  ✓ Bot foi cordial e não respondeu com informações erradas ou inventadas
  ✓ Bot encerrou ou transferiu para atendimento humano
  ✗ Falha: bot tentou vender para alguém que não quer comprar
  ✗ Falha: bot inventou informações (endereço, preço, política) que não tem como saber

TRANSCRIPT COMPLETO:
[turno 1] LEAD: [texto]
[turno 2] BOT: [texto]
[continuar para todos os turnos]

CONDIÇÃO DE PARADA QUE DISPAROU: [nome da condição]
TOTAL DE TURNOS: [n]

Produza em português um resumo com no máximo 200 palavras, contendo:
1. **Veredito:** PASSOU / PASSOU COM RESSALVAS / FALHOU
2. **O que o bot fez bem** (1-3 pontos)
3. **Onde travou ou falhou** — se houver, citar o trecho exato da resposta do bot que disparou o problema
4. **Nº de turnos até resolução**
5. **Condição de parada que disparou**

Retorne apenas o texto do resumo, sem cabeçalhos extras.
```

---

**Após o subagent retornar o texto do resumo:**

O agente principal (não o subagent) localiza no arquivo `leads-teste.md` o campo `**resumo teste:**` da persona corrente (identificada pelo número e nome). Escreve o texto retornado logo após os dois-pontos. Nenhum outro campo ou persona é tocado.

Confirmar que a escrita foi bem-sucedida antes de prosseguir.

---

## Etapa 6 — Finalizar

### dry-run → parar e reportar ao usuário

Após a primeira persona ser concluída e o resumo gravado, parar e reportar:

1. **Tempo de Stage 1 por turno** (quanto demorou o bot começar a responder em cada turno)
2. **Tempo de Stage 2 por turno** (quanto demorou o bot terminar cada resposta)
3. **Conteúdo de `typing-selector.txt`** — qual seletor foi gravado, ou "ausente"
4. **Verificação de fragmentação** (se a persona era "mensagens picadas"): o bot agrupou os fragmentos numa resposta única, ou respondeu cada um separadamente?
5. **Condição de parada que disparou**
6. **Hesitações da automação**: elemento não encontrado, timeout, fallback ativado em alguma etapa
7. **Recomendação** para o full-run se algum ajuste for necessário

### full-run → continuar para próxima persona

Voltar para a Etapa 1 (ler o arquivo, pegar a próxima com `resumo teste:` vazio).

Encerrar quando não houver mais personas com resumo vazio.

Reportar sumário final:
```
Teste concluído: [n]/20 personas testadas
PASSOU: [n]
PASSOU COM RESSALVAS: [n]
FALHOU: [n]
```

---

## Regras gerais

### Sobre o método de interação com o browser

| Ação | Método correto | Método PROIBIDO |
|------|---------------|-----------------|
| Digitar mensagem no chat | `execute_javascript` com native setter + dispatchEvent | `type_text`, `press_key tab`, `click_element` |
| Clicar em botão DOM | `execute_javascript` com `.click()` | `page action=click_element` (não implementado no macOS) |
| Ler resposta do bot | `page action=get_text` | — |
| Verificar elemento | `execute_javascript` com querySelector | `query_dom` (só funciona como fallback AX se JS desativado) |
| `execute_javascript` com retorno | Usar última expressão sem `return` | `return valor` (causa "missing value" no AppleScript) |

- **JS Apple Events é pré-requisito absoluto.** Sem ele, nada funciona. Verificar na Etapa 0c antes de qualquer coisa.
- **Fidelidade à persona acima de tudo:** o ator não suaviza, não corrige o próprio português, não "ajuda" o bot se a persona não ajuda.
- **Nunca revelar que é um teste** — o lead é um lead.
- **Não editar nada do `leads-teste.md` além do campo `resumo teste:`** da persona corrente.
- **Em caso de erro inesperado a meio caminho:** registrar o estado, deixar o `resumo teste:` vazio (para retomada) e parar de forma limpa. Reportar ao usuário o que aconteceu.
