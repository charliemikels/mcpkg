module mcpkg

// load_mod_platforms runs ModPlatform constructors and converts them into a map.
// This is ran by load_api()
fn (mut a Api) load_mod_platforms() {
	mut platforms := []ModPlatform{}
	// vv new platforms here vv
	platforms << a.new_platform_modrinth()
	// ^^ new platforms here ^^
	mut platform_map := map[string]ModPlatform{}
	for p in platforms {
		if p.requires_authentication && a.auth_keys[p.name] == '' {
			a.notifications << Notification{ // since API is already mutable, we can directly insert a notification here.
				title: 'Platform $p.name requires authentication.'
				msg: 'No authentication key was found for $p.name in ${a.auth_keys_path}. $p.name will be skipped.'
			}
			continue
		}
		platform_map[p.name] = p
	}
	a.mod_platforms = platform_map.move()
}

const page_size_const = 10

interface ModPlatform {
	name string
	home_url string
	requires_authentication bool
	search_for_mods(search SearchFilter, page PageInfo) ?[]Mod
	get_mod_by_id(mod_id string) ?Mod
	get_versions_by_mod_id(mod_id string) ?[]ModVersion
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
pub fn (mut a Api) search_for_mods(s SearchFilter) []Mod {
	page_num := 0 // TODO: put in search_for_mods(s SearchFilter, page_num int)
	page := PageInfo{
		number: page_num
	}
	if s.platform_name != '' {
		mut p := a.mod_platforms[s.platform_name] or {
			a.notifications << Notification{
				title: 'No platform $s.platform_name'
				msg: 'No known platform with key `$s.platform_name`. Known keys: $a.mod_platforms.keys()'
			}
			return []Mod{}
		}
		return p.search_for_mods(s, page) or {
			a.notifications << err_msg_to_notification(err.msg)
			return []Mod{}
		}
	} else {
		mut mod_list := []Mod{}
		for _, p in a.mod_platforms {
			mod := p.search_for_mods(s, page) or {
				a.notifications << err_msg_to_notification(err.msg)
				continue
			}
			mod_list << mod
		}
		return mod_list
	}
}

pub fn (mut a Api) get_full_mod(mod Mod) Mod {
	return mod.platform.get_mod_by_id(mod.id) or {
		a.notifications << err_msg_to_notification(err.msg)
		return mod
	}
}

// pub fn (a Api) get_full_version(ver ModVersion) ModVersion {
// 	return mod.platform.get_version_by_id(ModVersion.id)
// }

pub fn (mut a Api) get_mod_versions(mod Mod) []ModVersion {
	return mod.platform.get_versions_by_mod_id(mod.id) or {
		a.notifications << err_msg_to_notification(err.msg)
		return []ModVersion{}
	}
}
