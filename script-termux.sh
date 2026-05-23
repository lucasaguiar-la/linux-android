#!/data/data/com.termux/files/usr/bin/bash
set -e

# ============== CONFIGURAÇÃO BÁSICA ==============
DE_CHOICE="1"
DE_NAME="XFCE4"
GPU_DRIVER=""
GPU_ENABLED="false"
INSTALL_WINE="n"

LOG=~/termux-linux-install.log
SPINNER_PID=""

# ============== FUNÇÕES SIMPLIFICADAS ==============
_stop_spinner() {
    if [ -n "$SPINNER_PID" ]; then
        kill "$SPINNER_PID" 2>/dev/null || true
        wait "$SPINNER_PID" 2>/dev/null || true
        printf "\r\033[K"
        SPINNER_PID=""
    fi
}

print_step() {
    _stop_spinner
    echo "[$1/$2] $3"
    ( i=0
        while true; do
            case $((i % 4)) in
                0) printf "\r  |" ;;
                1) printf "\r  /" ;;
                2) printf "\r  -" ;;
                3) printf "\r  \\" ;;
            esac
            i=$((i+1))
            sleep 0.2
        done ) &
    SPINNER_PID=$!
}

install_pkg() {
    echo "  -> Instalando: $*"
    if ! pkg install -y "$@" >> "$LOG" 2>&1; then
        _stop_spinner
        echo "  -> Falha ao instalar: $*"
        echo "Verifique o log: $LOG"
        exit 1
    fi
}

trap '_stop_spinner' EXIT

# ============== DETECÇÃO DO DISPOSITIVO ==============
cat << 'EOF'
    .·:''''''''''''''''''''''''''''''''''''''''''':·.
    : :                                           : :
    : :      |    | |\ | |  | \_/                 : :
    : :      |___ | | \| \__/ / \                 : :
    : :                                           : :
    : :                 __   __   __     __       : :
    : :       /\  |\ | |  \ |__) /  \ | |  \      : :
    : :      /~~\ | \| |__/ |  \ \__/ | |__/      : :
    : :                                           : :
    '·:...........................................:·'
EOF
sleep 1.5
echo "=== Configurando Termux Linux ==="
echo "Verificando internet..."

ping -c 1 google.com >> "$LOG" 2>&1 || {
    echo "Sem conexão com internet"
    exit 1
}

ARCH=$(uname -m)

echo "Arquitetura: $ARCH"

if [[ "$ARCH" != "aarch64" ]]; then
    echo "AVISO: Wine funciona melhor em ARM64"
fi

echo ""

DEVICE_BRAND=$(getprop ro.product.brand 2>/dev/null || echo "Unknown")
GPU_VENDOR=$(getprop ro.hardware.egl 2>/dev/null || echo "")

echo "Dispositivo: $DEVICE_BRAND"
echo ""

echo "Configuração de GPU:"
echo "1) Automático (recomendado)"
echo "2) Ativar aceleração GPU"
echo "3) Desativar aceleração GPU"

read -p "Opção [1-3, padrão=1]: " GPU_OPTION
GPU_OPTION=${GPU_OPTION:-1}

case $GPU_OPTION in
    1)
        # Detecção automática
        if [[ "$GPU_VENDOR" == *"adreno"* ]] || [[ "$DEVICE_BRAND" == *"samsung"* ]]; then
            GPU_DRIVER="freedreno"
            GPU_ENABLED="true"
            echo "GPU: Adreno (aceleração ativada)"
        else
            GPU_DRIVER="zink_native"
            GPU_ENABLED="false"
            echo "GPU: Compatibilidade sem aceleração"
        fi
    ;;
    
    2)
        GPU_DRIVER="freedreno"
        GPU_ENABLED="true"
        echo "GPU: aceleração forçada pelo usuário"
    ;;
    
    3)
        GPU_ENABLED="false"
        echo "GPU: aceleração desativada"
    ;;
esac

# ============== SELEÇÃO DO DESKTOP ==============
echo ""
echo "Escolha o Desktop:"
echo "1) XFCE4 (recomendado)"
echo "2) LXQt (leve)"
echo "3) MATE (médio)"
echo "4) KDE Plasma (experimental/requer muita RAM)"
read -p "Opção [1-4, padrão=1]: " DE_INPUT
DE_INPUT=${DE_INPUT:-1}

