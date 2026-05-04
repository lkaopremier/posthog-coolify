#!/usr/bin/env bash
# Télécharge les fichiers de configuration PostHog nécessaires depuis le repo officiel
# via un sparse-checkout (seuls les répertoires utiles sont récupérés).
# À exécuter une fois avant le premier `docker compose up`, ou en pre-deploy sur Coolify.

set -euo pipefail

TARGET_DIR="posthog"
POSTHOG_REPO="https://github.com/PostHog/posthog"
BRANCH="${POSTHOG_BRANCH:-master}"

echo "==> Configuration PostHog"

if [ -d "$TARGET_DIR/.git" ]; then
    echo "    Mise à jour des configs existantes..."
    cd "$TARGET_DIR"
    git fetch --depth=1 origin "$BRANCH"
    git reset --hard "origin/$BRANCH"
    cd ..
else
    if [ -e "$TARGET_DIR" ]; then
        echo "    Répertoire $TARGET_DIR existant sans .git détecté (artefact Docker) — nettoyage..."
        rm -rf "$TARGET_DIR"
    fi
    echo "    Sparse-clone du repo PostHog (configs uniquement)..."
    git clone \
        --filter=blob:none \
        --sparse \
        --depth=1 \
        --branch "$BRANCH" \
        "$POSTHOG_REPO" \
        "$TARGET_DIR"

    cd "$TARGET_DIR"
    git sparse-checkout set \
        docker/clickhouse \
        docker/livestream \
        docker/postgres-init-scripts \
        posthog/idl \
        posthog/user_scripts \
        dev-services.env
    cd ..
fi

echo "==> Prêt ! Lance maintenant : docker compose up -d"
