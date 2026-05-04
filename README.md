# PostHog self-hosted — Coolify / Docker Compose

Déploiement clé en main de [PostHog](https://posthog.com) en mode **hobby** sur [Coolify](https://coolify.io) via Docker Compose.

> **Ressources minimales recommandées : 8 Go de RAM, 4 vCPU, 50 Go de disque.**  
> Le premier démarrage prend 5 à 10 minutes (migrations Postgres + ClickHouse).

---

## Architecture

```
Internet ──HTTPS──▶ Traefik (Coolify)
                         │ HTTP
                         ▼
                    Caddy (proxy)  ──▶ web:8000       (interface PostHog)
                         │         ──▶ capture:3000   (ingestion d'événements)
                         │         ──▶ replay-capture  (enregistrements)
                         │         ──▶ feature-flags  (feature flags)
                         │         ──▶ hypercache      (surveys, remote config)
                         │         ──▶ plugins:6738    (webhooks CDP)
                         └─────────▶  …
```

**Coolify gère le SSL (Let's Encrypt via Traefik). Caddy route en HTTP pur en interne.**

---

## Déploiement sur Coolify

### 1. Préparer le repo

```bash
git clone https://github.com/<toi>/posthog-coolify
```

### 2. Créer le service dans Coolify

1. **Nouveau Projet** → **Nouvelle Ressource** → **Docker Compose**
2. Source : **Git Repository** → ton fork de ce repo
3. Fichier Compose : `docker-compose.yml`
4. **Pre-deploy Command** : `bash setup.sh`

### 3. Configurer les variables d'environnement

Dans Coolify → ton service → **Environment Variables** :

| Variable | Description | Exemple |
|---|---|---|
| `DOMAIN` | Ton domaine public | `posthog.exemple.com` |
| `POSTHOG_SECRET` | Clé secrète Django | `openssl rand -hex 28` |
| `ENCRYPTION_SALT_KEYS` | Clé de chiffrement | `openssl rand -hex 16` |
| `POSTHOG_APP_TAG` | Version de PostHog | `latest` |

### 4. Configurer le routing dans Coolify

- **Service exposé** : `proxy`
- **Port** : `80`
- **Domain** : ton domaine
- **SSL** : activé (Let's Encrypt)

### 5. Déployer

Cliquer sur **Deploy**. Surveiller les logs — le démarrage complet prend ~10 min.

---

## Déploiement manuel (sans Coolify)

```bash
# 1. Cloner ce repo
git clone https://github.com/<toi>/posthog-coolify && cd posthog-coolify

# 2. Créer le fichier .env
cp .env.example .env
# Éditer .env et remplir DOMAIN, POSTHOG_SECRET, ENCRYPTION_SALT_KEYS

# 3. Télécharger les configs PostHog
bash setup.sh

# 4. Lancer la stack
docker compose up -d

# 5. Vérifier l'état
docker compose ps
docker compose logs -f web
```

---

## Mise à jour

```bash
# Mettre à jour les configs PostHog
bash setup.sh

# Tirer les nouvelles images et redémarrer
docker compose pull
docker compose up -d
```

Sur Coolify, redéployer simplement depuis l'interface (le pre-deploy command relancera `setup.sh`).

---

## Monitoring

```bash
# État de tous les conteneurs
docker compose ps

# Logs en temps réel
docker compose logs -f web worker

# Santé ClickHouse
docker compose exec clickhouse wget -qO- http://localhost:8123/ping

# Santé Kafka
docker compose exec kafka rpk topic list --brokers localhost:9092
```

---

## Dépannage courant

| Symptôme | Cause probable | Solution |
|---|---|---|
| `web` en boucle de redémarrage | Migrations en cours | Attendre 5 min, vérifier `docker compose logs worker` |
| `clickhouse` qui ne démarre pas | Configs manquantes | Vérifier que `./posthog/docker/clickhouse/` existe (relancer `setup.sh`) |
| Page blanche après connexion | `SITE_URL` incorrect | Vérifier que `DOMAIN` correspond exactement au domaine utilisé |
| Erreur CSRF | Proxy non déclaré | Vérifier `IS_BEHIND_PROXY=true` dans les env vars |

---

## Fichiers du repo

```
.
├── docker-compose.yml   — stack complète adaptée pour Coolify
├── setup.sh             — télécharge les configs PostHog depuis GitHub
├── .env.example         — template des variables d'environnement
└── README.md
```

Le répertoire `posthog/` (créé par `setup.sh`) contient les fichiers de configuration
ClickHouse, Postgres, livestream et les scripts IDL. Il est exclu du repo (`.gitignore`).

---

## Licence

Ce repo est sous licence MIT.  
PostHog est sous licence [MIT](https://github.com/PostHog/posthog/blob/master/LICENSE) pour la version open-source.
