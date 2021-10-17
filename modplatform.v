module mcpkg

// load_mod_platforms runs ModPlatform constructors and converts them into a map.
// This is ran by load_api()
fn (mut a Api) load_mod_platforms() map[string]ModPlatform {
	mut platforms := []ModPlatform{}
	// vv new platforms here vv
	platforms << a.new_platform_modrinth()
	// ^^ new platforms here ^^
	mut platform_map := map[string]ModPlatform{}
	for p in platforms {
		if p.requires_authentication && a.auth_keys[p.name] == '' {
			a.notifications << Notification{	// since API is already mutable, we can directly insert a notification here.
				title: 'Platform $p.name requires authentication.',
				msg: 'No authentication key was found for $p.name in ${a.auth_keys_path}. $p.name will be skipped.'
			}
			continue
		}

		platform_map[p.name] = p
	}
	return platform_map
}

const page_size_const = 10

interface ModPlatform {
	name string
	home_url string
	requires_authentication bool
	// TODO: Set all these methods to also return []Notification, rather than fenagaling the `return error()` system.
	search_for_mods(search SearchFilter, page PageInfo) ([]Mod, []Notification)
	get_mod_by_id(mod_id string) (Mod, []Notification)
	get_versions_by_mod_id(mod_id string) ([]ModVersion, []Notification)
}

pub struct SearchFilter {
	query         string
	game_versions []string
	platform_name string
}

pub struct PageInfo {
	number         int
	items_per_page int = 10
	total_pages    int = -1
	total_items    int = -1
}

// search_for_mods forwards a search request to all mod platforms.
// If a platform is provided in SearchFilter, use only that platform.
pub fn (mut a Api) search_for_mods(s SearchFilter) ([]Mod, []Notification) {
	mut notifications := []Notification{}
	page_num := 0 // TODO: put in search_for_mods(s SearchFilter, page_num int)
	page := PageInfo{
		number: page_num
	}
	if s.platform_name != '' {
		mut p := a.mod_platforms[s.platform_name] or {
			notifications << Notification{
				title: 'No platform $s.platform_name',
				msg: 'No known platform with key `$s.platform_name`. Known keys: $a.mod_platforms.keys()',
			}
			return []Mod{}, notifications
		}
		return p.search_for_mods(s, page)

	} else {
		mut mod_list := []Mod{}
		for _, p in a.mod_platforms {
			mod, notifs := p.search_for_mods(s, page)
			mod_list << mod
			notifications << notifs
		}
		return mod_list, notifications
	}
}

pub fn (a Api) get_full_mod(mod Mod) (Mod, []Notification) {
	return mod.platform.get_mod_by_id(mod.id)
}

// pub fn (a Api) get_full_version(ver ModVersion) ModVersion {
// 	return mod.platform.get_version_by_id(ModVersion.id)
// }

pub fn (mut a Api) get_mod_versions(mod Mod) ([]ModVersion, []Notification) {
	return mod.platform.get_versions_by_mod_id(mod.id)
}
