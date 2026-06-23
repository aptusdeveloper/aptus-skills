# sync-skills

Sincroniza as skills APTUS com o repositório GitHub compartilhado entre Eder e Tiago.

## O que faz

1. Puxa atualizações remotas (`git pull --rebase`)
2. Faz stage de todas as mudanças locais
3. Se houver mudanças, gera uma mensagem de commit descritiva e faz push

## Quando usar

- Após criar ou editar qualquer skill
- Antes de começar a trabalhar, para pegar skills atualizadas pelo parceiro

## Execução

```bash
cd ~/.claude/skills

# 1. Puxa atualizações do remoto
git pull --rebase origin main

# 2. Verifica se há mudanças locais
STATUS=$(git status --porcelain)

if [ -z "$STATUS" ]; then
  echo "✓ Nenhuma mudança local. Skills já sincronizadas."
  exit 0
fi

# 3. Lista as mudanças para gerar a mensagem de commit
echo "Mudanças detectadas:"
git status --short

# 4. Stage de tudo
git add -A

# 5. Gera mensagem de commit com base nas mudanças
CHANGED=$(git diff --cached --name-only | sed 's|/.*||' | sort -u | tr '\n' ', ' | sed 's/,$//')
MSG="update skills: ${CHANGED}"

# 6. Commit e push
git commit -m "$MSG"
git push origin main

echo "✓ Skills sincronizadas com sucesso."
```

## Instrução para o Claude

Execute os comandos bash acima na sequência. Se o `git pull --rebase` tiver conflito, liste os arquivos em conflito e peça orientação ao usuário antes de continuar. Ao gerar a mensagem de commit, liste as pastas alteradas de forma legível.
