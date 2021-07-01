module mod_platforms

import net
import net.http
import json
import math

// define platform
fn modrinth() ModPlatform  {
	return ModPlatform{
		name: 'Modrinth'
		base_url: 'https://modrinth.com/'
		list_mods: modrinth_list_mods
		download_mod: modrinth_download_mod
	}
}

// structs for parsing json
struct ModrinthModResult {
	mod_id         string
	slug           string
	author         string
	title          string
	description    string
	categories     []string // Do not parse to enums, they might add new catagories.
	versions       []string // TODO: parse into versions struct
	downloads      int
	follows        int
	page_url       string
	icon_url       string
	author_url     string
	date_created   string // TODO: Date time type?
	date_modified  string // TODO: Date time type?
	latest_version string // TODO: parse into versions struct
	license        string
	client_side    string // TODO?: Enum (Optional, Required, other?)
	server_side    string // TODO?: Enum (Optional, Required, other?)
	host           string
}

struct ModrinthHitList {
	hits       []ModrinthModResult
	offset     int
	limit      int
	total_hits int
}

fn modrinth_list_mods(f SearchFilter) []Mod {

	// prepare html request
	config_1 := http.FetchConfig{
		// See https://github.com/modrinth/labrinth/wiki/API-Documentation
		params: map{
			'query': ''//f.name
			// 'version': 'version="$f.version"'
			'limit': '100' //f.limit.str()
			// 'offset': ----
		}
	}

	// make the request
	responce_1 := http.fetch('https://api.modrinth.com/api/v1/mod', config_1) or {
		println('http.fetch() failed')
		panic(err)
	}

	// Parse json results structs
	hit_list_1 := json.decode(ModrinthHitList, responce_1.text) or {
		println('JSON failed to decode responce.text from Modrinth.')
		panic(err)
	}



	mut mod_result_list := []ModrinthModResult{}
	mod_result_list << hit_list_1.hits

	// calculate needed cycles to get full list.
	cycles := int(math.ceil(f64(hit_list_1.total_hits) / 100.0))	// total items / slice. round up

	// reppetedly make requests to finish list.
	for n in 1..cycles {
		config_n := http.FetchConfig{
			// See https://github.com/modrinth/labrinth/wiki/API-Documentation
			params: map{
				'query': ''//f.name
				// 'version': 'version="$f.version"'
				'limit': '100' //f.limit.str()
				'offset': '${100*n}'
			}
		}

		// make the request
		responce_n := http.fetch('https://api.modrinth.com/api/v1/mod', config_n) or {
			println('http.fetch() failed')
			panic(err)
		}

		// Parse json results structs
		hit_list_n := json.decode(ModrinthHitList, responce_n.text) or {
			println('JSON failed to decode responce.text from Modrinth.')
			panic(err)
		}
		mod_result_list << hit_list_n.hits
	}



	// Convert hits into mcpkg mod list
	mut mod_list := []Mod{}

	for mod in mod_result_list {
		mod_list << Mod{
			host: modrinth()
			id: mod.mod_id
			slug: mod.slug
			author: mod.author
			title: mod.title
			description: mod.description
			game_versions: mod.versions
			page_url: mod.page_url
			icon_url: mod.icon_url
			date_created: mod.date_created
			date_modified: mod.date_modified
		}
	}

	return mod_list
}

fn modrinth_download_mod(mod_id string) string {
	return 'Mod downloading WIP.'
}
