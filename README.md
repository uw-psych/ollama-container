# ollama-container

This container provides a convenient way to run [ollama](https://github.com/ollama/ollama) on Hyak.

## Running ollama on Hyak in interactive mode 🍇

First, you'll need to log in to Hyak. If you've never set this up, go [here](https://uw-psych.github.io/compute_docs).

```bash
# Replace `your-uw-netid` with your UW NetID:
ssh your-uw-netid@klone.hyak.uw.edu
```

Then, you'll need to request a compute node. You can do this with the `salloc` command:

```bash
# Request a GPU node with 8 CPUs, 2 GPUs, 64GB of RAM, and 1 hour of runtime:
# (Note: you may need to change the account and partition)
salloc --account escience --partition gpu-a40 --mem 64G -c 2 --time 1:00:00 --gpus 1
```

### Building the container

Next, you'll need to build the container. In this example, we'll build the container in a directory in your scratch space. You can change the path to wherever you'd like to build the container.

```bash
mkdir -p "/gscratch/scrubbed/${USER}/ollama"
cd "/gscratch/scrubbed/${USER}/ollama"
git clone https://github.com/uw-psych/ollama-container
cd ollama-container
apptainer build ollama.sif Singularity
```

#### Specifying a different version of `ollama`

By default, the container will install the latest version of `ollama`. If you want to install a specific version, you can specify the version with the `OLLAMA_VERSION` build argument. The most recent version tested with this container is `0.5.8`.

### Starting the `ollama` server

The model files that `ollama` uses are stored by default in your home directory. As these files can be quite large, it's a good idea to store them somewhere else. In this example, we'll store them in your scratch space.

```bash
export OLLAMA_MODELS="/gscratch/scrubbed/${USER}/ollama/models"
mkdir -p "${OLLAMA_MODELS}"
```

You should run the command above every time you start a new server. If you want to run it automatically every time you log in, you can add it to your `.bashrc` file.

Next, you'll have to start the `ollama` server. You can set the port for the server with the `OLLAMA_PORT` environment variable or leave it unset to use a random port.

```bash
# Start the ollama server as an Apptainer instance named "ollama-$USER":
# --nv: Use the NVIDIA GPU
# --writable-tmpfs: Use a writable tmpfs for the cache directory
# --bind /gscratch: Bind /gscratch to the container
apptainer instance start --nv --writable-tmpfs --bind /gscratch ollama.sif ollama-$USER
```

### Running `ollama` commands

To run `ollama` commands, execute the `apptainer run` command with your instance as the first argument and the `ollama` command as the second argument.

For example, to get help with the `ollama` command, run:

```bash
apptainer run instance://ollama-$USER ollama help
```

You can start an interactive prompt with the following command:

```bash
apptainer run instance://ollama-$USER ollama run qwen:0.5b
```

Or provide the prompt on the command line and return JSON output non-interactively:

```bash
# NOTE: Not all models support JSON output
# NOTE: Wrap the prompt in single quotes to avoid issues with special characters
apptainer run instance://ollama-$USER ollama run qwen:0.5b --format=json --prompt 'Who are you?'
```

For other models, you can replace `qwen:0.5b` with the name of the model you want to use. You can find a list of available models [here](https://ollama.ai/library).

To show the models on the server, run:

```bash
apptainer run instance://ollama-$USER ollama list
```

To show the currently running models, run:

```bash
apptainer run instance://ollama-$USER ollama ps
```

To stop the server, run:

```bash
apptainer instance stop ollama-$USER
```

See the [documentation](https://github.com/ollama/ollama) for more information on how to use `ollama`.

#### Listing available models and tags

This repository includes a custom command to list available models and tags at (https://ollama.com/library). This command is not part of the `ollama` package and is only available in this container. It is useful for finding the names of models and tags to use with the `ollama` command, but it is not guaranteed to work in the future.

To list available models, try the following command with a running instance:

```bash
apptainer run instance://ollama-$USER available-models
```

To list available tags for a model, try:

```bash
# Replace `qwen` with the name of the model you want to check:
apptainer run instance://ollama-$USER available-tags qwen
```
