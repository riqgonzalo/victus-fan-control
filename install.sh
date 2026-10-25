#!/usr/bin/env bash
# Instalador de Victus Fan Control (widget de Plasma 6)
#   ./install.sh            instala el widget, el lanzador y la regla udev (pide contraseña)
#   ./install.sh --no-root  instala solo el widget y el lanzador
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

ID="com.victus.fancontrol"
RULE="/etc/udev/rules.d/90-hp-victus-fan.rules"
ok()   { printf '\e[1;32m✔\e[0m %s\n' "$*"; }
warn() { printf '\e[1;33m!\e[0m %s\n' "$*"; }
die()  { printf '\e[1;31m✘\e[0m %s\n' "$*" >&2; exit 1; }

for c in kpackagetool6 plasmawindowed busctl; do
  command -v "$c" >/dev/null || die "Falta '$c'. Se necesita KDE Plasma 6."
done

if ls -d /sys/devices/platform/hp-wmi/hwmon/hwmon* >/dev/null 2>&1; then
  ok "Driver hp-wmi detectado"
else
  warn "No se detectó el driver hp-wmi con sensores de ventilador. El widget se instalará, pero puede no mostrar datos."
fi

chmod +x package/contents/code/victus-fan.sh
if kpackagetool6 -t Plasma/Applet -s "$ID" >/dev/null 2>&1; then
  kpackagetool6 -t Plasma/Applet -u package >/dev/null
  ok "Widget actualizado"
else
  kpackagetool6 -t Plasma/Applet -i package >/dev/null
  ok "Widget instalado"
fi

mkdir -p "$HOME/.local/share/applications"
install -m 0644 system/victus-fan-control.desktop "$HOME/.local/share/applications/"
command -v kbuildsycoca6 >/dev/null && kbuildsycoca6 >/dev/null 2>&1 || true
ok "Lanzador agregado al menú (Control de Ventiladores Victus)"

if [ "${1:-}" = "--no-root" ]; then
  warn "Se omitió la regla udev: los botones AUTO/TURBO quedarán desactivados."
  exit 0
fi

# Grupo administrador: wheel (Fedora, Arch) o sudo (Debian, Ubuntu)
GROUP=""
for g in wheel sudo; do
  if id -nG "$USER" | tr ' ' '\n' | grep -qx "$g"; then GROUP="$g"; break; fi
done
[ -n "$GROUP" ] || die "Tu usuario no está en el grupo wheel ni sudo. Usa --no-root."

TMP=$(mktemp)
sed "s/@GROUP@/$GROUP/g" system/90-hp-victus-fan.rules.in > "$TMP"
if [ -f "$RULE" ] && cmp -s "$TMP" "$RULE"; then
  ok "Regla udev ya instalada"
else
  if [ -t 0 ] && command -v sudo >/dev/null; then ROOT=(sudo); else ROOT=(pkexec); fi
  "${ROOT[@]}" /bin/sh -c "install -m 0644 '$TMP' '$RULE' && udevadm control --reload && udevadm trigger --subsystem-match=hwmon --attr-match=name=hp --action=change"
  ok "Regla udev instalada (grupo $GROUP)"
fi
rm -f "$TMP"

echo
ok "Listo. Agrega el widget desde «Añadir elementos gráficos» o ábrelo desde el menú."
