module mcpkg

// Idealy, build this list from a dir of platform plug-ins, but this will work fine.
// Currently Api copies this into itself at load_api. TODO: Convert to "load_platforms" fn?
const mod_platforms_const = {
	'modrinth': ModPlatform(PlatformModrinth{})
}

const page_size_const = 10

interface ModPlatform {
	// api &Api
	name string
	home_url string
	// get_updates([]Mod) []ModVersion
	search_for_mods(search SearchFilter, page PageInfo) []Mod
}

pub struct SearchFilter {
	query         string
	game_versions []string
	platform_name string
}

pub struct PageInfo {
	number     			int
	items_per_page  int = 10
	total_pages			int = -1
	total_items			int = -1
}

// search_for_mods forwards a search request to all mod platforms.
// If a platform is provided in SearchFilter, use only that platform.
// TODO: Move to mod.v ?
pub fn (a Api) search_for_mods(s SearchFilter) ([]Mod) {
	page_num := 0 // TODO: put in search_for_mods(s SearchFilter, page_num int)
	page := PageInfo{
		number: page_num
	}
	if s.platform_name != '' {
		p := a.mod_platforms[s.platform_name] or {
			eprintln('No platform with key `$s.platform_name`. Known keys: ${a.mod_platforms.keys()}')
			return []Mod{}
		}
		return p.search_for_mods(s, page)
	} else {
		mut mod_list := []Mod{}
		for _, p in a.mod_platforms {
			mod_list << p.search_for_mods(s, page)
		}
		return mod_list
	}
}

