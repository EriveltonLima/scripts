# 🚀 Scripts Collection

Uma coleção de scripts úteis para administração de sistemas Linux, automação e produtividade.

## 📋 Índice

- [🎯 Sobre](#-sobre)
- [🌟 Características](#-características)
- [📦 Scripts Disponíveis](#-scripts-disponíveis)
- [🚀 Instalação](#-instalação)
- [💡 Como Usar](#-como-usar)
- [🎨 Capturas de Tela](#-capturas-de-tela)
- [🔧 Requisitos](#-requisitos)
- [🤝 Contribuição](#-contribuição)
- [🐛 Reportar Bugs](#-reportar-bugs)
- [📈 Roadmap](#-roadmap)
- [📄 Licença](#-licença)
- [👨💻 Autor](#-autor)

## 🎯 Sobre

Este repositório contém uma coleção de scripts bash desenvolvidos para facilitar tarefas comuns de administração de sistemas, automação de processos e melhoria da produtividade em ambientes Linux.

### 🌟 Características

- ✅ Scripts testados e funcionais
- 📚 Documentação clara
- 🔧 Fácil instalação e uso
- 🎨 Interface visual amigável
- 🛡️ Verificações de segurança

## 📦 Scripts Disponíveis

### 🖥️ Monitoramento e Sistema

| Script | Descrição | Uso |
|--------|-----------|-----|
| `diskview.sh` | Visualizador interativo de espaço em disco (alternativa visual ao df -h) | `./diskview.sh` |
| `speed-apt.sh` | Otimizador de velocidade para APT e sistema | `sudo ./speed-apt.sh` |
| `status_servidor_v2.sh` | Monitor completo de status do servidor | `./status_servidor_v2.sh` |

### 🛠️ Instalação e Configuração

| Script | Descrição | Uso |
|--------|-----------|-----|
| `install-git.sh` | Instalador automático do Git com configurações | `./install-git.sh` |
| `install-lazygit.sh` | Instalador do LazyGit (interface visual para Git) | `./install-lazygit.sh` |
| `install-lazydocker.sh` | Instalador do LazyDocker (interface visual para Docker) | `./install-lazydocker.sh` |
| `pathmanager.sh` | Gerenciador de scripts no PATH | `./pathmanager.sh add script.sh` |

### ☁️ Cloud e Rede

| Script | Descrição | Uso |
|--------|-----------|-----|
| `cloudflare.linux.sh` | Configurações Cloudflare para Linux | `./cloudflare.linux.sh` |
| `cloudflare.proxmox.sh` | Configurações Cloudflare para Proxmox | `./cloudflare.proxmox.sh` |

## 🚀 Instalação

### Instalação Rápida

Clonar o repositório
git clone https://github.com/EriveltonLima/scripts.git

Entrar no diretório
cd scripts

Dar permissões de execução
chmod +x *.sh

text

### Instalação Individual

Baixar script específico
wget https://raw.githubusercontent.com/EriveltonLima/scripts/main/diskview.sh

Dar permissão
chmod +x diskview.sh

Executar
./diskview.sh

text

### Adicionar ao PATH

Usando o PathManager incluído
./pathmanager.sh add diskview.sh

Ou manualmente
sudo cp diskview.sh /usr/local/bin/diskview

text

## 💡 Como Usar

### Exemplos Práticos

**Monitorar espaço em disco:**
./diskview.sh

Interface visual interativa com navegação por setas
text

**Otimizar sistema:**
sudo ./speed-apt.sh

Configura mirrors brasileiros e otimizações de rede
text

**Instalar ferramentas:**
./install-lazygit.sh

Instala LazyGit automaticamente
text

**Gerenciar scripts:**
./pathmanager.sh add meu-script.sh # Adicionar ao PATH
./pathmanager.sh list # Listar scripts instalados
./pathmanager.sh remove script # Remover do PATH

text

## 🎨 Capturas de Tela

### DiskView - Visualizador de Disco

╔══════════════════════════════════════════════════════════════════════════════╗
║ DISKVIEW ULTRA ║
║ Visualizador Interativo de Espaço em Disco ║
╠══════════════════════════════════════════════════════════════════════════════╣
║ Status: ● Saudáveis: 2 | ● Atenção: 1 | ● Críticos: 0 | Total: 3 discos ║
╠══════════════════════════════════════════════════════════════════════════════╣
║ ► /dev/sda1 ext4 50G 30G 18G 60% ████████████░░░░░░░░ / ║
║ /dev/sda2 ext4 100G 45G 50G 45% ██████████░░░░░░░░░░ /home ║
╚══════════════════════════════════════════════════════════════════════════════╝

text

## 🔧 Requisitos

**SO:** Linux (Ubuntu, Debian, CentOS, etc.)
**Shell:** Bash 4.0+
**Dependências:** Instaladas automaticamente pelos scripts

### Dependências Opcionais

- `curl` e `wget` para downloads
- `git` para versionamento
- `docker` para scripts relacionados

### Permissões

- `sudo` para alguns scripts

## 🤝 Contribuição

Contribuições são bem-vindas! Siga estes passos:

1. **Fork** o projeto
2. Crie uma **branch** para sua feature (`git checkout -b feature/NovaFeature`)
3. **Commit** suas mudanças (`git commit -m 'Adiciona nova feature'`)
4. **Push** para a branch (`git push origin feature/NovaFeature`)
5. Abra um **Pull Request**

### 📝 Diretrizes

- Mantenha o código limpo e comentado
- Teste em diferentes distribuições Linux
- Adicione documentação para novos scripts
- Siga o padrão de nomenclatura existente

## 🐛 Reportar Bugs

Encontrou um bug? Abra uma issue com:

- Descrição detalhada do problema
- Passos para reproduzir
- Sistema operacional e versão
- Logs de erro (se houver)

## 📈 Roadmap

- [ ] Scripts para monitoramento de containers
- [ ] Integração com APIs de cloud
- [ ] Scripts para backup automatizado
- [ ] Interface web para alguns scripts
- [ ] Suporte para mais distribuições Linux

## 📊 Estatísticas

![GitHub stars](https://img.shields.io/github/stars/EriveltonLima/scripts)
![GitHub forks](https://img.shields.io/github/forks/EriveltonLima/scripts)
![GitHub issues](https://img.shields.io/github/issues/EriveltonLima/scripts)
![GitHub license](https://img.shields.io/github/license/EriveltonLima/scripts)

## 📄 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 👨💻 Autor

**Erivelton de Lima da Cruz**

- 🏢 Técnico em Assuntos Educacionais - UFPEL
- 🎓 Formação: Letras-Português/Francês
- 📍 Laranjal, Rio Grande do Sul, Brasil
- 📧 Email: [seu-email@exemplo.com]
- 💼 LinkedIn: [seu-linkedin]

## 🙏 Agradecimentos

- Comunidade Linux pela inspiração
- Contribuidores do projeto
- UFPEL pelo ambiente de desenvolvimento

---

**Se este projeto foi útil, considere dar uma estrela!** ⭐
