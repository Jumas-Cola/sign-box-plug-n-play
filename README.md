# sing-box-plug-n-play

Готовые конфигурации и скрипт для быстрого развёртывания Upstream-сервера на базе [sing-box](https://github.com/SagerNet/sing-box).

```
Client --> Upstream Server --> Internet
```

Используется протокол **VLESS + Reality + Vision** для маскировки трафика под обращения к популярным веб-ресурсам.

## Структура

- `upstream/` — конфигурация и docker-compose для Upstream-сервера
- `generate-keys.sh` — скрипт автоматической генерации ключей и UUID
- `client-config.json` — клиентский конфиг (создаётся после запуска скрипта)

## Быстрый старт

1. Запустите `generate-keys.sh` и сохраните сгенерированные значения
2. На сервере выполните `docker compose up -d` в директории `upstream/`
3. Импортируйте `client-config.json` в клиент sing-box одним из способов ниже

## Импорт конфига в клиент

Официальный клиент sing-box поддерживает несколько способов:

| Способ | Как использовать |
|---|---|
| **Local File** | Перенесите `client-config.json` на устройство и импортируйте как локальный файл |
| **QR-code** | Сгенерируйте QR-код из содержимого конфига |
| **Manual** | Вручную заполните параметры из вывода `generate-keys.sh` |

## Рекомендуемые домены для маскировки

В `upstream/config.json` (поля `server_name`, `handshake.server`):

| Домен | Ресурс |
|---|---|
| `vk.ru` | ВКонтакте |
| `m.vk.ru` | ВКонтакте (мобильная) |
| `mail.ru` | Mail.ru |
| `www.tinkoff.ru` | Тинькофф Банк |
| `www.ozon.ru` | Ozon |
| `www.wildberries.ru` | Wildberries |
| `gosuslugi.ru` | Госуслуги |
| `www.mos.ru` | Портал мэра Москвы |

> Домен должен поддерживать TLS 1.3 и HTTP/2. Проверка: `curl -I --tlsv1.3 --http2 https://vk.ru`
