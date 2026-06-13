# my_module — environment module system for bash/zsh

A lightweight module system that manages environment variables (PATH, library paths, include paths) when loading/unloading software modules. Works in both **bash** and **zsh**.

I have been using the old my_module.bak for many years since I wrote it in 2013 when I started my grad school in Princeton astro (I really needed this on my office desktop due to their security policies). The new my_module is the updated version using OpenCode + GLM 5.1. 

## Quick start

```bash
source /path/to/my_module

# Install a module from a directory
module install myapp /opt/myapp

# Load it into your environment
module load myapp

# See what's loaded
module list

# Unload it
module unload myapp

# Swap one module for another
module swap oldapp newapp
```

## Installation

Source the script in your shell init:

```bash
# ~/.bashrc or ~/.zshrc
source /home/lilew/bin/my_module
```

The module database directory defaults to `~/.module` — override with `MODULE_DB_DIR`.

## Commands

| Command | Usage | Description |
|---|---|---|
| `install` | `module install <name> [path]` | Register a module from a directory (defaults to `$PWD`). Scans for `bin/`, `sbin/`, `include/`, `lib/`, `lib64/`, `pkgconfig/` subdirectories. |
| `load` | `module load <name>` | Add module paths to environment variables |
| `unload` | `module unload <name>` | Remove module paths from environment variables |
| `swap` | `module swap <old> <new>` | Unload old module, load new module |
| `list` | `module list` | Show currently loaded modules |
| `avail` | `module avail` | List available modules in the database |
| `remove` | `module remove <name>` | Delete a module from the database |
| `help` | `module help` | Show usage information |

## How it works

Each module is a text file in the database directory. Each line sets a variable:

```
PATH=/opt/myapp/bin
PATH=/opt/myapp/sbin
LD_LIBRARY_PATH=/opt/myapp/lib
```

When loading, paths are prepended to the current environment variable. When unloading, the exact paths are removed. Multiple lines for the same variable are accumulated correctly — the key fix in this version.

## Auto-detected subdirectories

`module install` scans for these subdirectories and creates entries automatically:

| Subdirectory | Variable |
|---|---|
| `bin/`, `sbin/` | `PATH` |
| `include/` | `C_INCLUDE_PATH`, `CPLUS_INCLUDE_PATH` |
| `lib/`, `lib64/` | `LIBRARY_PATH`, `LD_LIBRARY_PATH`, `DYLD_LIBRARY_PATH` |
| `pkgconfig/` | `PKG_CONFIG_PATH` |

## Shell compatibility notes

- **zsh**: use `source my_module` (not `zsh my_module`). Setting `MODULE_DB_DIR=val` as a temp env var before `source` does NOT persist — assign it on a separate line instead.
- **bash**: works with both `source` and direct execution with args.
- **eval-free**: no `eval` in the public API. The accumulated-output fix uses `eval` internally but only on controlled variable names.

## The old version
You will have to type
```bash
source my_module.bak <module_name>
```
to load a module, or put
```bash
alias my_module='source my_module.bak'
```
into the .bashrc/.zshrc files so that you don't have to explicitly "source" every single time.
