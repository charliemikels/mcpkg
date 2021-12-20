
# MCPKG
A tool to install and update Minecraft mods written in V.

> :warning: Right now, this is a **very** work-in-progress project, and it is not ready for real usage.

```V
fn main() {
	mut api := mcpkg.new_api()
	api.initialize()

	demo_mods := api.search_for_mods(mcpkg.SearchFilter{
		game_versions:['1.17.1'],
		query:'sodium',
		platform_name:'modrinth'
	})

	if demo_mods.len > 0 {
		demo_mod := demo_mods[0]
		api.install_mod(demo_mod)
	}
```

## About
MCPKG is an tool to install and update Minecraft mods with only a few commands. This version of MCPKG is just a V module to build other tools. In the future, a cli wrapper will be available.

The primary mod platform that I'll support for 1.0 will be [Modrinth](https://modrinth.com/), a collection of open source Minecraft mods. However, I plan to code flexibly enough so that new sources could be added in the future.

<!-- ## Wishlist
- [ ] Notify user when a new version of a mod is available.
- [x] Download mods to mods folder
- [ ] Combine first two into a nice script
- [ ] Handle dependencies / library mods
- [x] Search for and install new mods
- [ ] Upgrade all mods to new preferred version of Minecraft.
- [x] ~~Mod folders / profiles (eg `1.16`, `1.17 Optifine`, `1.17 Sodium`)~~ Branches
- [ ] Texture / resource packs support?
- [ ] Shader pack support??? -->

## Dependencies and running MCPKG
MCPKG is written in [V](https://vlang.io/), but it doesn't need any other dependencies.

After installing V, clone and enter this repo and type `v run .` to start mcpkg. If you want to build the project, it's simply `v .`.

You can install V from
- [V's website](https://vlang.io/)
- [V's Github](https://github.com/vlang/v)
