# MaxSpeedVPN — Парсинг протоколов

## Обзор

MaxSpeedVPN поддерживает парсинг VPN-ссылок следующих протоколов:
- VLESS (с XTLS REALITY)
- Trojan
- Shadowsocks (SS)
- VMess

Все парсеры реализованы в `lib/vpn/protocol_parsers/`.

## Формат ссылок

### VLESS

```
vless://uuid@host:port?type=ws&security=tls&fp=chrome&pbk=publickey&sid=shortid&sni=example.com&alpn=h2,http/1.1#ServerName
```

**Параметры:**
| Параметр | Обязательный | Описание |
|----------|-------------|----------|
| uuid | Да | UUID пользователя |
| host | Да | Адрес сервера |
| port | Да | Порт (обычно 443) |
| type | Нет | Тип транспорта (ws, tcp, grpc) |
| security | Нет | Тип безопасности (tls, reality, none) |
| fp | Нет | Fingerprint (chrome, firefox, safari) |
| pbk | Нет | Public key для REALITY |
| sid | Нет | Short ID для REALITY |
| sni | Нет | Server Name Indication |
| alpn | Нет | ALPN протокол |

### Trojan

```
trojan://password@host:port?sni=example.com&alpn=h2,http/1.1&allowInsecure=0#ServerName
```

**Параметры:**
| Параметр | Обязательный | Описание |
|----------|-------------|----------|
| password | Да | Пароль |
| host | Да | Адрес сервера |
| port | Да | Порт (обычно 443) |
| sni | Нет | Server Name Indication |
| alpn | Нет | ALPN протокол |
| allowInsecure | Нет | Разрешить небезопасные (0/1) |

### Shadowsocks

```
ss://base64(method:password)@host:port#ServerName
```

Или в расширенном формате:
```
ss://base64(method:password)@host:port/?plugin=obfs-local#ServerName
```

**Параметры:**
| Параметр | Обязательный | Описание |
|----------|-------------|----------|
| method | Да | Метод шифрования |
| password | Да | Пароль |
| host | Да | Адрес сервера |
| port | Да | Порт |
| plugin | Нет | Плагин (obfs-local, v2ray-plugin) |

**Поддерживаемые методы шифрования:**
- aes-256-gcm
- aes-128-gcm
- chacha20-ietf-poly1305
- xchacha20-ietf-poly1305
- aes-256-cfb
- aes-128-cfb

### VMess

```
vmess://base64({
  "v": "2",
  "ps": "ServerName",
  "add": "host.com",
  "port": "443",
  "id": "uuid",
  "aid": "0",
  "scy": "auto",
  "net": "ws",
  "type": "none",
  "host": "example.com",
  "path": "/ws",
  "tls": "tls",
  "sni": "example.com"
})
```

**Параметры:**
| Параметр | Обязательный | Описание |
|----------|-------------|----------|
| v | Нет | Версия (обычно "2") |
| ps | Нет | Название сервера |
| add | Да | Адрес сервера |
| port | Да | Порт |
| id | Да | UUID |
| aid | Нет | alterId (обычно 0) |
| scy | Нет | Метод шифрования |
| net | Нет | Транспорт (ws, tcp, grpc, h2) |
| type | Нет | Тип маскировки |
| host | Нет | Host для WebSocket |
| path | Нет | Путь для WebSocket |
| tls | Нет | TLS (tls, "") |
| sni | Нет | SNI |

## Парсинг подписок

Подписки могут быть в двух форматах:

### Plain text
```
vless://uuid1@server1.com:443?security=tls#Server1
trojan://pass@server2.com:443#Server2
ss://YWVzLTI1Ni1nY206cGFzc3dvcmQ=@server3.com:8388#Server3
```

### Base64 encoded
```
dmxlc3MvLy4uLgp0cm9qYW4vLy4uLgpzcy8vLi4u
```

Парсер автоматически определяет формат и декодирует base64 при необходимости.

## Генерация sing-box конфига

Каждый парсер генерирует JSON-конфиг для sing-box:

### VLESS + REALITY
```json
{
  "outbounds": [
    {
      "type": "vless",
      "tag": "proxy",
      "server": "host.com",
      "server_port": 443,
      "uuid": "uuid",
      "flow": "xtls-rprx-vision",
      "tls": {
        "enabled": true,
        "server_name": "example.com",
        "utls": {
          "enabled": true,
          "fingerprint": "chrome"
        },
        "reality": {
          "enabled": true,
          "public_key": "publickey",
          "short_id": "shortid"
        }
      }
    },
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "block"
    }
  ],
  "route": {
    "final": "proxy"
  }
}
```

### Trojan
```json
{
  "outbounds": [
    {
      "type": "trojan",
      "tag": "proxy",
      "server": "host.com",
      "server_port": 443,
      "password": "password",
      "tls": {
        "enabled": true,
        "server_name": "example.com",
        "alpn": ["h2", "http/1.1"]
      }
    }
  ]
}
```

### Shadowsocks
```json
{
  "outbounds": [
    {
      "type": "shadowsocks",
      "tag": "proxy",
      "server": "host.com",
      "server_port": 8388,
      "method": "aes-256-gcm",
      "password": "password"
    }
  ]
}
```

## Обработка ошибок

Парсеры обрабатывают следующие ошибки:
- Невалидный URL — пропускается
- Невалидный base64 — пропускается
- Отсутствие обязательных параметров — пропускается
- Неизвестный протокол — пропускается

Все ошибки логируются через LogService.
