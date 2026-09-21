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

## Notes & caveats

- Only `i.instagram.com` / `b.i.instagram.com` (small JSON API) go through the
  outbound — never the media CDNs, so reels/photos/video and the music audio
  stay on your free exit.
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
