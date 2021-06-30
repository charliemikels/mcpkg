module mod_platforms

import net
import net.http
import json

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

struct HitList {
	hits       []ModResult
	offset     int
	limit      int
	total_hits int
}

fn modrinth_list_mods(f SearchFilter) []Mod {


	// prepare html request
	config := http.FetchConfig{
		// See https://github.com/modrinth/labrinth/wiki/API-Documentation
		params: map{
			'query': ''//f.name
			// 'version': 'version="$f.version"'
			'limit': f.limit.str()
		}
	}

	// make the request
	responce := http.fetch('https://api.modrinth.com/api/v1/mod', config) or {
		println('http.fetch() failed')
		panic(err)
	}

	// Parse json results structs
	hits := json.decode(HitList, responce.text) or {
		println('JSON failed to decode responce.text from Modrinth.')
		panic(err)
	}

	// Convert hits into mcpkg mod list
	mut mod_list := []Mod{}

	for i, mod in hits.hits {
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
