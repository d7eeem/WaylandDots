#!/usr/bin/env bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://gitlab.com/d7eeem

set -euo pipefail

# Check if running with sudo
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run with sudo or as root"
   exit 1
fi

echo "[*] Configuring UFW firewall rules..."

# SSH
ufw_rules=(
  "22/tcp              # SSH"
  
  # Syncthing
  "8384/tcp            # Syncthing Web UI"
  "22000/tcp           # Syncthing sync protocol"
  "21027/udp           # Syncthing discovery"
  
  # Steam/Gaming
  "27015:27050/udp     # Steam game traffic"
  "27000:27036/udp     # Steam client"
  "27031:27036/tcp     # Steam downloads"
  "27040/tcp           # Steam voice chat"
  "27040/udp           # Steam voice chat"
  
  # Other services
  "3478/udp            # STUN/TURN (voice/video)"
  "4379/tcp            # Custom service"
  "4380/tcp            # Custom service"
  "5900/tcp            # VNC"
  "9300/tcp            # Custom service"
  "11434/tcp           # Ollama API"
  "53317/tcp           # Custom service"
  "5149:5169/tcp       # Port range"
)

# Apply rules
for rule in "${ufw_rules[@]}"; do
  # Extract port/protocol (before the # comment)
  port=$(echo "$rule" | awk '{print $1}')
  
  # Skip empty lines or pure comments
  [[ -z "$port" || "$port" == "#"* ]] && continue
  
  echo "[+] Allowing: $port"
  ufw allow "$port" 2>/dev/null || echo "[!] Failed to add rule: $port"
done

echo ""
echo "[*] Current UFW status:"
ufw status numbered

echo ""
echo "[✓] Firewall configuration complete!"
echo ""
echo "To enable UFW if not already enabled:"
echo "  sudo ufw enable"
echo ""
echo "To remove a rule by number:"
echo "  sudo ufw delete <number>"
