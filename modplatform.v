module mcpkg

// Idealy, build this list from a dir of platform plug-ins, but this will work fine.
const mod_platforms_const = {
	'modrinth': ModPlatform(PlatformModrinth{})
	'bogus': ModPlatform(PlatformBogusPlatform{})
}

interface ModPlatform {
	//api &Api
	name string
	home_url string
	search_for_mods(SearchFilter) []Mod
	// get_updates([]Mod) []ModVersion
}

pub struct SearchFilter {
	query         string
	game_versions []string
	platform_name string
}

// search_for_mods forwards a search request to all mod platforms.
// If a platform is provided in SearchFilter, use only that platform.
pub fn (a Api)search_for_mods(s SearchFilter) []Mod {
	if s.platform_name != '' {
		p := a.mod_platforms[s.platform_name] or {
			eprintln('No platform with key `$s.platform_name`')
			return []
		}
		return p.search_for_mods(s)
	} else {
		mut mod_list := []Mod{}
		for _, p in a.mod_platforms {
			 mod_list << p.search_for_mods(s)
		}
		return mod_list
	}
}





// Dummy mod platform to test interfaceness. 
pub struct PlatformBogusPlatform {
	name string = 'yes'
	home_url string = 'no'
}

fn (p PlatformBogusPlatform) search_for_mods(s SearchFilter) []Mod {
	return []
}
