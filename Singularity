Bootstrap: docker
From: ollama/ollama:{{ OLLAMA_TAG }}

%arguments
	OLLAMA_TAG=0.5.8

%setup
	[ -n "${APPTAINER_ROOTFS:-}" ] && ./.build-scripts/write-apptainer-labels.sh >"${APPTAINER_ROOTFS}/.build_labels"

%files
	ollama_available_models.sh /usr/local/bin/ollama-available-models

%post
	set -ex
	export DEBIAN_FRONTEND=noninteractive
	apt-get update -yq
	apt-get install -yq curl
	apt-get clean -yq
	rm -rf /var/lib/apt/lists/*

%test
	ollama --help

%runscript
	set -e
	get_random_port() {
		bash -c 'set -e; read LOWERPORT UPPERPORT < /proc/sys/net/ipv4/ip_local_port_range; PORTRANGE=$(( UPPERPORT - LOWERPORT )); while :; do PORT=$(( LOWERPORT + ( RANDOM % PORTRANGE) )); (echo -n > /dev/tcp/127.0.0/${PORT}) &>/dev/null || echo "${PORT}" && exit 0; done; exit 1' || {
			echo "Failed to find an open port. Exiting." >&2
			exit 1
		}
	}
	
	if [ "${1:-}" = "random-port" ]; then
		get_random_port
		exit $?
	fi
	
	# Set up OLLAMA_HOST if OLLAMA_PORT is set:
	export OLLAMA_HOST="${OLLAMA_HOST:-127.0.0.1${OLLAMA_PORT:+:${OLLAMA_PORT}}}"
	
	# If we're runninng on klone, we should have access to /gscratch/scrubbed.
	# However, by default, /gscratch is not mounted in the container, whereas /mmfs1 is.
	# /gscratch is the same as /mmfs1/gscratch, so we can use /mmfs1/gscratch/scrubbed.
	if [ -d "/gscratch/scrubbed" ]; then
		SCRUBBED_DIR="/gscratch/scrubbed/${USER}"
	elif [ -d "/mmfs1/gscratch/scrubbed" ]; then
		SCRUBBED_DIR="/mmfs1/gscratch/scrubbed/${USER}"
		case "${OLLAMA_MODELS:-}" in
		/gscratch/*)
			OLLAMA_MODELS="${OLLAMA_MODELS#/gscratch/}"
			OLLAMA_MODELS="/mmfs1/gscratch/${OLLAMA_MODELS}"
			;;
		*) ;;
		esac
	fi
	[ -n "${SCRUBBED_DIR:-}" ] && OLLAMA_MODELS="${OLLAMA_MODELS:-${SCRUBBED_DIR}/ollama/models}"
	[ -n "${OLLAMA_MODELS:-}" ] && export OLLAMA_MODELS
	
	# If no arguments are given, default to running `ollama serve`:
	[ $# -eq 0 ] && set -- serve
	
	# If the first argument is "serve",
	# 	1. create the models directory if it doesn't exist
	# 	2. write a descriptive message to stderr
	if [ "${1:-}" = "serve" ]; then
		if [ -z "${OLLAMA_PORT:-}" ]; then
			echo "OLLAMA_PORT not set. Finding a random port to use" >&2
			OLLAMA_PORT="$(get_random_port)"
			if [ $? -ne 0 ]; then
				echo "Failed to get random port. Exiting." >&2
				exit 2
			fi
		fi
	
		if [ -n "${OLLAMA_MODELS:-}" ]; then
			mkdir -p "${OLLAMA_MODELS}" || {
				echo "Failed to create the OLLAMA_MODELS=\"${OLLAMA_MODELS}\" directory. Exiting." >&2
				exit 1
			}
		fi
		echo "Starting ollama server${OLLAMA_HOST:+ on ${OLLAMA_HOST}}${OLLAMA_MODELS:+ with models in ${OLLAMA_MODELS}}." >&2
	fi
	
	if [ "${1:-}" = "available" ]; then
		if ollama available 2>&1 | grep -qE 'Error:.*unknown command'; then
			shift
			ollama-available-models "$@"
			exit $?
		fi
	fi
	# Run the ollama command with the given arguments:
	ollama "$@"

%startscript
	/.run serve "$@"

%help
	This is a simple container for running Ollama. For more information, visit https://ollama.ai.

