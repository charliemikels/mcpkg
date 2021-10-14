module mcpkg

// load_mod_platforms runs ModPlatform constructors and converts them into a map.
// This is ran by load_api()
fn (mut a Api) load_mod_platforms() map[string]ModPlatform {
	mut platforms := []ModPlatform{}
	// vv new platforms here vv
	platforms << a.new_platform_modrinth()


	mut platform_map := map[string]ModPlatform
	for p in platforms {
		if p.requires_authentication && a.auth_keys[p.name] == '' {
			continue
		}

		platform_map[p.name] = p
	}
	return platform_map
}

const page_size_const = 10

interface ModPlatform {
	// api &Api
	name string
	home_url string
	requires_authentication bool
	search_for_mods(search SearchFilter, page PageInfo) []Mod
	get_mod_by_id(mod_id string) Mod
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

pub fn (a Api) get_mod_by_id(mod_id string, platform_name string) []Mod {
	if platform_name != '' {
		p := a.mod_platforms[platform_name] or {
			eprintln('No platform with key `$platform_name`. Known keys: ${a.mod_platforms.keys()}')
			return []Mod{}
		}
		return [ p.get_mod_by_id(mod_id) ]
	} else {
		mut mod_list := []Mod{}
		for _, p in a.mod_platforms {
			mod_list << p.get_mod_by_id(mod_id)
		}
		return mod_list
	}
}
