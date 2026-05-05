#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEED_FILE="SEMENTE_SUPRALEGAL.md"
SEED_HASH_FILE="SEMENTE_SUPRALEGAL.sha256"
HASHES_FILE="HASHES.md"
JSON_OUTPUT=0

REQUIRED_DOCS=(
  README.md Manifest.md preambulo.md Md.md Mp0001.md License.md
  LEGAL_BASIS.md SUMULAS_E_JURISPRUDENCIA.md COPYRIGHT.md NOTICE.md
  AUTHORS.md GOVERNANCE.md CHILD_DATA_PROTECTION.md LIMITS_AND_DISCLAIMER.md CONTRIBUTING.md
)

ACTIONS=()

log(){ printf '%s\n' "$*"; }
err(){ printf '[ERRO] %s\n' "$*" >&2; }

usage(){
  cat <<USAGE
Uso: ./HAJA.SH [--check] [--generate] [--hash] [--verify] [--json]
  --check     valida documentos obrigatórios
  --generate  regenera ${SEED_FILE}
  --hash      atualiza ${SEED_HASH_FILE} e ${HASHES_FILE}
  --verify    verifica hashes esperados
  --json      saída em JSON simples
USAGE
}

validate_docs(){
  local missing=0
  for file in "${REQUIRED_DOCS[@]}"; do
    if [[ -f "$file" ]]; then
      log "[OK] Documento localizado: $file"
    else
      err "Documento obrigatório ausente: $file"
      missing=1
    fi
  done
  [[ $missing -eq 0 ]]
}

generate_seed(){
  local generated_at
  generated_at="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  cat > "$SEED_FILE" <<SEED
# Carta-Semente Supra Legal do Orquestrador Jurídico HAJA

**Data de emissão (UTC):** ${generated_at}

## Cláusulas-base
1. Dignidade humana.
2. Proteção integral de crianças e adolescentes.
3. Devido processo, contraditório e ampla defesa.
4. Legalidade, publicidade e auditabilidade.
5. Rastreabilidade técnica por hash e logs UTC.

## Nota de escopo
Documento declaratório, técnico e acadêmico. Não implica reconhecimento estatal automático nem soberania jurídica real.
SEED
  log "[OK] Arquivo regenerado: $SEED_FILE"
}

generate_hashes(){
  sha256sum "$SEED_FILE" > "$SEED_HASH_FILE"
  {
    echo "# HASHES"
    echo
    echo "Gerado em UTC: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    echo
    for f in README.md Manifest.md preambulo.md Md.md Mp0001.md License.md \
      LEGAL_BASIS.md SUMULAS_E_JURISPRUDENCIA.md COPYRIGHT.md NOTICE.md AUTHORS.md \
      GOVERNANCE.md CHILD_DATA_PROTECTION.md LIMITS_AND_DISCLAIMER.md CONTRIBUTING.md \
      "$SEED_FILE"; do
      [[ -f "$f" ]] && sha256sum "$f"
    done
  } > "$HASHES_FILE"
  log "[OK] Hashes atualizados: $SEED_HASH_FILE e $HASHES_FILE"
}

verify_hashes(){
  [[ -f "$SEED_HASH_FILE" ]] || { err "Arquivo ausente: $SEED_HASH_FILE"; return 1; }
  sha256sum -c "$SEED_HASH_FILE"
  log "[OK] Verificação concluída com sucesso"
}

emit_json(){
  printf '{"status":"ok","actions":"%s"}\n' "$(printf '%s,' "${ACTIONS[@]}" | sed 's/,$//')"
}

parse_args(){
  if [[ $# -eq 0 ]]; then
    ACTIONS=(check generate hash)
    return
  fi
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --check) ACTIONS+=(check) ;;
      --generate) ACTIONS+=(generate) ;;
      --hash) ACTIONS+=(hash) ;;
      --verify) ACTIONS+=(verify) ;;
      --json) JSON_OUTPUT=1 ;;
      -h|--help) usage; exit 0 ;;
      *) err "Opção inválida: $1"; usage; exit 2 ;;
    esac
    shift
  done
}

main(){
  cd "$ROOT_DIR"
  parse_args "$@"
  local failed=0
  for action in "${ACTIONS[@]}"; do
    case "$action" in
      check) validate_docs || failed=1 ;;
      generate) generate_seed ;;
      hash) generate_hashes ;;
      verify) verify_hashes || failed=1 ;;
    esac
  done
  if [[ $JSON_OUTPUT -eq 1 ]]; then emit_json; fi
  [[ $failed -eq 0 ]] || exit 1
}

main "$@"
