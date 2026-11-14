# weka

Home server: NixOS on bare metal (Ryzen 7 3700X, X470, Samsung 970 EVO 1 TB
NVMe, 2× 4 TB WD Red Plus as `tank1`). Nothing is exposed to the internet.
Apps are reached over Tailscale, and a few LAN-only devices use its LAN
address, `192.168.10.101`.

- Deploy: `just weka-deploy`
- Secrets: `just weka-secrets` (sops, `./secrets.yaml`; recipients in `/.sops.yaml`)
- Start page: https://home.tarpan-krait.ts.net

The module comments explain how each part works. This file covers what
spans several modules, and the state that lives outside the repo.

## Layout

- `default.nix`: host identity (users, SSH, Tailscale, sops) and imports
- `base/`: the machine itself: disks (`disko.nix`, `tank1.nix`), the UPS,
  and unlocking the root pool at boot (`unlock.nix`)
- `platform/`: what every app plugs into: Tailscale Services and Homepage
- `backup/`: sanoid/syncoid snapshots and restic to B2
- `monitoring/`: Prometheus and alerts, Grafana, Loki
- `apps/`: one file, or a directory when it has more than one, per app

## Adding an app

1. Define the Tailscale Service in the admin console (`tcp:443`, tag
   `tag:weka-svc`) **before** deploying. See `platform/tailscale-services.nix` for
   what happens if it's done the other way round.
2. Add `apps/<app>.nix` and import it in `apps/default.nix`. Bind the app
   to `127.0.0.1` and set `weka.tailscaleServices.<app> = <port>;`.
3. If the app keeps state, give it a dataset in the same file:
   `weka.datasets."data/<app>" = "<its state dir>";` (snapshotted and backed
   up), or `"nosnap/<app>"` (neither). Check whether the module uses
   `DynamicUser` (state in `/var/lib/private/<app>`) or not
   (`/var/lib/<app>`). disko only runs at install, so also create it on weka:
   `sudo zfs create -o mountpoint=legacy rpool/crypt/data/<app>`.
4. Deploy. Then `sudo systemctl start sanoid`, or `ZfsSnapshotsStale` fires
   until sanoid's next hourly run.

   Modules that set their data dir's permissions with tmpfiles (radarr,
   lidarr, qbittorrent) instead of systemd's `StateDirectory` (sonarr, prowlarr) race a
   fresh dataset: tmpfiles runs at activation, before the dataset's mount
   unit exists, so the dirs are created on the pool root and then hidden by
   the mount. The app crashes with permission denied and hits its start
   limit. Fix, after the mounts are up: `sudo systemd-tmpfiles --create`
   and `sudo systemctl reset-failed <app>.service && sudo systemctl start
   <app>.service`. Fine after any reboot, which mounts before tmpfiles.

