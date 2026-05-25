# Projeto Android Linux - Termux

```ascii
.·:'''''''''''''''''''''''''''''''''''''''''''''''''''''''''':·.
: :                            _              _      _       : :
: :          /\               | |            (_)    | |      : :
: :         /  \    _ __    __| | _ __  ___   _   __| |      : :
: :        / /\ \  | '_ \  / _` || '__|/ _ \ | | / `_ |      : :
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
- Aplicativos pré-instalados: VLC, Code OSS, Firefox, Python, wget, curl
- Compatibilidade com smartphones e tablets

## Ambientes Desktop Suportados


| Desktop | Peso   | Recomendação                   |
| ------- | ------ | ------------------------------ |
| XFCE4   | Médio  | Recomendado                    |
| LXQt    | Leve   | Para dispositivos antigos      |
| MATE    | Médio  | Alternativa experimental       |
| KDE     | Pesado | Para dispositivos com mais RAM |


## Aplicativos Instalados Automaticamente


| Aplicativo | Descrição                                        |
| ---------- | ------------------------------------------------ |
| VLC        | Player de mídia                                  |
| Code OSS   | Editor de código (VS Code open source)           |
| Firefox    | Navegador web (quando disponível no dispositivo) |
| Python     | Interpretador Python                             |
| wget, curl | Ferramentas de linha de comando                  |


## Instalação

1. Instale o [Termux](https://f-droid.org/pt_BR/packages/com.termux/) do F-Droid
2. Desbloqueie o modo Desenvolvedor no seu aparelho
3. Em 'Opções do Desenvolvedor' desabilite a opção 'Desativar restrições de processos filhos' (ou 'Disable child process restrictions')
4. Instale e abra o [Termux X11](https://github.com/termux/termux-x11/releases/tag/nightly) pois essa será a interface gráfica
5. Instale o git e clone este repositório:

```bash
pkg install git
git clone https://github.com/lucasaguiar-la/linux-android.git
```

1. Execute o script:

```bash
cd linux-android
chmod +x script-termux.sh
./script-termux.sh
```

1. Selecione a configuração de GPU, o ambiente desktop desejado e se deseja instalar o Wine (o script instala o Hangover Wine, variante compatível com ARM/Android)
2. O script solicitará permissão de armazenamento automaticamente e aguardará sua confirmação antes de prosseguir
3. Aguarde a instalação ser concluída
4. Inicie ou pare o desktop a partir da pasta clonada:

```bash
# Iniciar o desktop
./start-linux.sh

# Parar o desktop
./stop-linux.sh
```

1. Abra o Termux X11 e o provedor gráfico já estará funcionando

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

# Cole o conteúdo abaixo (ajuste o caminho se necessário):
~/linux-android/start-linux.sh
```

- Em caso de falha durante a instalação, consulte o log em `~/termux-linux-install.log`

