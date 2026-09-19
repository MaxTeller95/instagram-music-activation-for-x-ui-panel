# Instagram Music Activation for x-ui panel

Bring back the **Instagram Music sticker** when your x-ui server exits through a
datacenter / VPN IP — **without** paying for a residential proxy on your whole
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
call** to `i.instagram.com`, and then **caches that decision server-side for
~1.5–2 hours**. The heavy stuff — reels, photos, video, even the music audio
clips — is delivered separately (`*.cdninstagram.com`) and does **not** need a
special IP.

So this tool routes **only `i.instagram.com`**, **only for a few minutes every
~90 minutes**, through a **residential SOCKS outbound** you add to x-ui. That
periodically re-registers your account in a music-enabled region while your
account's cache keeps music visible the whole time — and essentially no traffic
goes through the (metered, expensive) residential proxy.

```
 app ─► x-ui ─► i.instagram.com   (region check)   ─► residential   ◄ tiny, ~5 min / 90 min
              ╰► everything else  (feed, media, …)  ─► your normal exit  ◄ free
```

Nothing else in your panel is touched: only one routing rule is added/removed,
the panel version and all your other routing stay exactly as they are, and
`x-ui.db` is backed up before every change.

## Requirements

- A working **x-ui / 3x-ui** panel (uses `xrayTemplateConfig` in `x-ui.db`).
- A **residential proxy** (SOCKS5) in a music-licensed country (US, GB, DE, …).
  Datacenter proxies usually won't unlock music — the installer warns you if
  yours looks like a datacenter IP.

## Install

1. In the x-ui panel: **Xray Settings → Outbounds → +**
   - Protocol: `socks`
   - **Tag: `residental`**
   - Address / Port / Username / Password: your residential proxy
   - Save (no need to restart anything yet).

2. On the server:

```bash
git clone https://github.com/MaxTeller95/instagram-music-activation-for-x-ui-panel.git
cd instagram-music-activation-for-x-ui-panel
sudo bash install.sh
```

The installer verifies the proxy (egress country + residential check), enables a
systemd timer, and does a first activation. Close and reopen Instagram — the
Music sticker is back.

## Usage

```bash
sudo igmusic check       # verify x-ui + the residential proxy egress
sudo igmusic install     # enable the automatic refresh (systemd timer)
sudo igmusic status      # route state, timer, next refresh, residential MB used
sudo igmusic refresh     # run one refresh cycle right now
sudo igmusic on|off      # manually pin the route on / off
sudo igmusic uninstall   # remove the timer, send Instagram back to the normal exit

sudo igmusic install --interval 90 --window 300   # tune cadence (minutes / seconds)
```

## How it stays cheap

- Only `i.instagram.com` (JSON API) is ever routed through residential — never
  the media CDNs. Media, reels and the music audio go through your free exit.
- The route is **on ~5 min per ~90 min**, off the rest of the time.
- `igmusic status` prints how many MB actually went through the residential
  outbound.

## Notes & caveats

- Each refresh briefly **restarts Xray** (a few seconds) to apply the routing
  change. On a busy panel, raise `--interval` to restart less often.
- Music availability also depends on your **account's region**. If the account
  itself is set to a no-music country, an IP alone may not be enough.
- Instagram may show a **"suspicious login / verify it's you"** the first time
  the API appears from a new country — just confirm it.
- Some residential providers rotate IPs; a **sticky** session is best so the
  region stays consistent.

## License

MIT — see [LICENSE](LICENSE).
