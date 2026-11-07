# ML Notebook Environment

A personal, containerized Jupyter environment for machine learning experimentation, numerical computing, data analysis, and model development.

The goal is to maintain a reproducible ML development environment without installing and managing multiple Python frameworks directly on the host.

## Features

- JupyterLab for interactive Python development
- Docker Compose for container management
- Support for PyTorch, TensorFlow, Keras, and JAX
- Persistent notebooks and project files through a host bind mount
- Configurable workspace directory using an environment variable
- Local browser access without repeated authentication
- Separation of the Python runtime from host dependencies

## Prerequisites

- Docker Engine or Docker Desktop
- Docker Compose v2
- Git
- A modern web browser

## Quick Start

From this repository's directory, create your local configuration:

```bash
cp .env.example .env
id -u
id -g
```

Edit `.env` for your host **before starting the container**. Set `NB_UID` and
`NB_GID` to the values printed above. A typical macOS account uses UID `501`
and GID `20`; Linux accounts commonly use `1000` for both, but check your own
account. Compose defaults to `1000:1000` when these variables are unset or empty.
The local `.env` is ignored by Git; `.env.example` is the shared template.

Set `NOTEBOOK_DIR` to an existing, writable **absolute host path**, such as
`/Users/yourname/wrk` on macOS or `/home/yourname/wrk` on Linux. Create the
directory as your host user if necessary. Without a value, Compose uses
`${HOME}/wrk`. Exported shell variables take precedence over `.env`.

Start and inspect the environment:

```bash
docker compose up -d
docker compose ps
docker compose logs --tail=50
```

Open **http://localhost:8888**. To stop and remove the container:

```bash
docker compose down
```

Your notebooks and projects remain in the host directory, bind-mounted read/write
at `/home/jovyan/work`.

## User identity and workspace permissions

Matching the notebook user's numeric UID/GID to the host user helps avoid
permission errors and files owned by an unexpected user, especially on Linux.
The existing Jupyter Docker Stacks base image supports `NB_UID` and `NB_GID`
through its [startup scripts](https://jupyter-docker-stacks.readthedocs.io/en/latest/using/common.html).
Compose starts as `root` so those scripts can update `jovyan`, then they drop
privileges before launching Jupyter. Setting environment variables alone would
not change the runtime user. `CHOWN_HOME=yes` adjusts the home directory itself;
we do not recursively change ownership of your mounted projects.

After startup, open a **JupyterLab terminal** and run:

```bash
id -u
id -g
python - <<'PYTHON'
from pathlib import Path
from tempfile import TemporaryDirectory
with TemporaryDirectory(prefix=".jupyter-write-check-", dir="/home/jovyan/work") as d:
    p = Path(d) / "check.txt"
    p.write_text("workspace read/write OK\n")
    print(p.read_text(), end="")
PYTHON
```

The IDs should match `.env`; the temporary read/write check cleans up after
itself. Use the JupyterLab terminal to test the effective notebook user:
plain `docker compose exec jupyter id` may report root because Compose's
configured startup user is root.

Docker Desktop on macOS shares files through a Linux VM, so host ownership and
ACL behavior can differ from native Linux even with matching IDs. Ensure
Docker Desktop allows sharing `NOTEBOOK_DIR` (Settings → Resources → File sharing,
where available), macOS grants Docker access to that folder, and your host user
can write there. UID/GID mapping cannot override host ACLs, privacy restrictions,
or a read-only share. On Linux, existing files must allow the chosen user or
group to write; correct permissions on the specific project rather than broadly
changing ownership of the entire workspace.

## Machine Learning Frameworks

The environment is intended to support multiple Python ML frameworks.

| Framework | Primary Use |
|---|---|
| PyTorch | Deep learning, research, model development |
| TensorFlow | Deep learning, model training and deployment |
| Keras | High-level neural network API |
| JAX | Accelerated numerical computing and automatic differentiation |
| NumPy | Numerical computing |
| Pandas | Data analysis |
| SciPy | Scientific computing |
| Matplotlib | Visualization |
| scikit-learn | Classical machine learning |

The SciPy notebook base supplies the scientific Python tools; the Dockerfile adds
PyTorch, TensorFlow, JAX, and Keras. Keras defaults to its TensorFlow backend.
After building and starting, verify imports in a notebook or JupyterLab terminal:

```bash
python -c "import torch, tensorflow, jax, keras; print(torch.__version__, tensorflow.__version__, jax.__version__, keras.__version__)"
```

### Framework Selection

PyTorch, TensorFlow, and JAX are Python libraries rather than separate Jupyter servers.

Within a notebook, select the appropriate library:

**PyTorch**

```python
import torch

print(torch.__version__)
print(torch.cuda.is_available())
```

**TensorFlow**

```python
import tensorflow as tf

print(tf.__version__)
print(tf.config.list_physical_devices())
```

**JAX**

```python
import jax
import jax.numpy as jnp

print(jax.__version__)
print(jax.devices())
```

**Keras**

```python
import keras

print(keras.__version__)
print(keras.backend.backend())
```

Keras can use different computational backends. Configure `KERAS_BACKEND` before importing Keras.

## Working with Git Repositories

Notebooks can be maintained in independent Git repositories under the mounted workspace.

Example host directory structure:

```text
~/wrk/
├── ml-experiments/
│   ├── notebooks/
│   ├── data/
│   └── README.md
├── neural-networks/
│   └── training.ipynb
└── numerical-analysis/
    └── optimization.ipynb
```

Changes made within JupyterLab are written directly to the corresponding host files.

Git operations can be performed from the host or from a properly configured container environment.

## Container Management

Start:

```bash
docker compose up -d
```

View logs:

```bash
docker compose logs -f
```

Restart:

```bash
docker compose restart
```

Stop:

```bash
docker compose down
```

Rebuild after changing Dockerfile dependencies (when you want to replace the running environment):

```bash
docker compose build --pull
docker compose up -d
```

## Security

JupyterLab is intended for local, trusted development.

Authentication is disabled by the existing empty token/password settings, and
Compose publishes port 8888 exclusively on `127.0.0.1`. Keep these settings paired.

Do not expose an unauthenticated Jupyter server to public networks.

## Notes on Hardware Acceleration

GPU acceleration depends on the host platform and compatible container runtime.
Docker Desktop on macOS does not expose Apple Metal GPUs to these Linux containers;
expect CPU execution here.

## Repository hygiene

Notebooks, source, dependency manifests, and configuration templates remain
trackable. Local settings, caches, large datasets, model weights, and generated
training outputs are ignored. Small intentional test fixtures can live under
`tests/fixtures/`, which is exempted from these ignore rules; never put secrets there.
