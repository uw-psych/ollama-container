#!/usr/bin/env bash
set -o pipefail
OLLAMA_LIBRARY_URL="${OLLAMA_LIBRARY_URL:-https://ollama.com/library}"

action="${1:-models}"

case "${action}" in
	models)
		shift
		curl -sL "${OLLAMA_LIBRARY_URL}" | grep -oP 'href="/library/\K[^"]+' || { echo "No models found at ${OLLAMA_LIBRARY_URL}" >&2; exit 2; }
		;;
	tags)
		shift
		if [[ -z "${1:-}" ]]; then
			echo "No model name provided. Exiting." >&2
			exit 2
		fi
		curl -sL "${OLLAMA_LIBRARY_URL}/$1/tags" | grep -o "$1:[^\" ]*q[^\" ]*" | grep -E -v 'text|base|fp|q[45]_[01]' || { echo "No model tags found at ${OLLAMA_LIBRARY_URL}/$1/tags" >&2; exit 2; }

		;;
	*)
		printf "Unknown action: \"%s\"\n" "${action}" >&2
		exit 2
		;;
esac




