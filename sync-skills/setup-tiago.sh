#!/bin/bash
# setup-aptus-skills.sh — Setup inicial das skills APTUS para um novo membro
# Uso: bash setup-aptus-skills.sh

set -e

REPO_URL="https://github.com/aptusdeveloper/aptus-skills.git"
SKILLS_DIR="$HOME/.claude/skills"
TEMP_DIR="$HOME/.claude/skills-aptus-temp"
BACKUP_DIR="$HOME/.claude/skills-backup-$(date +%Y%m%d-%H%M%S)"

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║        APTUS Skills — Setup Inicial                  ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# ── 1. Clona o repo em pasta temporária ──────────────────────────────────────
echo "→ Baixando skills do repositório APTUS..."
rm -rf "$TEMP_DIR"
git clone --quiet "$REPO_URL" "$TEMP_DIR"
echo "  ✓ Repo clonado."
echo ""

# ── 2. Analisa o que existe localmente ───────────────────────────────────────
if [ ! -d "$SKILLS_DIR" ]; then
  echo "  Nenhuma pasta de skills local encontrada. Instalando tudo diretamente."
  mv "$TEMP_DIR" "$SKILLS_DIR"
  echo ""
  echo "✓ Skills instaladas em $SKILLS_DIR"
  echo ""
  exit 0
fi

APTUS_SKILLS=($(ls "$TEMP_DIR"))
LOCAL_SKILLS=($(ls "$SKILLS_DIR"))

ONLY_LOCAL=()
ONLY_APTUS=()
IN_BOTH=()

for skill in "${LOCAL_SKILLS[@]}"; do
  if [[ " ${APTUS_SKILLS[*]} " == *" $skill "* ]]; then
    IN_BOTH+=("$skill")
  else
    ONLY_LOCAL+=("$skill")
  fi
done

for skill in "${APTUS_SKILLS[@]}"; do
  if [[ ! " ${LOCAL_SKILLS[*]} " == *" $skill "* ]]; then
    ONLY_APTUS+=("$skill")
  fi
done

