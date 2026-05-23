# Projeto Android Linux - Termux

```ascii
.·:'''''''''''''''''''''''''''''''''''''''''''''''''''''''''':·.
: :                            _              _      _       : :
: :          /\               | |            (_)    | |      : :
: :         /  \    _ __    __| | _ __  ___   _   __| |      : :
: :        / /\ \  | '_ \  / _` || '__|/ _ \ | | / _` |      : :
: :       / ____ \ | | | || (_| || |  | (_) || || (_| |      : :
: :      /_/    \_\|_| |_| \__,_||_|   \___/ |_| \__,_|      : :
: :       _       _                                          : :
: :      | |     (_)                                         : :
: :      | |      _  _ __   _   _ __  __                     : :
: :      | |     | || '_ \ | | | |\ \/ /                     : :
: :      | |____ | || | | || |_| | >  <                      : :
: :      |______||_||_| |_| \__,_|/_/\_\                     : :
'·:..........................................................:·'
```

Script de configuração automatizada para instalar e gerenciar um ambiente Linux completo no Termux.

## Recursos

- Detecção do dispositivo e GPU
- Suporte a múltiplos ambientes desktop (XFCE4, LXQt, MATE, KDE)
- Aceleração gráfica otimizada por GPU
- Instalação simplificada e automatizada em 11 passos
- Aplicativos pré-instalados: VLC, Code OSS, Firefox, Python, git, wget, curl
- Compatibilidade com smartphones e tablets

## Ambientes Desktop Suportados

| Desktop | Peso | Recomendação |
|---------|------|--------------|
| XFCE4   | Médio | Recomendado |
| LXQt    | Leve | Para dispositivos antigos |
| MATE    | Médio | Alternativa estável |
| KDE     | Pesado | Para dispositivos com mais RAM |

## Aplicativos Instalados Automaticamente

| Aplicativo | Descrição |
|------------|-----------|
| VLC | Player de mídia |
| Code OSS | Editor de código (VS Code open source) |
| Firefox | Navegador web (quando disponível no dispositivo) |
| Python | Interpretador Python |
| git, wget, curl | Ferramentas de linha de comando |

## Instalação

1. Instale o [Termux](https://f-droid.org/pt_BR/packages/com.termux/) do F-Droid
2. Abra o Termux e dê permissões para acesso ao armazenamento do celular:
```bash
termux-setup-storage
```
3. Desbloqueie o modo Desenvolvedor no seu aparelho
4. Em 'Opções do Desenvolvedor' desabilite a opção 'Desativar restrições de processos filhos' (ou 'Disable child process restrictions')
5. Instale e abra o [Termux X11](https://github.com/termux/termux-x11/releases/tag/nightly) pois essa será a interface gráfica
6. Instale o git:
```bash
pkg install git
```
7. Clone este repositório:
```bash
git clone https://github.com/lucasaguiar-la/linux-android.git
```
8. Após execute:
```bash
# Acessa a pasta clonada
cd linux-android

# Da permissões para executar o script
chmod +x script-termux.sh

# Executa o script de instalação
./script-termux.sh
```
9. Selecione a configuração de GPU, o ambiente desktop desejado e se deseja instalar o Wine (o script instala o Hangover Wine, variante compatível com ARM/Android)
10. Aguarde a instalação ser concluída
11. Inicie ou pare o desktop:
```bash
# Volte para a home
cd

# Iniciar o desktop
~/start-linux.sh

# Parar o desktop
~/stop-linux.sh
```
12. Abra o Termux X11 e o provedor gráfico já estará funcionando

## Requisitos

- Android 5.0+
- Termux instalado
- Termux: X11
- ~2GB de espaço livre
- Conexão com internet

## Notas

- Use XFCE4 para melhor equilíbrio entre performance e funcionalidade
- Dispositivos antigos: prefira LXQt
- Dispositivos topo de linha: experimente KDE
- Para iniciar o desktop automaticamente ao abrir o Termux, adicione ao `~/.bashrc`:
```bash
nano ~/.bashrc

# Cole o conteúdo abaixo:
~/start-linux.sh
```
- Em caso de falha durante a instalação, consulte o log em `~/termux-linux-install.log`
