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
        "type": "tls",
        "server": "8.8.8.8",
        "detour": "direct"
      },
      {
        "tag": "dns-local",
        "type": "local"
      }
    ],
    "rules": [
      {
        "rule_set": "geosite-category-ru",
        "action": "route",
        "server": "dns-local"
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
      "tag": "direct",
      "domain_resolver": {
        "server": "dns-local"
      }
    }
  ],
  "route": {
    "final": "proxy",
    "auto_detect_interface": true,
    "default_domain_resolver": {
      "server": "dns-remote"
    },
    "rules": [
      {
        "action": "sniff"
      },
      {
        "protocol": "dns",
        "action": "hijack-dns"
      },
      {
        "rule_set": ["geoip-ru", "geosite-category-ru"],
        "action": "route",
        "outbound": "direct"
      }
    ],
    "rule_set": [
      {
        "tag": "geoip-ru",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/geoip-ru.srs",
        "download_detour": "direct"
      },
      {
        "tag": "geosite-category-ru",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-category-ru.srs",
        "download_detour": "direct"
      }
    ]
  },
  "experimental": {
    "cache_file": {
      "enabled": true
    }
  }
}
EOF

echo "=== Клиентский конфиг сохранён ==="
echo "Файл: client-config.json"
echo "Импортируйте его в sing-box клиент через Local File"