# ── 3. Mostra o diagnóstico ───────────────────────────────────────────────────
echo "┌──────────────────────────────────────────────────────┐"
echo "│  Skills novas do repo APTUS (serão instaladas):      │"
echo "└──────────────────────────────────────────────────────┘"
if [ ${#ONLY_APTUS[@]} -eq 0 ]; then
  echo "  (nenhuma)"
else
  for s in "${ONLY_APTUS[@]}"; do echo "  + $s"; done
fi
echo ""

echo "┌──────────────────────────────────────────────────────┐"
echo "│  Skills que existem nos DOIS lugares (conflito):     │"
echo "└──────────────────────────────────────────────────────┘"
if [ ${#IN_BOTH[@]} -eq 0 ]; then
  echo "  (nenhuma)"
else
  for s in "${IN_BOTH[@]}"; do echo "  ~ $s"; done
fi
echo ""

echo "┌──────────────────────────────────────────────────────┐"
echo "│  Skills SUAS que não estão no repo APTUS:            │"
echo "└──────────────────────────────────────────────────────┘"
if [ ${#ONLY_LOCAL[@]} -eq 0 ]; then
  echo "  (nenhuma)"
else
  for s in "${ONLY_LOCAL[@]}"; do echo "  ● $s"; done
fi
echo ""

# ── 4. Pergunta sobre skills em conflito ──────────────────────────────────────
KEEP_LOCAL=()
OVERWRITE=()

if [ ${#IN_BOTH[@]} -gt 0 ]; then
  echo "╔══════════════════════════════════════════════════════╗"
  echo "║  Para cada skill em conflito, escolha:               ║"
  echo "║  [A] = usar a versão do repo APTUS (substituir)      ║"
  echo "║  [L] = manter a sua versão local                     ║"
  echo "╚══════════════════════════════════════════════════════╝"
  echo ""

  for skill in "${IN_BOTH[@]}"; do
    while true; do
      read -r -p "  $skill  [A/L]: " choice
      choice=$(echo "$choice" | tr '[:lower:]' '[:upper:]')
      if [[ "$choice" == "A" ]]; then
        OVERWRITE+=("$skill")
        break
      elif [[ "$choice" == "L" ]]; then
        KEEP_LOCAL+=("$skill")
        break
      else
        echo "  Digite A ou L."
      fi
    done
  done
  echo ""
fi

# ── 5. Pergunta sobre skills somente locais ───────────────────────────────────
PERSONAL_KEEP=()

if [ ${#ONLY_LOCAL[@]} -gt 0 ]; then
  echo "╔══════════════════════════════════════════════════════╗"
  echo "║  Suas skills pessoais não serão apagadas.            ║"
  echo "║  Deseja subir alguma delas pro repo APTUS?           ║"
  echo "║  [S] = sim, subir  |  [N] = manter só local         ║"
  echo "╚══════════════════════════════════════════════════════╝"
  echo ""

  for skill in "${ONLY_LOCAL[@]}"; do
    while true; do
      read -r -p "  $skill  [S/N]: " choice
      choice=$(echo "$choice" | tr '[:lower:]' '[:upper:]')
      if [[ "$choice" == "S" ]]; then
        PERSONAL_KEEP+=("$skill")
        break
      elif [[ "$choice" == "N" ]]; then
        break
      else
        echo "  Digite S ou N."
      fi
    done
  done
  echo ""
fi

# ── 6. Executa as mudanças ────────────────────────────────────────────────────
echo "→ Fazendo backup da pasta atual em $BACKUP_DIR..."
cp -r "$SKILLS_DIR" "$BACKUP_DIR"
echo "  ✓ Backup criado."
echo ""

echo "→ Instalando skills do repo APTUS..."

# Instala skills novas (só no repo)
for skill in "${ONLY_APTUS[@]}"; do
  cp -r "$TEMP_DIR/$skill" "$SKILLS_DIR/$skill"
  echo "  + instalado: $skill"
done

# Substitui skills em conflito que o usuário escolheu sobrescrever
for skill in "${OVERWRITE[@]}"; do
  rm -rf "$SKILLS_DIR/$skill"
  cp -r "$TEMP_DIR/$skill" "$SKILLS_DIR/$skill"
  echo "  ~ atualizado: $skill"
done

# Mantém o .gitignore e configuração do git do repo
cp "$TEMP_DIR/.gitignore" "$SKILLS_DIR/.gitignore" 2>/dev/null || true

echo ""

# ── 7. Inicializa git na pasta de skills e aponta pro repo ───────────────────
echo "→ Configurando git na pasta de skills..."
cd "$SKILLS_DIR"

if [ ! -d ".git" ]; then
  git init -q
  git remote add origin "$REPO_URL"
else
  git remote set-url origin "$REPO_URL" 2>/dev/null || true
fi

git fetch --quiet origin main
git checkout -q -b main --track origin/main 2>/dev/null || git checkout -q main

# Adiciona skills pessoais que o usuário quer subir
if [ ${#PERSONAL_KEEP[@]} -gt 0 ]; then
  echo ""
  echo "→ Subindo suas skills pessoais para o repo APTUS..."
  for skill in "${PERSONAL_KEEP[@]}"; do
    git add "$skill"
    echo "  + preparado para commit: $skill"
  done
  git commit -q -m "feat: skills pessoais do Tiago adicionadas ao repo"
  git push -q origin main
  echo "  ✓ Skills enviadas para o repo."
fi

# ── 8. Limpeza ────────────────────────────────────────────────────────────────
rm -rf "$TEMP_DIR"

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  ✓ Setup concluído!                                  ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "  Pasta de skills: $SKILLS_DIR"
echo "  Backup salvo em: $BACKUP_DIR"
echo ""
echo "  Use /sync-skills no Claude Code para sincronizar"
echo "  as skills com o Eder sempre que precisar."
echo ""
