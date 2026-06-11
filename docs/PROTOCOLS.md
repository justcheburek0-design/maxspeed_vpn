# Протоколы VPN — Справочник

## Обзор протоколов

| Протокол | Транспорт | Порты | Безопасность |
|----------|-----------|-------|-------------|
| VLESS | TCP/UDP | 443, 8443 | TLS/REALITY |
| VMess | TCP/UDP | 443, 10086 | AES-128/256, ChaCha20 |
| Trojan | TCP | 443 | TLS 1.2/1.3 |
| Shadowsocks | TCP/UDP | 8388 | AEAD (AES-GCM, ChaCha20) |
| Hysteria | UDP | 443, 8443 | QUIC/TLS 1.3 |
| WireGuard | UDP | 51820 | ChaCha20, Curve25519 |
| TUIC | UDP | 443 | TLS 1.3 + UDP mux |

## Заметки

- **VLESS + REALITY** — рекомендуемый протокол, маскировка под TLS без сертификата
- **Trojan** — маскировка под HTTPS, нужен валидный TLS-сертификат
- **Shadowsocks** — лёгкий, быстрый, но менее скрытный
- **VMess** — встроенное шифрование, устаревает в пользу VLESS
- **Hysteria** — высокая пропускная способность в сетях с потерями (QUIC)
- **WireGuard** — минималистичный, аудируемый, быстрый
- **TUIC** — низкая латентность через UDP-мультиплексирование

## Парсинг ссылок

### VLESS
```
vless://uuid@host:port?type=ws&security=tls&fp=chrome&pbk=key&sid=sid&sni=example.com#Name
```
Параметры: type, security, fp, pbk, sid, sni, alpn, flow

### Trojan
```
trojan://password@host:port?sni=example.com&alpn=h2,http/1.1&allowInsecure=0#Name
```
Параметры: sni, alpn, allowInsecure

### Shadowsocks
```
ss://base64(method:password)@host:port#Name
```
Методы: aes-256-gcm, aes-128-gcm, chacha20-ietf-poly1305, xchacha20-ietf-poly1305

### VMess
```
vmess://base64({"v":"2","ps":"Name","add":"host","port":"443","id":"uuid","aid":"0","scy":"auto","net":"ws","type":"none","host":"example.com","path":"/ws","tls":"tls","sni":"example.com"})
```

## Генерация sing-box конфига

### VLESS + REALITY
```json
{
  "outbounds": [{
    "type": "vless", "tag": "proxy",
    "server": "host.com", "server_port": 443, "uuid": "uuid",
    "flow": "xtls-rprx-vision",
    "tls": {
      "enabled": true, "server_name": "example.com",
      "utls": {"enabled": true, "fingerprint": "chrome"},
      "reality": {"enabled": true, "public_key": "key", "short_id": "sid"}
    }
  }, {"type": "direct", "tag": "direct"}, {"type": "block", "tag": "block"}],
  "route": {"final": "proxy"}
}
```

### Trojan
```json
{
  "outbounds": [{
    "type": "trojan", "tag": "proxy",
    "server": "host.com", "server_port": 443, "password": "pass",
    "tls": {"enabled": true, "server_name": "example.com", "alpn": ["h2", "http/1.1"]}
  }]
}
```

### Shadowsocks
```json
{
  "outbounds": [{
    "type": "shadowsocks", "tag": "proxy",
    "server": "host.com", "server_port": 8388,
    "method": "aes-256-gcm", "password": "pass"
  }]
}
```

## Обработка ошибок

Невалидный URL, base64, отсутствие обязательных параметров, неизвестный протокол — всё пропускается с логированием через LogService.
