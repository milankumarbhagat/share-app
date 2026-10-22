# Deploy NearShare on AWS Lightsail

One server runs three containers:

- **caddy**: HTTPS (automatic Let's Encrypt certificate) and reverse proxy
- **nearshare**: the app (page + signaling server)
- **coturn**: STUN/TURN server, relays transfers when two devices can't connect directly

## 1. Create the server

1. Lightsail console → **Create instance** → Linux/Unix → **OS Only → Ubuntu 24.04 LTS**, 1 GB plan or larger.
2. **Networking → Create static IP** and attach it to the instance.
3. Instance → **Networking → IPv4 firewall**, add:

   | Application | Protocol | Port(s) |
   |---|---|---|
   | SSH | TCP | 22 |
   | HTTP | TCP | 80 |
   | HTTPS | TCP | 443 |
   | Custom | UDP | 443 |
   | Custom | TCP | 3478 |
   | Custom | UDP | 3478 |
   | Custom | UDP | 49152 - 49999 |

4. At your DNS provider, add an **A record** for your domain (e.g. `share.example.com`) pointing to the static IP.

## 2. Install Docker

SSH into the server, then:

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
# log out and back in so the group change applies

# recommended on 1 GB plans: 1 GB swap
sudo fallocate -l 1G /swapfile && sudo chmod 600 /swapfile
sudo mkswap /swapfile && sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# automatic security updates
sudo apt install -y unattended-upgrades
```

## 3. Configure

```bash
git clone https://github.com/milankumarbhagat/share-app.git
cd share-app/deploy

cp .env.example .env
hostname -I | awk '{print $1}'   # this is PRIVATE_IP
openssl rand -hex 24             # use as TURN_PASSWORD
nano .env                        # fill in DOMAIN, PUBLIC_IP, PRIVATE_IP, TURN_PASSWORD

sh generate-rtc-config.sh
```

## 4. Start

```bash
docker compose up -d --build
docker compose ps
docker compose logs -f           # Ctrl+C to stop following
```

Open `https://<DOMAIN>`. The first start can take a minute while Caddy gets the certificate.

## Update

```bash
cd share-app && git pull
cd deploy && docker compose up -d --build
```

If you change `.env`, run `sh generate-rtc-config.sh` again before `docker compose up -d`.

Or, from your own machine after pushing, run `dip deploy`. It needs this in `~/.ssh/config`:

```
Host nearshare
    HostName <static IP>
    User ubuntu
    IdentityFile ~/.ssh/<your key>
    IdentitiesOnly yes
```

## Check the TURN server

Open the [Trickle ICE](https://webrtc.github.io/samples/src/content/peerconnection/trickle-ice/) test page, add
`turn:<DOMAIN>:3478` with your `TURN_USER` / `TURN_PASSWORD`, and click **Gather candidates**.
A `relay` candidate in the results means TURN works.

## Notes

- `RATE_LIMIT=1` tells the app there is one proxy (Caddy) in front of it. Change it if you add another proxy, such as a load balancer or Cloudflare.
- The TURN login is sent to every visitor's browser, so anyone could use it as a relay. The quotas and blocked private IP ranges in `docker-compose.yml` limit what they can do; check Lightsail's data transfer usage now and then.
- Adding another app later: add its service to `docker-compose.yml` and a site block to `Caddyfile`.