case $DE_INPUT in
    1)
        DE_NAME="XFCE4"
        DE_PACKAGES=(
            xfce4
            xfce4-terminal
            thunar
            mousepad
            dbus
            pulseaudio
            termux-x11
        )
    ;;
    2)
        DE_NAME="LXQt"
        DE_PACKAGES=(
            lxqt-panel
            lxqt-session
            pcmanfm-qt
            qterminal
            openbox
            featherpad
        
            dbus
        
            gtk3
            shared-mime-info
        
            fontconfig
        
            pavucontrol
        
            xorg-xhost
            xorg-xrandr
        )
    ;;
    3)
        DE_NAME="MATE"
        DE_PACKAGES=(
            mate
            mate-terminal
            mate-tweak
            caja
            pluma
            mate-power-manager
            dbus
            dbus-x11
            gtk3
            shared-mime-info
            adwaita-icon-theme
            papirus-icon-theme
            fontconfig
            dejavu-fonts
            pavucontrol
            xorg-xhost
            xorg-xrandr
        )
    ;;
    4)
        DE_NAME="KDE Plasma"
        DE_PACKAGES=(
            plasma-desktop
            konsole
            dolphin
            kate
            kde-cli-tools
            dbus
            dbus-x11
            gtk3
            shared-mime-info
            adwaita-icon-theme
            papirus-icon-theme
            fontconfig
            dejavu-fonts
            pavucontrol
            xorg-xhost
            xorg-xrandr
        )
    ;;
esac

echo "Selecionado: $DE_NAME"
echo ""

read -p "Instalar Wine/Hangover? [s/N]: " INSTALL_WINE
INSTALL_WINE=$(echo "$INSTALL_WINE" | tr '[:upper:]' '[:lower:]')

# ============== AJUSTES DE AMBIENTE ==============
export DEBIAN_FRONTEND=noninteractive
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export TMPDIR=${TMPDIR:-$PREFIX/tmp}
mkdir -p "$TMPDIR"

# Forçar resposta automática para prompts de arquivos de configuração do dpkg
mkdir -p "$PREFIX/etc/apt/apt.conf.d"
printf 'DPkg::Options { "--force-confdef"; "--force-confold"; };\n' \
    > "$PREFIX/etc/apt/apt.conf.d/99noninteractive"

# ============== INSTALAÇÃO (11 PASSOS) ==============
rm -f "$PREFIX/var/lib/dpkg/lock-frontend" \
      "$PREFIX/var/lib/dpkg/lock" \
      "$PREFIX/var/cache/apt/archives/lock" \
      "/data/data/com.termux/cache/apt/archives/lock" 2>/dev/null || true
dpkg --configure -a >> "$LOG" 2>&1 || true

TOTAL=11
CURRENT=0

# Passo 1
CURRENT=$((CURRENT+1)); print_step $CURRENT $TOTAL "Atualizando sistema"
pkg upgrade -y >> "$LOG" 2>&1

# Passo 2
CURRENT=$((CURRENT+1)); print_step $CURRENT $TOTAL "Adicionando repositórios"
pkg install -y -q x11-repo tur-repo >> "$LOG" 2>&1
pkg update -y >> "$LOG" 2>&1

# Passo 3
CURRENT=$((CURRENT+1)); print_step $CURRENT $TOTAL "Instalando servidor gráfico"
if ! pkg install -y termux-x11 xorg-xrandr >> "$LOG" 2>&1; then
    pkg install -y termux-x11-nightly xorg-xrandr >> "$LOG" 2>&1
fi

# Passo 4
CURRENT=$((CURRENT+1)); print_step $CURRENT $TOTAL "Instalando $DE_NAME"
install_pkg "${DE_PACKAGES[@]}"

# Passo 5
CURRENT=$((CURRENT+1)); print_step $CURRENT $TOTAL "Instalando drivers GPU"
if [ "$GPU_ENABLED" == "true" ]; then
    pkg install -y -q mesa-zink vulkan-loader-android >> "$LOG" 2>&1

    if [ "$GPU_DRIVER" == "freedreno" ]; then
        pkg install -y -q mesa-vulkan-icd-freedreno >> "$LOG" 2>&1
    fi

    echo "Aceleração GPU instalada"
