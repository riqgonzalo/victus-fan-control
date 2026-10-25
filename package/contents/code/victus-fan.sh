#!/bin/bash
# Victus Fan Control - lectura de sensores y cambio de modo (driver hp-wmi del kernel)
#   victus-fan.sh status            -> JSON con ventiladores, temperaturas y perfil
#   victus-fan.sh max | auto        -> modo de ventiladores
#   victus-fan.sh profile <nombre>  -> power-saver | balanced | performance
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/victus-fan"
STATE="$CONF/modo"
HW=$(ls -d /sys/devices/platform/hp-wmi/hwmon/hwmon* 2>/dev/null | head -1)
PPD=(org.freedesktop.UPower.PowerProfiles /org/freedesktop/UPower/PowerProfiles org.freedesktop.UPower.PowerProfiles)

rd() { [ -r "$1" ] && cat "$1" 2>/dev/null || echo ""; }
num() { [[ "$1" =~ ^-?[0-9]+$ ]] && echo "$1" || echo null; }

hwmon_by_name() {
  for h in /sys/class/hwmon/hwmon*; do [ "$(rd "$h/name")" = "$1" ] && { echo "$h"; return; }; done
}

set_mode() {  # $1 = 0 (máximo) | 2 (automático)
  [ -n "$HW" ] || { echo '{"ok":false,"error":"Driver hp-wmi no encontrado"}'; exit 1; }
  if [ -w "$HW/pwm1_enable" ]; then
    echo "$1" > "$HW/pwm1_enable" 2>/dev/null || { echo '{"ok":false,"error":"El firmware rechazó el cambio"}'; exit 1; }
  else
    echo '{"ok":false,"error":"Sin permiso de escritura (regla udev)"}'; exit 1
  fi
}

case "$1" in
  max)  mkdir -p "$CONF"; echo max  > "$STATE"; set_mode 0; echo '{"ok":true}';;
  auto) mkdir -p "$CONF"; echo auto > "$STATE"; set_mode 2; echo '{"ok":true}';;
  profile)
    case "$2" in power-saver|balanced|performance) ;; *) echo '{"ok":false,"error":"Perfil no válido"}'; exit 1;; esac
    busctl --system set-property "${PPD[@]}" ActiveProfile s "$2" >/dev/null 2>&1 \
      && echo '{"ok":true}' || echo '{"ok":false,"error":"No se pudo cambiar el perfil"}';;
  status|*)
    want=$(rd "$STATE"); want=${want:-auto}
    pwm=$(rd "$HW/pwm1_enable")
    # Si el firmware vuelve a automático por su cuenta, reaplicar la elección del usuario
    if [ "$want" = max ] && [ "$pwm" != 0 ] && [ -w "$HW/pwm1_enable" ]; then echo 0 > "$HW/pwm1_enable" 2>/dev/null; pwm=$(rd "$HW/pwm1_enable"); fi
    f1=$(rd "$HW/fan1_input"); f2=$(rd "$HW/fan2_input")
    ct=$(hwmon_by_name coretemp); cpu=$(rd "$ct/temp1_input")
    nv=$(hwmon_by_name nvme); ssd=$(rd "$nv/temp1_input")
    [ -n "$cpu" ] && cpu=$((cpu/1000)); [ -n "$ssd" ] && ssd=$((ssd/1000))
    gpu=""; gpust="sin-gpu"
    G=$(ls -d /sys/bus/pci/devices/*/ 2>/dev/null | while read d; do [ "$(rd ${d}vendor)" = 0x10de ] && [ "$(rd ${d}class | cut -c1-6)" = 0x0300 ] && echo "$d"; done | head -1)
    if [ -n "$G" ]; then
      gpust=$(rd "${G}power/runtime_status")
      # Solo consultar la GPU si ya está despierta, para no gastar batería
      if [ "$gpust" = active ] && command -v nvidia-smi >/dev/null; then
        gpu=$(timeout 3 nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -dc 0-9)
      fi
    fi
    prof=$(busctl --system get-property "${PPD[@]}" ActiveProfile 2>/dev/null | sed -E 's/^s "(.*)"$/\1/')
    writable=false; [ -w "$HW/pwm1_enable" ] && writable=true
    printf '{"ok":true,"driver":%s,"writable":%s,"pwm":%s,"want":"%s","fan1":%s,"fan2":%s,"cpu":%s,"gpu":%s,"gpuState":"%s","ssd":%s,"profile":"%s"}\n' \
      "$([ -n "$HW" ] && echo true || echo false)" "$writable" "$(num "$pwm")" "$want" "$(num "$f1")" "$(num "$f2")" \
      "$(num "$cpu")" "$(num "$gpu")" "$gpust" "$(num "$ssd")" "$prof";;
esac
