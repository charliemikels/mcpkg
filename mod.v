module mcpkg

import x.json2
import json

struct Mod {
pub mut:
	is_incomplete bool = true
	name          string
	slug          string
	platform      ModPlatform = ModPlatform(PlatformDummy{})
	id            string
	// platform_string string [json: platform]	// generate on load w/ json2
	author        string
	description   string
	game_versions []string
	icon_url      string
	versions      []ModVersion
	page_url      string
	date_created  string
	date_modified string
	// published					string	// same as date_created?
	// catagories				[]string
	downloads int
	// follows				int
	description_full string
	// license          map[string]string	// TODO? convert to struct? Move to links?
	license string
	// id, name, url
	links map[string]string
	// client_side: 	string
	// server_side: 	string
}

// ModVersion is a specific version of a mod. Not to be confused with GameVersion
struct ModVersion {
mut:
	is_incomplete  bool        = true
	platform       ModPlatform = ModPlatform(PlatformDummy{})
	id             string
	mod            Mod
	name           string
	number         string // version number, as in '0.1.5' etc.
	version_type   string // "release" "beta" "alpha"
	game_versions  []string
	files          []ModVersionFile
	date_published string
	changelog      string
	dependencies   []Mod
	loaders        []string // merge with dependencies??
	downloads      int
	// author_id			string
}

struct ModVersionFile {
mut:
	// mod_version &ModVersion
	hashes   map[string]string
	url      string
	filename string
	// primary  bool
}

fn (v ModVersion) to_json() json2.Any {
	mut json_map := map[string]json2.Any{}
	json_map['id'] = v.id
	json_map['platform'] = v.platform.name
	json_map['name'] = v.name
	json_map['number'] = v.number
	json_map['mod_id'] = v.mod.id
	json_map['date_published'] = v.date_published
	json_map['files'] = v.files.map(json2.Any(it.filename))
	// json_map['dependency_ids'] = v.dependencies.map(it.id )
	return json_map
}

fn (mut a Api) json_to_mod(json json2.Any) Mod {
	mut mod := Mod{}
	for k, v in json.as_map() {
		match k {
			'platform' {
				mod.platform = a.mod_platforms[v.str()] or {
					a.notifications << new_alert('high', 'Error loading Mod from json: No known platform `$v.str()`',
						'`$v.str()` is not in the list of known platforms: $a.mod_platforms')
					continue
				}
			}
			'id' {
				mod.id = v.str()
			}
			'name' {
				mod.name = v.str()
			}
			'slug' {
				mod.slug = v.str()
			}
			'page_url' {
				mod.page_url = v.str()
			}
			'icon_url' {
				mod.icon_url = v.str()
			}
			// the rest can be built from a.get_full_mod()
			else {}
		}
	}
	return mod
}

fn (a Api) json_to_mod_version(json json2.Any) ModVersion {
	mut ver := ModVersion{}
	mut mod_id := ""
	for k, v in json.as_map() {
		match k {
			'platform' { ver.platform = a.mod_platforms[v.str()] }
			'id' { ver.id = v.str() }
			'mod_id' { mod_id = v.str() }
			'name' { ver.name = v.str() }
			'number' { ver.number = v.str() }
			// 'files' { ver.files = v.arr().map(a.json_to_mod_version_file(it)) }
			'files' { ver.files = v.arr().map(ModVersionFile{ filename: it.str() }) }
			// the rest can be built from a.get_full_version()
			else {}
		}
	}

	ver.mod = Mod{
		platform: ver.platform
		id: mod_id
	}
	return ver
}