sanoid, syncoid and restic pick up a new `crypt/data` dataset with no
extra config, and Homepage lists the new service under "Other" (give it a
group, icon and widgets with `weka.homepage.<app>` in the app's file).

## Removing an app

1. Delete its file or directory and its line in `apps/default.nix`. Deploy.
2. On weka, `tailscale serve clear svc:<app>`: removing the service from the
   config doesn't stop serving it. Then delete the Service in the admin
   console.
3. Its dataset stays on the pool, unmounted, with its snapshots. When it's
   no longer wanted: `sudo zfs destroy -r rpool/crypt/data/<app>`, and the
   same for its syncoid copy, `tank1/backup/weka/<app>`. restic's older
   snapshots keep it until they age out of the retention.
4. Remove its keys from `secrets.yaml` (`just weka-secrets`).

## Reboots and unlocking

The root pool is encrypted (passphrase in 1Password: "weka zfs"). At boot,
clevis unlocks it by itself from a Tang server: keystone, a Cloudflare Worker
at `tang.jackrose.co.nz/weka`, deployed from the infra repo (`tang/README.md`)
and answering only the home IPv4. curl retries for up to 90 seconds, then the
boot falls back to asking for the passphrase. Kernel updates arrive with the
weekly autoUpgrade, but rebooting is still manual while auto-unlock is tested
(issue #4).

The passphrase sealed to the Tang key is `/etc/secrets/initrd/rpool-crypt.jwe`,
kept out of the store like the initrd SSH key. To remake it after rotating the
key set (or losing it), on weka, with the new set's thp:

```sh
nix shell nixpkgs#clevis
read -rs pass   # the passphrase
printf '%s' "$pass" \
  | clevis encrypt tang '{"url":"https://tang.jackrose.co.nz/<set>","thp":"<thp>"}' \
  | sudo tee /etc/secrets/initrd/rpool-crypt.jwe >/dev/null
unset pass
sudo chmod 600 /etc/secrets/initrd/rpool-crypt.jwe
sudo cat /etc/secrets/initrd/rpool-crypt.jwe | clevis decrypt | sudo zfs load-key -n rpool/crypt
sudo /run/current-system/bin/switch-to-configuration boot   # re-copy initrd secrets
```

If it didn't unlock itself:

- At home: `just weka-unlock` (gets passphrase from 1Password)
- Away: switch the phone from Tailscale to the UniFi WireGuard VPN, unlock
  the same way, switch back.

Until it's unlocked everything is down, Home Assistant included.
Healthchecks.io notices the missing Watchdog ping and posts to Slack.

`tank1` unlocks by itself after the root pool is unlocked (key in sops).

## Storage and data protection

| Dataset | What | Snapshots | Offsite |
|---|---|---|---|
| `rpool/crypt/{root,nix,home}` | OS, rebuilt from this repo | no | no |
| `rpool/crypt/data/<app>` | app state, Samba share | sanoid: hourly ×24, daily ×30, monthly ×6 | restic → B2, daily |
| `rpool/crypt/nosnap/<app>` | Prometheus, Loki | no | no |
| `tank1/media` | films and TV | sanoid: daily ×14 | no, it's replaceable |
| `tank1/backup/weka/<app>` | syncoid copy of `crypt/data`, daily | hourly ×24, daily ×30, monthly ×12 | no |
| `tank1/hs` | old experiments, to sort through | no | one-off restic snapshot (tag `tank1-hs`) |

What each layer covers:

| What fails | Recovered from |
|---|---|
| Accidental delete, bad upgrade | sanoid snapshot on rpool |
| The NVMe | syncoid copy on `tank1` |
| The whole box or house | restic on B2 |

There's no ECC, so bad RAM can write corrupt data that ZFS and restic then
keep faithfully. The long restic retention (7 daily, 8 weekly, 12 monthly)
is there to reach back before that started. Restore by hand every few
months to check the backups.

### Restoring

- **From a local snapshot**: files are under `<mountpoint>/.zfs/snapshot/<name>/`.
  `zfs list -t snapshot rpool/crypt/data/<app>`, then copy back, or
  `zfs rollback` with the app stopped.
- **From the tank1 copy**: `zfs list -t snapshot -r tank1/backup/weka/<app>`,
  then `zfs clone` a snapshot with a temporary mountpoint and copy files
  back, or `zfs send | zfs recv` it onto a new rpool dataset.
- **From B2**: `sudo restic-weka snapshots`, then
  `sudo restic-weka restore latest --target /var/tmp/restore --include /var/lib/private/<app>`.
  Stop the app, copy the files back from under `.zfs/snapshot/restic/`, and
  start it. From another machine, use the repo URL in `backup/restic.nix`, the
  two B2 values as `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`
  (1Password: "weka-backblaze") and the repo password ("weka restic").

The B2 bucket keeps old file versions for 14 days, so files a mistaken
`restic forget`/`prune` deleted can be un-hidden in B2 for that long.

## Monitoring

- https://grafana.tarpan-krait.ts.net: dashboards and logs. Logs in from
  your Tailscale identity; the admin password is in 1Password ("weka grafana").
- https://prometheus.tarpan-krait.ts.net: the Alerts tab shows every rule and its state.
- https://alertmanager.tarpan-krait.ts.net: silences.

Alerts go to Slack, `#weka-alerts` (Slack app "Weka", incoming webhook).
Nothing pages. A known, accepted problem gets a silence rather than being
left firing. The Watchdog alert pings the Healthchecks.io check "weka
watchdog" (period 5 min, grace 5 min), which posts to the same channel
when the pings stop.

## Home Assistant

Configured in its UI, with state in `/var/lib/hass`. Things that aren't
obvious from `apps/home-assistant.nix`:

- HA must trust Tailscale Serve as a proxy (`use_x_forwarded_for: true`,
  `trusted_proxies: [127.0.0.1, ::1]`). These live in `.storage/http`,
  under `stable`, not in YAML. Edit that file with HA stopped. The UI's
  way stages a pending config that reverts unless confirmed in 5 minutes.
- Its external URL is `https://home-assistant.tarpan-krait.ts.net` and its
  internal URL `http://192.168.10.101:8123`.
- MQTT devices (Tasmota, Faikin, Valetudo) point at `192.168.10.101:1883`
  by IP, with the `mqtt` login.

## LAN-only clients

These use `192.168.10.101` directly because they can't run Tailscale:

- Brother scanner: FTP into Paperless's consume folder (`apps/paperless.nix`).
- PS5: Plex on 32400 (`apps/plex.nix`).
- MQTT devices, HomeKit and Home Assistant's mobile apps on the LAN.

## Outside the repo

- **UniFi**: fixed DHCP lease for `192.168.10.101` (by MAC; the initrd
  uses the MAC as its client ID so unlock gets the same address).
  A WireGuard VPN with access to the whole home network, as a fallback for
  when Tailscale isn't working: from away it reaches the unlock prompt on
  port 2222 and normal SSH. The Tasmota, Faikin and vacuum devices are on other
  VLANs, and the firewall lets them reach weka's MQTT.
- **Tailscale admin console**: weka is a tagged device (`tag:server`, no
  key expiry). HTTPS certificates are on. The policy file has `tag:weka-svc`
  in `tagOwners` and
  `"autoApprovers": {"services": {"tag:weka-svc": ["tag:server"]}}`. Each
  Tailscale Service is defined there.
- **Backblaze B2**: bucket `weka-backups`, an application key scoped to
  it, a lifecycle rule keeping prior versions for 14 days.
- **Healthchecks.io** and **Slack** as above.
- **1Password**: "weka zfs" (root passphrase), "weka restic", "weka-backblaze",
  "weka grafana", the tank1 key, the initrd SSH host key, and
  "nixfiles age key" (the sops admin key).

## Reinstalling

From the NixOS installer USB, using nixos-anywhere from another machine:

1. On weka's console: `passwd` (for the `nixos` user), `ip -br a` for its
   IP, `lsblk` to check the NVMe is `nvme0n1`. Then `ssh-copy-id nixos@<ip>`.
2. Put the initrd SSH host key (1Password) in a directory at
   `etc/secrets/initrd/ssh_host_ed25519_key`.
3. From this repo (fish):
   ```
   nix run github:nix-community/nixos-anywhere -- \
     --flake .#weka --target-host nixos@<ip> --build-on remote \
     --generate-hardware-config nixos-generate-config ./hosts/weka/base/hardware.nix \
     --extra-files <that dir> \
     --disk-encryption-keys /tmp/secret.key (op read -n "op://Personal/weka zfs/password" | psub -F)
   ```
   `-n` because a trailing newline would become part of the passphrase,
   `psub -F` so it's a pipe rather than a temp file.
4. Reboot, unlock on port 2222, `ssh jack@<ip>`.
5. The new SSH host key means a new sops identity: update the `weka` key in
   `/.sops.yaml` (`ssh-to-age` on the new public key), run
   `sops updatekeys hosts/weka/secrets.yaml`, and deploy.
6. Join Tailscale by hand with `tailscale up --advertise-tags=tag:server`
   (remove the old node first). `tank1` imports at boot once sops can
   decrypt its key. Restore app data from the tank1 copy or B2.