else
    echo "Modo sem aceleração GPU"
fi

# Passo 6
CURRENT=$((CURRENT+1)); print_step $CURRENT $TOTAL "Instalando áudio"
pkg install -y -q pulseaudio >> "$LOG" 2>&1

# Passo 7
CURRENT=$((CURRENT+1)); print_step $CURRENT $TOTAL "Instalando apps"
pkg install -y -q vlc git wget curl code-oss wol >> "$LOG" 2>&1
if ! pkg install -y firefox >> "$LOG" 2>&1; then
    echo "Firefox não disponível neste dispositivo"
fi

# Passo 8
CURRENT=$((CURRENT+1)); print_step $CURRENT $TOTAL "Instalando Python"
pkg install -y -q python >> "$LOG" 2>&1
pip install --upgrade pip >> "$LOG" 2>&1
pip install flask >> "$LOG" 2>&1

# Passo 9
CURRENT=$((CURRENT+1)); print_step $CURRENT $TOTAL "Configurando Wine"

if [[ "$INSTALL_WINE" == "s" ]]; then
    pkg remove -y wine-stable >> "$LOG" 2>&1
    pkg install -y hangover-wine hangover-wowbox64 >> "$LOG" 2>&1

    ln -sf \
    /data/data/com.termux/files/usr/opt/hangover-wine/bin/wine \
    /data/data/com.termux/files/usr/bin/wine 2>/dev/null

    echo "Wine instalado"
else
    echo "Wine ignorado"
fi

# Passo 10
CURRENT=$((CURRENT+1)); print_step $CURRENT $TOTAL "Criando scripts"
cat > ~/start-linux.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

pkill -9 -f "termux.x11" 2>/dev/null
pulseaudio --kill 2>/dev/null

sleep 1

export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export TMPDIR=${TMPDIR:-/data/data/com.termux/files/usr/tmp}
mkdir -p "$TMPDIR"

export XDG_RUNTIME_DIR=${TMPDIR}
export DISPLAY=:0
export QT_X11_NO_MITSHM=1
export XDG_SESSION_TYPE=x11

pulseaudio --start \
  --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" \
  --exit-idle-time=-1

export PULSE_SERVER=127.0.0.1

am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1
termux-x11 :0 >/dev/null 2>&1 &

sleep 2

export DISPLAY=:0
EOF

if [ "$GPU_ENABLED" == "true" ]; then
    echo "export GALLIUM_DRIVER=zink" >> ~/start-linux.sh
fi

case $DE_INPUT in
    1)
        echo "exec dbus-launch --exit-with-session startxfce4" >> ~/start-linux.sh
    ;;
    2)
        echo "exec dbus-launch --exit-with-session startlxqt" >> ~/start-linux.sh
    ;;
    3)
        echo "exec dbus-launch --exit-with-session mate-session" >> ~/start-linux.sh
    ;;
    4)
        echo "exec dbus-launch --exit-with-session startplasma-x11" >> ~/start-linux.sh
    ;;
esac

chmod +x ~/start-linux.sh

cat > ~/stop-linux.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
pkill -9 -f "termux.x11" 2>/dev/null
pkill -9 pulseaudio 2>/dev/null
echo "Desktop finalizado"
EOF
chmod +x ~/stop-linux.sh

# Passo 11
CURRENT=$((CURRENT+1)); print_step $CURRENT $TOTAL "Criando atalhos"
mkdir -p ~/Desktop
cat > ~/Desktop/Firefox.desktop << 'EOF'
[Desktop Entry]
Name=Firefox
Exec=firefox
Type=Application
EOF
chmod +x ~/Desktop/*.desktop 2>/dev/null

# ============== FINALIZAÇÃO ==============
_stop_spinner
echo ""
echo "=== INSTALAÇÃO CONCLUÍDA ==="
echo ""
echo "Para iniciar o desktop: ./start-linux.sh"
echo "Para parar: ./stop-linux.sh"
echo "Abra o app Termux-X11 para ver a interface"
echo ""
echo "Log da instalação: $LOG"
echo ""
