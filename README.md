# Assignment 3 — CI/CD with GitHub Actions

A small Bash CLI (`app.sh`) with a local CI pipeline built on GitHub
Actions. The pipeline validates the code, runs the test suite, and
builds/smoke-tests a Docker image — all locally within GitHub-hosted
runners, with no cloud deployment.

## Contents

```
assignment-3/
├── README.md
├── app/
│   └── app.sh
├── scripts/
│   ├── lint.sh
│   └── build.sh
├── tests/
│   └── test.sh
├── .github/
│   └── workflows/
│       └── ci.yml
├── Dockerfile
├── compose.yaml
├── .dockerignore
└── grade.sh
```

## Requirements

- Bash 4+ on a Linux environment (or WSL/macOS).
- Docker Engine with the `docker compose` plugin, for the Docker
  build/smoke-test stage.
- A GitHub repository (public or private) to push to, so GitHub
  Actions can run the workflow.

## Installation / Setup

```bash
git clone <your-repository-url>
cd assignment-3
chmod +x app/*.sh scripts/*.sh tests/*.sh grade.sh
```

## Usage

### Application (`app/app.sh`)

```
app.sh system-info                 Display system information
app.sh check-host <host>           Resolve and check a host
app.sh check-port <host> <port>    Check TCP connectivity to a host:port
app.sh help                        Show usage help
```

Examples:

```bash
./app/app.sh system-info
./app/app.sh check-host example.com
./app/app.sh check-port example.com 443
```

Exit codes:

| Code | Meaning                          |
|------|-----------------------------------|
| 0    | Success                           |
| 1    | Operational/runtime failure       |
| 2    | Invalid command or invalid input  |

### Docker

```bash
docker build -t devops-tool .
docker run --rm devops-tool help
docker run --rm devops-tool system-info
```

Or with Compose:

```bash
docker compose run --rm devops-tool system-info
```

## Testing

Three scripts drive testing, matching the CI pipeline stages:

1. **`scripts/lint.sh`** — checks required files exist and runs
   `bash -n` against every script. Runs ShellCheck as an extra,
   non-blocking check if it's installed.

   ```bash
   ./scripts/lint.sh
   ```

2. **`tests/test.sh`** — 10 tests against `app/app.sh` directly (no
   Docker needed), covering: `help`, `system-info`, an invalid
   command, a missing command, `check-host` with a missing host,
   `check-host` with a valid host, `check-port` with a missing port,
   a non-numeric port, and out-of-range ports (`0` and `65536`).

   ```bash
   ./tests/test.sh
   ```

3. **`scripts/build.sh`** — builds the `devops-tool` image and runs
   Docker smoke tests (`help`, `system-info`, and an invalid command).

   ```bash
   ./scripts/build.sh
   ```

Run everything the instructor will run with:

```bash
./grade.sh
```

## GitHub Actions Pipeline

`.github/workflows/ci.yml` runs on every `push` and `pull_request` and
defines three jobs, chained with `needs:` so each only runs after the
previous one succeeds:

```
validate  →  test  →  docker
```

- **validate** — installs nothing extra; runs `scripts/lint.sh`.
- **test** — runs `tests/test.sh` (`needs: validate`).
- **docker** — runs `scripts/build.sh`, which builds the image and
  smoke-tests it (`needs: test`).

### CI failure demonstration

To demonstrate the pipeline catching a real failure:

1. A branch (e.g. `demo/ci-failure`) was created from `main`.
2. A deliberate fault was introduced — a Bash syntax error in
   `app/app.sh` (an unclosed `if` block) — and pushed.
3. The `validate` job failed on `bash -n`, which correctly blocked
   the `test` and `docker` jobs from running (they never started, per
   the `needs:` chain).
4. The syntax error was reverted/fixed in a follow-up commit and
   pushed to the same branch.
5. The workflow re-ran automatically and all three jobs
   (`validate` → `test` → `docker`) passed.
6. The branch was merged into `main` once CI was green.

You can see this history under the **Actions** tab of the GitHub
repository once pushed: one red run on the faulty commit, followed by
a green run once the fix landed.

## Assumptions

- The workflow triggers on `push` and `pull_request` with no branch
  filters, so it runs for every branch and every PR.
- `check-host` and `check-port` in `app.sh` are intentionally the same
  lightweight resolve/ping/TCP-check pattern used in the earlier
  assignments, scoped down to what this CLI's spec requires.
- `scripts/build.sh` uses the image name `devops-tool` by default
  (overridable via the `IMAGE_NAME` environment variable) so the CI
  job and local runs stay consistent.
- ShellCheck is treated as an optional, non-blocking check in
  `scripts/lint.sh` since it isn't guaranteed to be installed in every
  local environment; `bash -n` is the required, blocking syntax check.
- `.dockerignore` excludes `.git/`, `.github/`, logs, and the README
  to keep the Docker build context minimal.
