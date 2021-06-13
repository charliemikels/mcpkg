# MCPKG
A package manager for Minecraft mods

:warning: Right now, this is a **very** work in progress project and it is far from usable or stable. It will explode your computer. (It shouldn't, but please treat it like it might.)

![A screenshot of mcpkg being built and ran](README_assets/demo_screenshot.png "MCPKG screenshot")

## About
MCPKG is a **work in progress** tool to automatically download and update Minecraft mods.

I plan to support searching, downloading, and updating mods from [Modrinth](https://modrinth.com/), an open source collection of open source Minecraft mods. In the future, I'd also like to support from other mod platforms and Resource/Data pack management, but Modrinth is a first priority.

## Dependancies and running MCPKG
MCPKG is currently written in [V](https://github.com/vlang/v), but it currently doesn't need any extra dependencies.

After installing V, clone and enter this repo and type `v run .` to start mcpkg. If you want to build the project, it's simply `v .`.

V is also available in the [AUR](https://aur.archlinux.org/packages/vlang/).

## Using MCPKG
MCPKG is unfinished, so not all of these options are implemented

Planned usage cheat sheet:

| Option | Name | Description | Example |
| ------ | ---- | ----------- | ------- |
| `-h` | Help | Returns a simple help text similar to this table | `mcpkg -h` |
| `-s mod_name`   | Search | Searches for a mod of a given name. | `mcpkg -s sodium` |
| `-i mod_name`   | Install | Same as search, but after the mod is found it will try to download it. If it's already installed, it will ask if you want to update. | `mcpkg -s sodium` |
| `-v version_number`   | Version | Limits a search to a version of Minecraft. | `mcpkg -i sodium -v 1.16` |
| `-u mod_name`   | Update mod | Essentially the same as -i. If it's not already installed, it will ask if you want to install the mod. | `mcpkg -u sodium` |
| `-u` | Update All | Scans the list of installed mods and will try to find and install updates for them | `mcpkg -u` |
| `--mod_dir dir` | Specify Directory | This will redefine a mod installation directory to `dir` | `mcpkg -u --mod_dir ~/tekkit_mods` |

<!-- | `--source source_name` | Specify Source | Specifies a specific mod source (When supported) | `mcpkg -s sodium --source curseforge` | -->

If no options are given, MCPKG will run with `-u`. And if there's only a string, it will run `-u mod_name`
