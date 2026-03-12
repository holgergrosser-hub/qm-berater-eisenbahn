#!/bin/bash
set -e

# ============================================================
# DEPLOYMENT-SKRIPT: QMBerater Eisenbahn-Personaldienstleister
# Erstellt: 2026-03-12
# Subdomain: qm-berater-eisenbahn.qmberater.info
# ============================================================

BRANCHE="eisenbahn"
MARKE="qmberater"
REPO_NAME="qmberater-eisenbahn"
SUBDOMAIN="qm-berater-eisenbahn"
DOMAIN="qmberater.info"
FULL_DOMAIN="${SUBDOMAIN}.${DOMAIN}"
NETLIFY_SUBDOMAIN="${REPO_NAME}.netlify.app"

GITHUB_USER="${GITHUB_USER:-dein-github-user}"
CF_TOKEN="${CLOUDFLARE_API_TOKEN}"
ZONE_QMBERATER="${CF_ZONE_QMBERATER}"

echo "🚂 Deployment: ${FULL_DOMAIN}"
echo "=========================================="

# PHASE 2: GitHub
echo "[1/4] GitHub Repository erstellen..."
git init
git add .
git commit -m "Initial: Landingpage ISO Eisenbahnpersonal für QMBerater"
gh repo create "${REPO_NAME}" --public --source=. --remote=origin --push 2>/dev/null || {
  echo "  ⚠️  Repo existiert bereits, pushe Updates..."
  git remote set-url origin "https://github.com/${GITHUB_USER}/${REPO_NAME}.git" 2>/dev/null || true
  git push -u origin main --force
}
echo "  ✅ GitHub: https://github.com/${GITHUB_USER}/${REPO_NAME}"

# PHASE 3: Netlify
echo "[2/4] Netlify deployen..."
npm install && npm run build
netlify deploy --prod --dir=dist 2>/dev/null || netlify init
echo "  ✅ Netlify: https://${NETLIFY_SUBDOMAIN}"

# PHASE 4: Cloudflare DNS
echo "[3/4] Cloudflare CNAME erstellen..."
CF_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${ZONE_QMBERATER}/dns_records" \
  -H "Authorization: Bearer ${CF_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"type\": \"CNAME\",
    \"name\": \"${SUBDOMAIN}\",
    \"content\": \"${NETLIFY_SUBDOMAIN}\",
    \"proxied\": false,
    \"ttl\": 1,
    \"comment\": \"Landingpage ISO Eisenbahn - QMBerater\"
  }")

if echo "$CF_RESPONSE" | grep -q '"success":true'; then
  echo "  ✅ DNS: ${FULL_DOMAIN} → ${NETLIFY_SUBDOMAIN}"
else
  echo "  ⚠️  DNS: $(echo $CF_RESPONSE | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("errors","Fehler"))' 2>/dev/null)"
fi

echo "[4/4] Custom Domain in Netlify hinzufügen..."
echo "  ⚠️  MANUELL: Netlify Dashboard → Domain management → Add domain: ${FULL_DOMAIN}"

echo ""
echo "=========================================="
echo "🎉 Deployment abgeschlossen!"
echo ""
echo "📋 NÄCHSTE SCHRITTE:"
echo "  1. Netlify: Custom Domain hinzufügen: ${FULL_DOMAIN}"
echo "  2. Cloudflare: SSL-Modus auf 'Full' setzen (NICHT Full strict)"
echo "  3. Cloudflare: CNAME-Proxy auf 'DNS only' (graue Wolke)"
echo "  4. SSL-Zertifikat abwarten (5-30 Min)"
echo "  5. Google Search Console: https://${FULL_DOMAIN}/sitemap.xml einreichen"
echo ""
echo "  🌐 Live unter: https://${FULL_DOMAIN}"
