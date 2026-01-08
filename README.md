# 🚀 HomLab Scripts

Repositório de scripts para instalação rápida via `curl | bash`.

## Scripts Disponíveis

### Pangolin Blueprint Generator

Gera blueprint YAML para Pangolin Proxy a partir dos containers Docker.

```bash
curl -fsSL https://raw.githubusercontent.com/EriveltonLima/scripts/main/pangolin.sh | sudo bash
```

Após instalar, execute:

```bash
pangolin-blueprint
```

## Como Adicionar Novos Scripts

1. Crie o script na pasta raiz
2. Commit e push
3. Use via: `curl -fsSL https://raw.githubusercontent.com/EriveltonLima/scripts/main/SEU_SCRIPT.sh | bash`
