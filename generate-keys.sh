#!/bin/bash

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

sed -i "s/UPSTREAM-UUID/$UPSTREAM_UUID/g" upstream/config.json
sed -i "s/UPSTREAM-PRIVATE-KEY/$UPSTREAM_PRIVATE/g" upstream/config.json
sed -i "s/0123456789abcdef/$UPSTREAM_SHORT_ID/g" upstream/config.json

echo "=== Ссылка для подключения ==="
echo "vless://${UPSTREAM_UUID}@${UPSTREAM_IP}:13336?encryption=none&security=reality&sni=vk.ru&fp=chrome&pbk=${UPSTREAM_PUBLIC}&sid=${UPSTREAM_SHORT_ID}&type=tcp&flow=xtls-rprx-vision#sing-box-upstream"
