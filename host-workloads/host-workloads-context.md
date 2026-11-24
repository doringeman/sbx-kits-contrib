## Windows host commands

You can run commands natively on the user's Windows computer with `sbx-host`:

```sh
sbx-host [-C dir] [--timeout duration] command [args...]
```

`-C dir` sets the working directory, relative to the workspace root; without it, the run uses your current directory, which must be inside the workspace. The workspace is shared: files you write here are visible to the host run, and its writes are visible here. `sbx-host --help` prints the full usage.

Use it for work that needs Windows itself: building or testing for Windows with `dotnet` or MSBuild, PowerShell scripts, `.cmd` and `.bat` files, Windows-only tools, or checking that something works on Windows. Do everything else in this sandbox.

The user approves each run, or every run of this sandbox at once until the sandbox restarts or a kit is added. A run waits up to 5 minutes for that approval. Ask for few runs: put several steps in one script in the workspace and run that.

What a run can do:

- It writes only the workspace and a private home on the host, which is kept between runs.
- It reads what Windows lets any app container read, such as system and program files, and the toolchains the host has: the folders on its PATH, those in toolchain variables such as `JAVA_HOME`, `GOROOT` or `NVM_HOME`, and rustup's home. It reads nothing else of the user's, such as their documents, unless a PATH entry points there.
- Where the host supports it, it can list the names and read the attributes of files and folders anywhere on the host's fixed drives, but not read their contents.
- It reaches the network only through this sandbox's network policy.
- It may use the user's desktop, including the clipboard.

How commands are found:

- A bare name, such as `dotnet` or `powershell`, is looked up on the host's PATH, never in the workspace.
- Run a workspace script by its path: `sbx-host ./build.cmd`.
- `.com` programs, such as `tree`, run only through `cmd.exe`: `sbx-host cmd /c tree`.
- Arguments to a batch file cannot contain `" % ! ^ & | < >`; pass such values in a file instead.

Git Bash and other MSYS2 programs do not start in a host run, so Git hooks, Git LFS and ssh remotes fail there. Do Git work in this sandbox.

How a run behaves:

- The command's stdout and stderr arrive on `sbx-host`'s stdout and stderr as they are produced.
- There is no stdin or terminal. A command that waits for input, or on a dialog on the user's desktop, waits until `--timeout` stops it or `sbx-host` is stopped. Pass non-interactive options, such as PowerShell's `-NonInteractive`, and give a command that might wait or run long a `--timeout`, such as `--timeout 10m`. Time spent waiting for approval does not count.
- Stopping `sbx-host`, as with Ctrl-C or a kill, stops the command.

`sbx-host` exits with the command's own exit code, or with one of these and a line starting `sbx-host:` on stderr that says why:

- 124: the command ran longer than `--timeout` and was stopped.
- 125: sbx could not run the command, or `sbx-host` could not write its output.
- 126: the run was refused before it started: host commands are off or not available, the user denied the run or did not answer in time, or the directory, an option or an argument was bad.
- 127: the command is not on the host's PATH.
- 1: the command's own code was outside 0-255, such as a Windows crash status; the line prints it.

If host commands are off or not available, or the user denied the run, tell the user rather than retrying.
