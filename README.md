# Instagram Music Activation for x-ui panel

Bring back the **Instagram Music sticker** when your x-ui server exits through a
datacenter / VPN IP, **without** paying for a residential proxy on your whole
Instagram traffic.

## The problem

Instagram hides the *Music* sticker (you only get "suggested" on stories, no
music icon) when it sees your connection coming from:

- a **datacenter / VPN IP** (a normal VPS, Cloudflare WARP, most proxies), or
- a **region without music licensing**.

If your traffic goes out through such an exit, music disappears even though
everything else works.

## The idea (and why it's cheap)

Instagram decides whether music is available from a small **region-check API
call** to `i.instagram.com`, and then **caches that decision server-side** for a
while. The heavy stuff — reels, photos, video, even the music audio clips — is
delivered separately (`*.cdninstagram.com`) and does **not** need a special IP.

So this tool routes **only `i.instagram.com`**, **only for a few minutes when
needed**, through a **residential SOCKS outbound** you add to x-ui. That
re-registers your account in a music-enabled region while the account's cache
keeps music visible — and essentially no traffic goes through the (metered,
expensive) residential proxy.

```
 app -> x-ui -> i.instagram.com   (region check)   -> residential   <- tiny, only when needed
              \> everything else  (feed, media, ...) -> your normal exit  <- free
```

Nothing else in your panel is touched: only one routing rule is added/removed,
the panel version and all your other routing stay exactly as they are, and
`x-ui.db` is backed up before structural changes.

## Two refresh modes

- **reactive** *(default, recommended)* — a lightweight watcher reads x-ui's
  access log and notices **when you are actually using Instagram**, then refreshes
  the region right then, at most once per `--cooldown`. Residential is touched
  **only while you use Instagram** and never on a blind schedule, so it can't
  "miss" you (the failure mode of a fixed timer) and burns almost no data.
- **timer** — refresh on a fixed `--interval` via a systemd timer, whether or not
  the app is open. Simpler, but music can lapse if the window doesn't overlap
  your usage.

## Requirements

- A working **x-ui / 3x-ui** panel (uses `xrayTemplateConfig` in `x-ui.db`).
- A **residential proxy** (SOCKS5) in a music-licensed country (US, GB, DE, ...).
  Datacenter proxies usually won't unlock music — `igmusic check` warns you if
  yours looks like a datacenter IP.
- Reactive mode uses x-ui's Xray **access log**; the installer enables it if it's
  off.

## Install

1. In the x-ui panel: **Xray Settings → Outbounds → +**
   - Protocol: `socks`
   - **Tag: `residental`**
   - Address / Port / Username / Password: your residential proxy
   - Save.

2. On the server:

```bash
git clone https://github.com/MaxTeller95/instagram-music-activation-for-x-ui-panel.git
cd instagram-music-activation-for-x-ui-panel
sudo bash install.sh
```

The installer verifies the proxy (egress country + residential check), enables the
reactive watcher, and does a first activation. Close and reopen Instagram — the
Music sticker is back.

## Usage

```bash
sudo igmusic check       # verify x-ui + the residential proxy egress
sudo igmusic install     # enable automatic activation (reactive mode)
sudo igmusic status      # mode, route state, watcher, last refresh, residential MB
sudo igmusic refresh     # run one refresh cycle right now
sudo igmusic on|off      # manually pin the route on / off
sudo igmusic uninstall   # remove the watcher/timer, Instagram back to the normal exit

# tuning
sudo igmusic install --cooldown 90 --window 180        # reactive: min minutes between refreshes / on-window
sudo igmusic install --mode timer --interval 90        # switch to the fixed-timer mode
```

## How it stays cheap

- Only `i.instagram.com` (JSON API) is ever routed through residential — never the
  media CDNs. Media, reels and the music audio go through your free exit.
- Reactive mode touches residential **only while you're using Instagram**, at most
  once per cooldown.
- `igmusic status` prints how many MB actually went through the residential
  outbound.

## Notes & caveats

- Each refresh briefly **restarts Xray** (a few seconds) to apply the routing
  change. Reactive mode does this at most once per cooldown, only when you use
  Instagram.
- Music availability also depends on your **account's region**. If the account
  itself is set to a no-music country, an IP alone may not be enough.
- Instagram may show a **"suspicious login / verify it's you"** the first time the
  API appears from a new country — just confirm it.
- A **sticky** residential session (stable IP) is best so the region stays
  consistent.

## License

MIT — see [LICENSE](LICENSE).
