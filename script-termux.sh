#!/data/data/com.termux/files/usr/bin/bash
set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# ============== PERMISSÃO DE ARMAZENAMENTO ==============
echo ""
echo "Solicitando permissão de armazenamento..."
termux-setup-storage

echo "  Aguardando permissão de armazenamento..."
timeout=30
while [ $timeout -gt 0 ] && [ ! -d "$HOME/storage/shared" ]; do
    sleep 1
    timeout=$((timeout-1))
done

# ============== CONFIGURAÇÃO BÁSICA ==============
DE_NAME="XFCE4"
GPU_DRIVER=""
GPU_ENABLED="false"
INSTALL_WINE="n"
LOG=~/termux-linux-install.log

# ============== FUNÇÕES ==============
print_step() {
    local pct=$(( $1 * 100 / $2 ))
    echo ""
    printf "  [%2d/%2d] %-35s %3d%%\n" "$1" "$2" "$3" "$pct"
}

run_cmd() {
    local desc="$1"; shift
    printf "    %s " "$desc"
    "$@" >> "$LOG" 2>&1 &
    local CMD_PID=$!
    while kill -0 "$CMD_PID" 2>/dev/null; do
        printf "."
        sleep 1
    done
    local rc=0
    wait "$CMD_PID" || rc=$?
    if [ $rc -eq 0 ]; then
        echo " OK"
    else
        echo " ERRO"
        echo "  Verifique o log: $LOG"
        exit 1
    fi
}

try_pkg() {
    local pkgs="$*"
    printf "    Instalando: %s " "$pkgs"
    pkg install -y "$@" >> "$LOG" 2>&1 &
    local CMD_PID=$!
    while kill -0 "$CMD_PID" 2>/dev/null; do
        printf "."
        sleep 1
    done
    local rc=0
    wait "$CMD_PID" || rc=$?
    if [ $rc -eq 0 ]; then
        echo " OK"
        return 0
    else
        echo " N/D"
        return 1
    fi
}

install_pkg() {
    if ! try_pkg "$@"; then
        echo "  Verifique o log: $LOG"
        exit 1
    fi
}

# ============== DETECÇÃO DO DISPOSITIVO ==============
echo ""
cat << 'EOF'
|    | |\ | |  | \_/
|___ | | \| \__/ / \

           __   __   __     __
 /\  |\ | |  \ |__) /  \ | |  \
/~~\ | \| |__/ |  \ \__/ | |__/
EOF
echo ""
echo "  ================================="
echo "      Configurando Termux Linux"
echo "  ================================="
echo ""
echo "  Verificando internet..."

ping -c 1 google.com >> "$LOG" 2>&1 || {
    echo "Sem conexão com internet"
    exit 1
}

ARCH=$(uname -m)
DEVICE_BRAND=$(getprop ro.product.brand 2>/dev/null || echo "Unknown")
GPU_VENDOR=$(getprop ro.hardware.egl 2>/dev/null || echo "")

echo "  Arquitetura : $ARCH"
echo "  Dispositivo : $DEVICE_BRAND"

if [[ "$ARCH" != "aarch64" ]]; then
    echo "  AVISO: Wine funciona melhor em ARM64"
fi

echo ""
echo "  -- Configuração de GPU --"
echo "   1) Automático (recomendado)"
echo "   2) Ativar aceleração GPU"
echo "   3) Desativar aceleração GPU"
echo ""
read -p "  Opção [1-3, padrão=1]: " GPU_OPTION
GPU_OPTION=${GPU_OPTION:-1}

case $GPU_OPTION in
    1)
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
echo "  -- Escolha o Desktop --"
echo "   1) XFCE4      (recomendado)"
echo "   2) LXQt       (leve)"
echo "   3) MATE       (médio)"
echo "   4) KDE Plasma (experimental)"
echo ""
read -p "  Opção [1-4, padrão=1]: " DE_INPUT
DE_INPUT=${DE_INPUT:-1}

case $DE_INPUT in
    1)
        DE_NAME="XFCE4"
        DE_PACKAGES=(
            xfce4 xfce4-terminal thunar mousepad dbus pulseaudio termux-x11
        )
    ;;
    2)
        DE_NAME="LXQt"
        DE_PACKAGES=(
            lxqt-panel lxqt-session pcmanfm-qt qterminal openbox featherpad
            dbus gtk3 shared-mime-info fontconfig pavucontrol
            xorg-xhost xorg-xrandr xorg-xsetroot
        )
    ;;
    3)
        DE_NAME="MATE"
        DE_PACKAGES=(
            mate-session-manager marco mate-panel mate-terminal
            dbus dbus-x11 fontconfig xorg-xhost xorg-xrandr
        )
    ;;
    4)
        DE_NAME="KDE Plasma"
        DE_PACKAGES=(
            plasma-desktop konsole dbus dbus-x11 fontconfig xorg-xhost xorg-xrandr
        )
    ;;
esac

echo "  -> Desktop: $DE_NAME"
echo ""
read -p "  Instalar Wine/Hangover? [s/N]: " INSTALL_WINE
INSTALL_WINE=$(echo "$INSTALL_WINE" | tr '[:upper:]' '[:lower:]')

# ============== AJUSTES DE AMBIENTE ==============
export DEBIAN_FRONTEND=noninteractive
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export TMPDIR=${TMPDIR:-$PREFIX/tmp}
mkdir -p "$TMPDIR"

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
run_cmd "Atualizando pacotes..." pkg upgrade -y

