module mod_platforms

import net
import net.http
import json
import math


// List of expected game versions in order: https://api.modrinth.com/api/v1/tag/game_version

// define platform
fn modrinth() ModPlatform {
	return ModPlatform{
		name: 'Modrinth'
		base_url: 'https://modrinth.com/'
		list_mods: modrinth_list_mods
		get_mod_info: modrinth_get_mod_info
		download_mod: modrinth_download_mod
	}
}

// structs for parsing json
struct ModrinthModResult {	// used with ModrinthHitList
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

struct ModrinthHitList {	// Used with GET https://api.modrinth.com/api/v1/mod/
	hits       []ModrinthModResult
	offset     int
	limit      int
	total_hits int
}

// struct ModrinthMod {	// more detailed than mod result. Used with GET https://api.modrinth.com/api/v1/mod/{ID}/
// 	id string
// 	slug string
// 	// team	string	// the team that owns the mod
// 	title string
// 	description string
// 	// body string // long description
// 	// body_url string // Deprecated
// 	published string	// datetime
// 	updated string	// datetime
// 	// status string // approved / rejected / draft / unlisted / processing
// 	// license License{}
// 	client_side string // required, optional, unsupported, unknown.
// 	server_side string // required, optional, unsupported, unknown.
// 	downloads int
// 	// categories []string
// 	versions []int 	// list of version IDs
// 	// icon_url string?
// 	// issues_url
// 	// source_url
// 	// wiki_url
// 	// discord_url
// 	// donation_urls []Donation_link
// }

// struct ModrinthLicense {}
// struct ModrinthDonationLink {}

struct ModrinthVersion {
	id	string
	mod_id string
	author_id string
	// featured userID
	name string
	version_number string
	// change_log "string?"
	date_published string
	// downloads int
	version_type string // alpha, beta, release
	files []ModrinthVersionFile
	dependencies []int // version IDs of dependancies
	game_version []string //array of game versison
	loaders []string //'array of mod loaders'
}

struct ModrinthVersionFile {
	hashes map[string]string
	url string
	filename string
}



// platform.list_mods:
fn modrinth_list_mods(/*f SearchFilter*/) []Mod {
	// prepare initial html request
	config_1 := http.FetchConfig{
		// See https://github.com/modrinth/labrinth/wiki/API-Documentation
		params: map{
			'index': 'updated'
			'limit': '100'
			// 'offset': ----
		}
	}

	println('Modrinth: Making request 1')

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

	// println('Request 1 done')

	// calculate needed cycles to get full list.
	cycles := int(math.ceil(f64(hit_list_1.total_hits) / 100.0)) // total items / slice. round up

	// reppetedly make requests to finish list.
	for n in 1 .. cycles {
		println('Modrinth: Making request ${n+1} out of ${cycles}') // request 1 is actualy request 0

		config_n := http.FetchConfig{
			// See https://github.com/modrinth/labrinth/wiki/API-Documentation
			params: map{
				'query':  '' // f.name
				// 'version': 'version="$f.version"'
				// 'version': 'version="1.16.3" OR version="1.16.2" OR version="1.16.1"'
				'limit':  '100' // f.limit.str()
				'offset': '${100 * n}'
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
			host: modrinth().name
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

fn modrinth_get_mod_info( mod_id string) {
	// Terra has a lot of versions. Good for testing: FIlZB9L0
	// Sodium: AANobbMI
	println('Modrinth: Looking up info about $mod_id')

	// Looks like the api doesn't actualy use the 'local-' part of the ID. Let's remove it
	id := if 'local-' in mod_id { mod_id[6..] } else { mod_id }
	// println(id)

	config := http.FetchConfig{
		// See https://github.com/modrinth/labrinth/wiki/API-Documentation
		params: map{
			'index': 'updated'
			'limit': '100'
			// 'offset': ----
		}
	}

	responce := http.fetch('https://api.modrinth.com/api/v1/mod/$id/version', config) or {
		// println('http.fetch() failed')
		panic(err)
	}

	// Parse json results structs
	versions := json.decode([]ModrinthVersion, responce.text) or {
		panic(err)
	}

	println(versions)


}

// platform.download_mod:
fn modrinth_download_mod( mod_id_version string ) string {
	return 'Mod downloading WIP.'
}
