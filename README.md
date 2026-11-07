# hcps-connect

Connects the HCPS server and St. Jude's billing server over a private, encrypted
network ([Tailscale](https://tailscale.com), built on WireGuard). Nothing is opened
to the internet and no inbound firewall rules or VPN licence are needed: each
machine only makes outbound connections.

The API's own TLS and mTLS run inside the tunnel, end to end.

## 1. Admin (once)

1. Sign in at https://login.tailscale.com.
2. Open **Access controls** and replace the policy with [`policy.hujson`](policy.hujson).
   Set St. Jude's callback port in it.

## 2. HCPS server (Ubuntu)

```bash
curl -fsSL https://raw.githubusercontent.com/nkrumahthis/hcps-connect/main/setup.sh -o setup.sh && sudo bash setup.sh hcps
```

A login link appears. Send it to the admin, who opens it and approves.
When it finishes, send the admin the private address it prints.

## 3. St. Jude's billing server

- **Linux:** same command, ending in `stjude` instead of `hcps`.
- **Windows:** install Tailscale from https://tailscale.com/download/windows and
  sign in with the link the admin sends. The admin then sets the machine's tag
  to `tag:stjude` in the admin console.

## What each machine can reach

| From | To | Ports |
|---|---|---|
| St. Jude billing | HCPS server | 443 (API) |
| HCPS server | St. Jude billing | callback port only |
| Admins | HCPS server | all (incl. SSH) |

Everything else is blocked.
