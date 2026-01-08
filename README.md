# 🚀 HomLab Scripts Repository

Repositório de scripts para instalação rápida via `curl | bash` para o homelab.

---

## 📦 Scripts Disponíveis

### 1. Pangolin Blueprint Generator

**Descrição:** Script interativo com interface TUI (Terminal User Interface) que escaneia containers Docker em execução e gera automaticamente um arquivo YAML de blueprint para o [Pangolin Proxy](https://github.com/fosrl/pangolin).

**Funcionalidades:**

- ✅ Detecta automaticamente containers Docker com portas expostas
- ✅ Interface interativa com checklist para seleção de containers
- ✅ Suporte a variável `VIRTUAL_HOST` para domínios customizados
- ✅ Gera arquivo YAML pronto para uso no Pangolin
- ✅ Compatível com Debian/Ubuntu (apt) e RHEL/CentOS (yum)

**Dependências instaladas automaticamente:**

- `jq` - Processador JSON
- `whiptail` - Interface TUI

**Instalação:**

```bash
curl -fsSL https://raw.githubusercontent.com/EriveltonLima/scripts/main/pangolin.sh | sudo bash
```

**Uso:**

```bash
pangolin-blueprint
```

**Exemplo de saída:**

```yaml
proxy-resources:
  resource-nginx-80:
    name: nginx service port 80
    protocol: http
    full-domain: nginx.homlab.site
    targets:
      - site: nginx
        hostname: localhost
        method: http
        port: 80
```

---

## 🛠️ Como Adicionar Novos Scripts

1. Crie o script na pasta raiz ou em `scripts/`
2. Commit e push para o repositório
3. Use via:

```bash
curl -fsSL https://raw.githubusercontent.com/EriveltonLima/scripts/main/SEU_SCRIPT.sh | bash
```

---

## 📁 Estrutura do Repositório

```
Script-Repository/
├── README.md           # Este arquivo
├── index.html          # Página web do repositório
├── pangolin.sh         # Instalador do Pangolin Blueprint Generator
└── scripts/
    └── pangolin.sh     # Cópia do instalador
```

---

## 🔗 Links Úteis

- **GitHub Pages:** [https://eriveltonlima.github.io/scripts](https://eriveltonlima.github.io/scripts)
- **Raw Scripts:** `https://raw.githubusercontent.com/EriveltonLima/scripts/main/`

---

## 📝 Changelog

### v1.0.0 (2026-01-07)

- ✨ Adicionado Pangolin Blueprint Generator
- 🎨 Criada página HTML para listagem de scripts

---

_HomLab Infrastructure - homlab.site_
