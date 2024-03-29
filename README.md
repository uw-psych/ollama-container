# ollama-container

This container provides a convenient way to run [ollama](https://github.com/ollama/ollama) on Hyak.

## Running ollama on Hyak in interactive mode 🍇

First, you'll need to log in to Hyak. If you've never set this up, go [here](https://uw-psych.github.io/compute_docs).

```bash
ssh your-uw-netid@klone.hyak.uw.edu # Replace `your-uw-netid` with your UW NetID
```

Then, you'll need to request a compute node. You can do this with the `salloc` command:

```bash
# Request a GPU node with 8 CPUs, 2 GPUs, 64GB of RAM, and 1 hour of runtime:
# (Note: you may need to change the account and partition)
salloc --account escience --partition gpu-a40 --mem 64G -c 8 --time 1:00:00 --gpus 2
```

One you're logged in to the compute node, you should set up your cache directories and Apptainer settings.

👉 *If you're following this tutorial, **you should do this every time you're running ollama on Hyak!** This is because the default settings for Apptainer will use your home directory for caching, which will quickly fill up your home directory and cause your jobs to fail. If you are aware of this and have already set `APPTAINER_CACHEDIR`, you can remove the line that sets `APPTAINER_CACHEDIR`.*

```bash
# Do this in every session where you're running ollama on Hyak!

# Set up cache directories:
export APPTAINER_CACHEDIR="/gscratch/scrubbed/${USER}/.cache/apptainer"
export OLLAMA_MODELS="/gscratch/scrubbed/${USER}/ollama/models"
mkdir -p "${APPTAINER_CACHEDIR}" "${OLLAMA_MODELS}"

# Set up Apptainer:
export APPTAINER_BIND=/gscratch APPTAINER_WRITABLE_TMPFS=1 APPTAINER_NV=1
```

Next, you'll have to start the ollama server. Before you do this, you'll need to find an open port to use. You can do this with the `random-port` command embedded in this container:

```bash
export OLLAMA_PORT=$(apptainer run oras://ghcr.io/uw-psych/ollama-container/ollama-container:latest random-port)

# Start the ollama server (make sure you include the `&` at the end to run it in the background):
apptainer run oras://ghcr.io/uw-psych/ollama-container/ollama-container:latest &

# Wait a few seconds for the server to start up:
sleep 5
```

Once the server is running, you can start an interactive prompt with the following command:

```bash
# Start an interactive prompt with the dolphin-phi model (1.6 GB):
apptainer run oras://ghcr.io/uw-psych/ollama-container/ollama-container:latest run dolphin-phi
```

For other models, you can replace `dolphin-phi` with the name of the model you want to use. You can find a list of available models [here](https://ollama.ai/library).

You can stop the server with the following command:

```bash
pkill -f "ollama serve"
```

See the [documentation](https://github.com/ollama/ollama) for more information on how to use ollama.
