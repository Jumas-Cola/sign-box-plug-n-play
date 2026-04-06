#!/bin/bash
set -euo pipefail

PORT=13336

read -p "Введите IP-адрес Upstream сервера: " UPSTREAM_IP

echo "Генерация UUID..."
UPSTREAM_UUID=$(docker run --rm ghcr.io/sagernet/sing-box generate uuid)

echo "Генерация ключей Reality..."
UPSTREAM_KEYS=$(docker run --rm ghcr.io/sagernet/sing-box generate reality-keypair)
UPSTREAM_PRIVATE=$(echo "$UPSTREAM_KEYS" | grep "PrivateKey:" | awk '{print $2}')
UPSTREAM_PUBLIC=$(echo "$UPSTREAM_KEYS" | grep "PublicKey:" | awk '{print $2}')

echo "Генерация Short ID..."
UPSTREAM_SHORT_ID=$(openssl rand -hex 8)

echo ""
echo "=== Сгенерированные значения ==="
echo "UUID:        $UPSTREAM_UUID"
echo "Private Key: $UPSTREAM_PRIVATE"
echo "Public Key:  $UPSTREAM_PUBLIC"
echo "Short ID:    $UPSTREAM_SHORT_ID"
echo ""

# Серверный конфиг из шаблона
sed \
  -e "s/UPSTREAM-UUID/$UPSTREAM_UUID/g" \
  -e "s/UPSTREAM-PRIVATE-KEY/$UPSTREAM_PRIVATE/g" \
  -e "s/0123456789abcdef/$UPSTREAM_SHORT_ID/g" \
  upstream/config.json.template > upstream/config.json

# Клиентский конфиг для импорта в sing-box
cat > client-config.json <<EOF
{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "dns": {
    "servers": [
      {
        "tag": "dns-remote",
        "address": "tls://8.8.8.8",
        "detour": "proxy"
      },
      {
        "tag": "dns-local",
        "address": "local",
        "detour": "direct"
      }
    ],
    "rules": [
      {
        "outbound": "any",
        "server": "dns-local"
      },
      {
        "domain": [
          "vk.ru",
          "m.vk.ru",
          "mail.ru",
          "www.tinkoff.ru",
          "www.ozon.ru",
          "www.wildberries.ru",
          "gosuslugi.ru",
          "www.mos.ru"
        ],
        "server": "dns-remote"
      }
    ],
    "final": "dns-remote",
    "strategy": "prefer_ipv4"
  },
  "inbounds": [
    {
      "type": "tun",
      "tag": "tun-in",
      "address": ["172.19.0.1/30"],
      "auto_route": true,
      "strict_route": true
    }
  ],
  "outbounds": [
    {
      "type": "vless",
      "tag": "proxy",
      "server": "$UPSTREAM_IP",
      "server_port": $PORT,
      "uuid": "$UPSTREAM_UUID",
      "flow": "xtls-rprx-vision",
      "tls": {
        "enabled": true,
        "server_name": "vk.ru",
        "utls": {
          "enabled": true,
          "fingerprint": "chrome"
        },
        "reality": {
          "enabled": true,
          "public_key": "$UPSTREAM_PUBLIC",
          "short_id": "$UPSTREAM_SHORT_ID"
        }
      }
    },
    {
      "type": "direct",
      "tag": "direct"
    }
  ],
  "route": {
    "auto_detect_interface": true
  }
}
EOF

echo "=== Клиентский конфиг сохранён ==="
echo "Файл: client-config.json"
echo "Импортируйте его в sing-box клиент через Local File"
