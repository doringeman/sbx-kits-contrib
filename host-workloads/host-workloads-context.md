## Windows host commands

You can run commands natively on the user's Windows computer with `sbx-host`:

```sh
sbx-host [-C dir] command [args...]
```

`-C dir` sets the working directory, relative to the workspace root; without it, the run uses your current directory in the workspace. The workspace is shared: files you write here are visible to the host run, and its writes are visible here.

Use it for work that needs Windows itself: building or testing for Windows with `dotnet` or MSBuild, PowerShell scripts, `.cmd` and `.bat` files, Windows-only tools, or checking that something works on Windows. Do everything else in this sandbox.

The user approves each run, or every run of this sandbox at once until the sandbox restarts or a kit is added. Ask for few runs: put several steps in one script in the workspace and run that.

What a run can do:

- It writes only the workspace and a private home on the host, which is kept between runs. It reads what Windows lets any app container read, such as system and program files, but not the user's documents.
- It reaches the network only through this sandbox's network policy.
- It may use the user's desktop, including the clipboard.

How commands are found:

- A bare name, such as `dotnet` or `powershell`, is looked up on the host's PATH, never in the workspace.
- Run a workspace script by its path: `sbx-host ./build.cmd`.
- `.com` programs, such as `tree`, run only through `cmd.exe`: `sbx-host cmd /c tree`.
- Arguments to a batch file cannot contain `" % ! ^ & | < >`; pass such values in a file instead.

Git Bash and other MSYS2 programs do not start in a host run, so Git hooks, Git LFS and ssh remotes fail there. Do Git work in this sandbox.

Output streams back as it is produced, with stderr merged into stdout. Input is not forwarded. `sbx-host` exits with the command's own exit code, or 125 when the command did not run: the run was refused, denied or not available, and the reason is on stderr. If `sbx-host` reports that host commands are off or not available, tell the user rather than retrying.
