#!/usr/bin/env bash
# Desinstala Victus Fan Control
set -uo pipefail
kpackagetool6 -t Plasma/Applet -r com.victus.fancontrol >/dev/null 2>&1 && echo "✔ Widget eliminado"
rm -f "$HOME/.local/share/applications/victus-fan-control.desktop" && echo "✔ Lanzador eliminado"
rm -rf "${XDG_CONFIG_HOME:-$HOME/.config}/victus-fan"
RULE=/etc/udev/rules.d/90-hp-victus-fan.rules
if [ -f "$RULE" ]; then
  if [ -t 0 ]; then sudo rm -f "$RULE"; else pkexec rm -f "$RULE"; fi && echo "✔ Regla udev eliminada (los permisos vuelven a la normalidad al reiniciar)"
fi
