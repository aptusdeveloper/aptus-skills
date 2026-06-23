---
name: sync-aptus
description: Sincroniza todos os repositórios da APTUS — commita mudanças pendentes com mensagens geradas por IA e sobe para o remoto correto. Use quando o usuário pedir para "subir tudo", "commitar tudo", "fazer push", "sincronizar os repositórios" ou qualquer variação disso.
license: MIT
metadata:
  author: APTUS
  version: "2.0.0"
  triggers: subir tudo, commitar tudo, push, sincronizar, sobe tudo, commita e sobe, commitar e subir, subir os repos, git push tudo
---

# Sync APTUS — Sincronização de Repositórios

Execute o script de sincronização da APTUS **sem fazer perguntas** e **sem pedir confirmação prévia**.

## Instrução única

Rode o seguinte comando via Bash:

```bash
/Users/ederambrosio/Projetos/Aptus/sync.sh
```

O script já cuida de tudo automaticamente:
- Verifica mudanças em cada projeto (aptus-hub, aws-backend, bp-integrations, idealizacoes, prompts)
- Faz `git pull --ff-only` antes de commitar — **obrigatório** porque Eder e Tiago trabalham direto na `main` dos três repositórios principais
- Se o pull falhar (históricos divergiram), avisa e pula o repo — não tenta resolver conflitos automaticamente
- Gera mensagens de commit semânticas via Claude CLI analisando o diff
- Commita e faz push para `origin/main`

## Workflow de dois devs na main

Os repositórios `aws-backend`, `aptus-hub` e `bp-integrations` são usados por **Eder e Tiago simultaneamente, ambos na branch `main`**. Por isso:

- O script sempre puxa o remoto antes de commitar
- Se o Tiago tiver subido algo que diverge do local, o script avisa e não sobrescreve — é necessário resolver manualmente com `git pull` + resolução de conflito

## Após executar

Mostre o output do script para o usuário. Se algum projeto tiver erro ou aviso de conflito, informe qual foi e oriente o usuário a fazer o pull e resolver manualmente.

Se o usuário passar o argumento `--dry-run` ou pedir para "ver o que seria commitado" sem realmente commitar, rode:

```bash
/Users/ederambrosio/Projetos/Aptus/sync.sh --dry-run
```
