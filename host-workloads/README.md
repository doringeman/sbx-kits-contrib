> [!NOTE]
> <strong>Experimental: Sandbox Kit v3</strong>
>
> This kit uses the experimental [Sandbox Kit specification](https://github.com/docker/sandbox-kit-spec), specifically [v3](https://github.com/docker/sandbox-kit-spec/blob/main/docs/spec/SPEC-v3.md). The format and runtime behavior may change before v3 is stable.

# Windows host workloads

A mixin that lets a sandbox's agent run approved commands natively on the
Windows host with `sbx-host`, for work that needs Windows itself: `dotnet` and
MSBuild, PowerShell, batch files and Windows-only tools. It composes with any
agent.

Each run is a native container that can write only the workspace and a private
host home, and reaches the network only through the sandbox's network policy.
The user approves every run, or every run of the sandbox at once.

## What a run can do

- Write the workspace and a private host home, kept between runs, and nothing
  else.
- Read what Windows lets any app container read, such as system and program
  files, and the host's toolchains: the folders on the host's PATH, those named
  by toolchain variables such as `JAVA_HOME`, `GOROOT`, `DOTNET_ROOT` or
  `NVM_HOME`, and rustup's home. Every file inside such a folder is readable.
  Drive roots, whole user profiles, sbx's own folders and known credential
  locations are never granted, and nothing else of the user's is readable
  unless a PATH entry points there.
- List the names and read the attributes of files and folders anywhere on the
  host's fixed drives, where the host's Windows supports it, without reading
  their contents. Node, npm and Go need this to resolve paths.
- Reach the network only through the sandbox's network policy.
- Use the user's desktop, including the clipboard.

The approval prompt says the same before each run.

## Requirements

- Docker Sandboxes on Windows x64, with host workloads available, using the
  default sandbox backend. The experimental Runtime backend refuses this kit.
- Host workloads turned on, on the host:

  ```console
  sbx settings set platform.allowExperimentalFeatures true
  sbx settings set feature.host-workloads true
  ```

Without them, the kit still composes, and `sbx-host` reports why host commands
are not available.

## Usage

Run it with any agent kit or built-in agent, from its published OCI artifact on
Docker Hub:

```console
sbx run --kit "docker.io/sbx/host-workloads:latest" claude
```

Or from a git URL targeting this repo:

```console
sbx run --kit "git+https://github.com/docker/sbx-kits-contrib.git#dir=host-workloads" claude
```

For local development, point `--kit` at this directory:

```console
sbx run --kit ./host-workloads/ claude
```

To give an existing sandbox host runs, add the kit to it. Its container is
replaced, so the user approves runs again:

```console
sbx kit add my-sandbox "docker.io/sbx/host-workloads:latest"
```

Then, in the sandbox:

```console
sbx-host dotnet --info
sbx-host -C src powershell -NonInteractive -File build.ps1
sbx-host --timeout 10m dotnet test
```

`sbx-host --help` lists the options and exit statuses.

## What the kit declares

- `com.docker.sandbox/api@1` with `operation: host-workloads.run` grants this
  sandbox host runs. sbx refuses them to sandboxes without the grant, and the
  grant cannot waive the user's approval: the operation accepts only
  `approval: required`.
- `com.docker.sandbox/agent-context@1` tells the agent when and how to use
  `sbx-host`, and what a run can reach.
- `/usr/local/bin/sbx-host` is a launcher for the client the sandbox's daemon
  serves.

## How the launcher works

The overlay is one shell script. It fetches the `sbx-host` client from the
sandbox's gateway at each run and executes it, so the client always speaks the
protocol of the daemon it talks to, and the kit needs no update when that
protocol changes. Where the daemon does not serve the client, the launcher says
so and exits 126, as the client does when host commands are not available; when
it cannot reach the gateway, it exits 125.

The kit declares no network policy: the launcher reaches only the sandbox's own
gateway, and host runs reach the network through the sandbox's existing policy.
It uses only `sh` and `curl`, which every base provides.
