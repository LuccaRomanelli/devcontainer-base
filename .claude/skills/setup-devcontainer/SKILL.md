---
name: setup-devcontainer
description: Configura o devcontainer em um projeto, detectando automaticamente as ferramentas necessárias
argument-hint: <path-do-projeto>
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Bash(mkdir:*), Bash(cp:*), Bash(chmod:*), Bash(ls:*)
---

# Setup Devcontainer

Você vai configurar um devcontainer no projeto especificado pelo usuário.

**Projeto alvo:** $ARGUMENTS

**Diretório do template devcontainer:** /home/lcc/devcontainer

## Instruções

### Passo 1: Validar o caminho do projeto

Verifique se o caminho do projeto existe e é um diretório válido. Se o usuário não forneceu um caminho, pergunte qual é o projeto.

### Passo 2: Analisar o projeto

Analise o projeto para detectar as tecnologias e ferramentas usadas. Procure por:

**Node.js/JavaScript/TypeScript:**
- `package.json` - detectar versão do Node em `engines.node` ou `.nvmrc`
- `pnpm-lock.yaml` - usa pnpm
- `yarn.lock` - usa yarn
- `package-lock.json` - usa npm
- `tsconfig.json` - usa TypeScript
- Frameworks: Next.js, Vite, React, Vue, Angular

**Python:**
- `requirements.txt`
- `pyproject.toml` - detectar versão em `[project].requires-python`
- `setup.py`
- `Pipfile`
- `poetry.lock`
- Frameworks: Django, Flask, FastAPI

**Go:**
- `go.mod` - detectar versão do Go
- `go.sum`

**Rust:**
- `Cargo.toml`
- `Cargo.lock`

**Ruby:**
- `Gemfile`
- `.ruby-version`

**PHP:**
- `composer.json`
- `composer.lock`

**Java/Kotlin:**
- `pom.xml` (Maven)
- `build.gradle` ou `build.gradle.kts` (Gradle)

**Databases e serviços:**
- `docker-compose.yml` existente - verificar serviços usados (postgres, mysql, redis, mongodb, etc.)
- Detectar em arquivos de config: DATABASE_URL, REDIS_URL, etc.

**Outras ferramentas:**
- `.tool-versions` - asdf/mise já configurado
- `mise.toml` - mise já configurado
- `Makefile`
- `Dockerfile` existente
- `.env.example`

### Passo 3: Apresentar descobertas e confirmar

Use a ferramenta AskUserQuestion para mostrar ao usuário:
1. Todas as tecnologias detectadas
2. Versões encontradas (se houver)
3. Dependências de sistema recomendadas

Pergunte se o usuário quer:
- Adicionar mais ferramentas
- Remover alguma ferramenta
- Ajustar versões

### Passo 4: Copiar arquivos do devcontainer

Copie os seguintes arquivos do template para o projeto:
- `Dockerfile`
- `docker-compose.yml`
- `devcontainer.json`
- `post-create.sh`
- `.env.example`
- `.env` - **sempre copiar** o `.env` do template (`/home/lcc/devcontainer/.env`) para trazer as configurações do usuário (dotfiles, git user, etc.)

**Não sobrescreva** arquivos que já existem sem perguntar ao usuário (exceto `.env` que deve sempre ser copiado do template).

Se o projeto já tem um `docker-compose.yml`, pergunte se deve:
- Fazer merge dos serviços
- Sobrescrever
- Manter o existente

### Passo 5: Gerar project-dependencies.sh

Crie o arquivo `project-dependencies.sh` baseado nas tecnologias detectadas.

Estrutura do arquivo:
```bash
#!/bin/bash
set -e

echo "==> Installing project-specific dependencies..."

# Runtimes via mise
mise use node@<versão>
mise use python@<versão>
# ... outras linguagens detectadas

# Bibliotecas do sistema (se necessário)
# sudo apt-get update && sudo apt-get install -y ...

# Dependências do projeto
npm install  # ou pnpm install, yarn install
pip install -r requirements.txt
# ... conforme detectado

echo "==> Project dependencies installed!"
```

### Passo 6: Ajustar docker-compose.yml se necessário

Se o projeto precisa de serviços adicionais (postgres, redis, etc.), adicione-os ao docker-compose.yml.

### Passo 7: Incorporar variáveis do projeto e configurar .gitignore

1. **Verificar se o projeto tem arquivo de environment** (`.env`, `.env.local`, `.env.example`, etc.)

2. **Se encontrar**, use AskUserQuestion para perguntar ao usuário:
   - "Deseja incorporar as variáveis de ambiente do projeto (`.env.local`, `.env`, etc.) ao `.devcontainer/.env`?"
   - Opções: Sim (adicionar ao final do .env) / Não (manter apenas as do template)

3. **Se o usuário aceitar**, leia as variáveis do arquivo de environment do projeto e adicione-as ao final do `.devcontainer/.env` em uma seção separada:
   ```
   # -------------------------------------------
   # Project-specific (from .env.local)
   # -------------------------------------------
   VARIAVEL=valor
   ```

4. **Sempre adicionar ao `.gitignore` do projeto** a linha `.devcontainer/.env` para proteger credenciais

### Passo 8: Resumo final

Mostre ao usuário:
1. Arquivos criados/modificados
2. Próximos passos para usar o devcontainer
3. Como personalizar se necessário

## Exemplo de uso

```
/setup-devcontainer ~/projetos/meu-app-node
```

Ou para o diretório atual:
```
/setup-devcontainer .
```