# Passo 2
CURRENT=$((CURRENT+1)); print_step $CURRENT $TOTAL "Adicionando repositórios"
run_cmd "Instalando: x11-repo tur-repo..." pkg install -y x11-repo tur-repo
run_cmd "Atualizando listas de pacotes..." pkg update -y

# Passo 3
CURRENT=$((CURRENT+1)); print_step $CURRENT $TOTAL "Instalando servidor gráfico"
if ! try_pkg termux-x11 xorg-xrandr; then
    install_pkg termux-x11-nightly xorg-xrandr
fi

# Passo 4
CURRENT=$((CURRENT+1)); print_step $CURRENT $TOTAL "Instalando $DE_NAME"
for _pkg in "${DE_PACKAGES[@]}"; do
    try_pkg "$_pkg" || true
done

# Passo 5
CURRENT=$((CURRENT+1)); print_step $CURRENT $TOTAL "Instalando drivers GPU"
if [ "$GPU_ENABLED" == "true" ]; then
    if try_pkg mesa-zink vulkan-loader-android; then
        if [ "$GPU_DRIVER" == "freedreno" ]; then
            try_pkg mesa-vulkan-icd-freedreno || true
        fi
    else
        echo "    Drivers GPU não disponíveis, continuando sem aceleração"
        GPU_ENABLED="false"
    fi
else
    echo "    Modo sem aceleração GPU"
fi

# Passo 6
CURRENT=$((CURRENT+1)); print_step $CURRENT $TOTAL "Instalando áudio"
install_pkg pulseaudio

# Passo 7
CURRENT=$((CURRENT+1)); print_step $CURRENT $TOTAL "Instalando apps"
install_pkg vlc wget curl code-oss wol neofetch
try_pkg firefox || echo "    Firefox não disponível neste dispositivo"

# Passo 8
CURRENT=$((CURRENT+1)); print_step $CURRENT $TOTAL "Instalando Python"
install_pkg python

# Passo 9
CURRENT=$((CURRENT+1)); print_step $CURRENT $TOTAL "Configurando Wine"
if [[ "$INSTALL_WINE" == "s" ]]; then
    pkg remove -y wine-stable >> "$LOG" 2>&1 || true
    install_pkg hangover-wine hangover-wowbox64
    ln -sf \
        /data/data/com.termux/files/usr/opt/hangover-wine/bin/wine \
        /data/data/com.termux/files/usr/bin/wine 2>/dev/null || true
    echo "    Wine instalado"
else
    echo "    Wine ignorado"
fi

# Passo 10
CURRENT=$((CURRENT+1)); print_step $CURRENT $TOTAL "Criando scripts"
cat > "$SCRIPT_DIR/start-linux.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

pkill -9 Xwayland 2>/dev/null || true
pkill -9 -f "termux.x11" 2>/dev/null || true
pkill -9 -f "termux-x11" 2>/dev/null || true
pulseaudio --kill 2>/dev/null || true

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

sleep 3
termux-x11 :0 >/dev/null 2>&1 &

sleep 4

export DISPLAY=:0
EOF

if [ "$GPU_ENABLED" == "true" ]; then
    echo "export GALLIUM_DRIVER=zink" >> "$SCRIPT_DIR/start-linux.sh"
fi

case $DE_INPUT in
    1)
        echo "exec dbus-launch --exit-with-session xfce4-session" >> "$SCRIPT_DIR/start-linux.sh"
    ;;
    2)
        echo "xsetroot -solid '#2e3440'" >> "$SCRIPT_DIR/start-linux.sh"
        echo "exec dbus-launch --exit-with-session startlxqt" >> "$SCRIPT_DIR/start-linux.sh"
    ;;
    3)
        echo "exec dbus-launch --exit-with-session mate-session" >> "$SCRIPT_DIR/start-linux.sh"
    ;;
    4)
        echo "exec dbus-launch --exit-with-session startplasma-x11" >> "$SCRIPT_DIR/start-linux.sh"
    ;;
esac

chmod +x "$SCRIPT_DIR/start-linux.sh"

cat > "$SCRIPT_DIR/stop-linux.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
pkill -9 Xwayland 2>/dev/null || true
pkill -9 -f "termux.x11" 2>/dev/null || true
pkill -9 pulseaudio 2>/dev/null || true
echo "Desktop finalizado"
EOF
chmod +x "$SCRIPT_DIR/stop-linux.sh"

# Passo 11
CURRENT=$((CURRENT+1)); print_step $CURRENT $TOTAL "Criando atalhos"
mkdir -p "$SCRIPT_DIR/Desktop"
cat > "$SCRIPT_DIR/Desktop/Firefox.desktop" << 'EOF'
[Desktop Entry]
Name=Firefox
Exec=firefox
Type=Application
EOF
chmod +x "$SCRIPT_DIR/Desktop/"*.desktop 2>/dev/null || true

# ============== FINALIZAÇÃO ==============
neofetch
echo ""
echo "  ================================="
echo "       INSTALAÇÃO CONCLUÍDA"
echo "  ================================="
echo ""
echo "  Iniciando desktop automaticamente..."
echo "  Para iniciar o desktop manualmente, execute:"
echo "  ./start-linux.sh"
echo ""
