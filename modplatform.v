module mcpkg

const mod_platforms{
	'modrinth': platform_modrinth()
}

//
struct ModPlatform {
	name string
	home_url string
	// search fn(searchFilter) []Mod
	// get_updates fn([]Mod)
}
