#!/usr/bin/env bash
# Carica il sito (file statici) su Tophost via FTPS.
# Richiede il file .ftp-credentials nella root del repo (mai committato, vedi
# .gitignore) con le variabili FTP_HOST, FTP_USERNAME, FTP_PASSWORD,
# FTP_REMOTE_DIR.
#
# Un fallimento di rete/FTP non fa fallire questo script (vedi `upload`):
# un deploy non riuscito non deve mai bloccare `git push` (che lo invoca
# dall'hook pre-push). Rilancia questo script a mano quando la rete lo
# consente per completare il deploy.
set -uo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"

# Se invocato tramite `bws run` (vedi .githooks/pre-push), FTP_HOST/
# FTP_USERNAME/FTP_PASSWORD sono già nell'ambiente: usale così come sono.
# Altrimenti, fallback al file locale .ftp-credentials.
if [ -z "${FTP_HOST:-}" ] || [ -z "${FTP_USERNAME:-}" ] || [ -z "${FTP_PASSWORD:-}" ]; then
  CRED_FILE="$REPO_ROOT/.ftp-credentials"
  if [ ! -f "$CRED_FILE" ]; then
    echo "FTP deploy: né Bitwarden Secrets Manager né .ftp-credentials sono disponibili, salto il deploy." >&2
    exit 0
  fi
  # shellcheck disable=SC1090
  source "$CRED_FILE"
fi
REMOTE_DIR="${FTP_REMOTE_DIR:-/}"

cd "$REPO_ROOT"

upload() {
  local f="$1"
  echo "FTP deploy: carico $f"
  # --connect-timeout: se la porta FTP (21) non è raggiungibile, fallisce in
  # pochi secondi invece di lasciare il TCP SYN ritentare per oltre un minuto.
  # TLS 1.2 forzato e -k: stesso ProFTPD di Tophost usato per menu-masseria,
  # interrompe i trasferimenti su TLS 1.3 e serve un certificato wildcard
  # condiviso non specifico per questo dominio (vedi menu-masseria per
  # riferimento allo stesso comportamento).
  curl -sS --connect-timeout 10 --ssl-reqd -k --tlsv1.2 --tls-max 1.2 --ftp-create-dirs \
    -T "$f" "ftp://${FTP_HOST}${REMOTE_DIR}/$f" \
    --user "${FTP_USERNAME}:${FTP_PASSWORD}"
}

# Solo i file effettivamente serviti dal sito: pagine statiche alla radice e
# l'intera cartella assets/. File di sviluppo (README, package.json,
# .gitignore, docs/, ecc.) restano fuori di proposito.
FILES=(index.html 404.html robots.txt)
while IFS= read -r -d '' f; do
  FILES+=("${f#./}")
done < <(find assets -type f -print0 | sort -z)

FAILED=0
FIRST=1
for f in "${FILES[@]}"; do
  [ -f "$f" ] || continue

  if ! upload "$f"; then
    echo "FTP deploy: upload di $f fallito." >&2
    if [ "$FIRST" = "1" ]; then
      # Il primo file è anche il test di raggiungibilità: se fallisce, il
      # server/la rete non sono raggiungibili e ritentare per ogni altro
      # file darebbe solo lo stesso esito, sprecando tempo. Ci si ferma qui.
      echo "FTP deploy: server FTP non raggiungibile, interrompo qui invece di ritentare per ogni file. Il push su git è comunque andato a buon fine: rilancia 'scripts/ftp-deploy.sh' da una rete che raggiunge la porta FTP (21) in uscita per completare la pubblicazione." >&2
      exit 0
    fi
    FAILED=1
  fi
  FIRST=0
done

if [ "$FAILED" = "1" ]; then
  echo "FTP deploy: alcuni file non sono stati caricati. Rilancia 'scripts/ftp-deploy.sh' per ritentare." >&2
  exit 0
fi

echo "FTP deploy: sito pubblicato su ${FTP_HOST}${REMOTE_DIR}."
