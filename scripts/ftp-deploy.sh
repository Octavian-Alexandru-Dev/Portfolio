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
CRED_FILE="$REPO_ROOT/.ftp-credentials"

if [ ! -f "$CRED_FILE" ]; then
  echo "FTP deploy: file .ftp-credentials non trovato in $REPO_ROOT, salto il deploy." >&2
  exit 0
fi

# shellcheck disable=SC1090
source "$CRED_FILE"
REMOTE_DIR="${FTP_REMOTE_DIR:-/}"

cd "$REPO_ROOT"

FAILED=0

upload() {
  local f="$1"
  echo "FTP deploy: carico $f"
  # TLS 1.2 forzato e -k: stesso ProFTPD di Tophost usato per menu-masseria,
  # interrompe i trasferimenti su TLS 1.3 e serve un certificato wildcard
  # condiviso non specifico per questo dominio (vedi menu-masseria per
  # riferimento allo stesso comportamento).
  if ! curl -sS --ssl-reqd -k --tlsv1.2 --tls-max 1.2 --ftp-create-dirs \
    -T "$f" "ftp://${FTP_HOST}${REMOTE_DIR}/$f" \
    --user "${FTP_USERNAME}:${FTP_PASSWORD}"; then
    echo "FTP deploy: upload di $f fallito (rete o server FTP non raggiungibili?)." >&2
    FAILED=1
  fi
}

# Solo i file effettivamente serviti dal sito: pagine statiche alla radice e
# l'intera cartella assets/. File di sviluppo (README, package.json,
# .gitignore, docs/, ecc.) restano fuori di proposito.
for f in index.html 404.html robots.txt; do
  [ -f "$f" ] && upload "$f"
done

while IFS= read -r -d '' f; do
  upload "${f#./}"
done < <(find assets -type f -print0 | sort -z)

if [ "$FAILED" = "1" ]; then
  echo "FTP deploy: uno o più file non sono stati caricati. Il push su git è comunque andato a buon fine: rilancia 'scripts/ftp-deploy.sh' da una rete che raggiunge la porta FTP (21) in uscita per completare la pubblicazione." >&2
  exit 0
fi

echo "FTP deploy: sito pubblicato su ${FTP_HOST}${REMOTE_DIR}."
