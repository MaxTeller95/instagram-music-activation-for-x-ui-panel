# Instagram Music Activation for x-ui panel

Bring back the **Instagram Music sticker** when your x-ui server exits through a
datacenter / VPN IP, with a single **static** routing rule — no timers, no
background services, no restart loops.

## The problem

Instagram hides the *Music* sticker (you only get "suggested" on stories, no
music icon) when it sees your connection coming from:

- a **datacenter / VPN IP** (a normal VPS, Cloudflare WARP, most proxies), or
- a **region without music licensing**.

If your traffic goes out through such an exit, music disappears even though
everything else works.

## How Instagram decides your location

Instagram reads your region from the **IP of your app's calls to
`i.instagram.com`** (its main private API; `b.i.instagram.com` is a mirror).
Whatever IP those calls come from is the region Instagram registers for your
account — and that region gates the music sticker. The heavy media
(`*.cdninstagram.com`, reels, photos, video, the music audio itself) is just a
CDN and plays no part in the location decision.

There are two separate gates, and they are answered by two different hosts:

| What you want | Decided from | Host |
|---|---|---|
| The **Music sticker** on your own story | your account's region | `i.instagram.com` |
| **Hearing** music on other people's stories | the music metadata call | `graph.instagram.com` |

Route only the first and the sticker comes back while other people's stories
still say *"Audio unavailable"* — that is the usual half-fixed state. Both are in
the defaults, together with `b.i.instagram.com`, the API fallback
`i-fallback.instagram.com` and the realtime channel `edge-mqtt.facebook.com`, so
no side channel reports the real region.

## What this tool does

It permanently routes **only those two region-check hosts** through an outbound
you add to x-ui whose egress IP is in the **US** (or another music-licensed
country). Everything else keeps using your normal, free exit.

```
 app -> x-ui -> i.instagram.com / b.i.instagram.com  -> IGMUSIC outbound (US IP)
              \> everything else (feed, media, reels) -> your normal exit  (free)
```

Because Instagram now always sees the region check from the US IP, the music
sticker stays — with no timers, watchers or refresh cycles. It's one static
routing rule. `x-ui.db` is backed up before the change and nothing else in your
panel is touched.

## The outbound: any config with a US IP

The `IGMUSIC` outbound can be **any protocol your x-ui panel supports**, as long
as its **egress IP is a US IP** (or another Instagram-music country):

- a **residential / mobile SOCKS or HTTP proxy** in the US (most reliable), or
- **VLESS / VMess / Trojan / Shadowsocks** to a US server you own, or
- **WireGuard**, etc.

A residential/mobile US IP is the most reliable; a plain US datacenter IP may
still work but Instagram trusts it less. `igmusic check` tells you the egress
IP, its country, and whether it looks residential.

## Install

1. In the x-ui panel: **Xray Settings → Outbounds → +**
   - Add any outbound (see above) whose exit IP is in the US.
   - **Tag it: `IGMUSIC`**
   - Save.

2. On the server, either the one-liner **or** a git clone:

**One-line (bash, no clone):**

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/MaxTeller95/instagram-music-activation-for-x-ui-panel/master/install.sh)"
```

> The one-liner downloads the CLI from the repo, so it needs the repo to be
> **public**. For a private repo use the git-clone method below.

**Git clone:**

```bash
git clone https://github.com/MaxTeller95/instagram-music-activation-for-x-ui-panel.git
cd instagram-music-activation-for-x-ui-panel
sudo bash install.sh
```

Close and reopen Instagram — the Music sticker is back.

## Usage

```bash
sudo igmusic check          # verify x-ui + the outbound, show its egress IP/country
sudo igmusic install        # add the static rule (region check -> IGMUSIC)
sudo igmusic status         # show route state + how much data used the outbound
sudo igmusic uninstall      # remove the rule (Instagram back on the normal exit)

sudo igmusic install --tag MYNAME   # if you named the outbound something else
```

## Staying inside a metered proxy's allowance

Residential proxies are sold by the gigabyte, and on a panel with more than a
couple of users `i.instagram.com` is not a trickle: on a hub with ~50 users
online it measured **250 MB/hour, about 180 GB/month**. If the allowance runs
out mid-month the proxy stops answering and then Instagram breaks completely -
not just the music.

`igmusic-budget` makes that failure a graceful one. It never touches the routing
rule; it watches how much the outbound has carried, warns on Telegram on the way
up, and when the allowance is gone it swaps the **outbound behind the tag** for a
free one. The region-check hosts keep working from the server's normal IP - you
lose the music sticker, not Instagram. On the first of the month it puts the
residential outbound back. Every swap goes through Xray's API: nothing restarts
and nobody is disconnected.

```bash
sudo igmusic-budget --limit 200        # your allowance, in GB per month
sudo systemctl enable --now igmusic-budget.timer
igmusic-budget                         # used / projected / parked?
igmusic-budget --json
sudo igmusic-budget park               # park it by hand
sudo igmusic-budget resume
```

```
[*]  outbound          : IGMUSIC
[*]  month             : 2026-09  (day 24)
[*]  used              : 42.10 of 200.0 GB  (21.1%)
[*]  at this pace      : 54 GB by the end of the month
[ok]  route            : residential
```

Alerts go out at 70%, 85% and 95% (`alert_at` in `/etc/igmusic/config.json`)
through the panel's own Telegram bot, or `tg_token` / `tg_chat` if you set them.
Xray's counters reset to zero on every restart, so the watcher stores the raw
counter each tick and adds only what appeared since the previous one - a restart
reads as the counter going backwards and is handled as such.

If `/var/lib/igmusic/off.json` exists (an outbound with the same tag - a WARP
config, say) it parks on that instead of plain `freedom`.

## Notes & caveats

- Only the API hosts (small JSON) go through the outbound — never the media
  CDNs, so reels/photos/video and the music audio stay on your free exit.
- **QUIC is blocked for those hosts.** A SOCKS proxy usually cannot carry UDP, so
  an app speaking HTTP/3 would go around the outbound and Instagram would see
  your real exit — the tool would look installed and do nothing. Blocking UDP for
  exactly those hosts makes the app fall back to TCP. Set `"block_quic": false`
  in `/etc/igmusic/config.json` if your outbound does carry UDP.
- The rules carry the tags `igmusic` and `igmusic-quic-block`, so they can be
  found (and removed) again later.
- Applying / removing the rule restarts Xray once (a few seconds); after that it
  is completely static.
- Music availability also depends on your **account's region**. If the account
  itself is set to a no-music country, an IP alone may not be enough.
- Instagram may show a **"suspicious login / verify it's you"** the first time
  the API appears from a new country — just confirm it.
- A **sticky** outbound IP (stable, not rapidly rotating) keeps the region
  consistent.

## License

MIT — see [LICENSE](LICENSE).
