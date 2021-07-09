module mod_platforms

import net
import net.http
import json
import math

// define platform
fn modrinth() ModPlatform {
	return ModPlatform{
		name: 'Modrinth'
		base_url: 'https://modrinth.com/'
		list_mods: modrinth_list_mods
		get_mod_details: modrinth_get_mod_details
		download_mod: modrinth_download_mod
	}
}

// structs for parsing json
struct ModrinthModResult { // used with ModrinthHitList
	mod_id         string
	slug           string
	author         string
	title          string
	description    string
	categories     []string // Do not parse to enums, they might add new catagories.
	versions       []string
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

struct ModrinthHitList { // Snippit of mod info, usefull in list of mods. Used with GET https://api.modrinth.com/api/v1/mod/
	hits       []ModrinthModResult
	offset     int
	limit      int
	total_hits int
}

struct ModrinthMod { // more detailed than mod result. Used with GET https://api.modrinth.com/api/v1/mod/${id}/
	id   string
	slug string
	// team				string	// the team that owns the mod
	title       string
	description string
	body        string // long description
	// body_url string	// Deprecated
	published string // datetime
	updated   string // datetime
	// status string // approved / rejected / draft / unlisted / processing
	// license License{}
	client_side string // required, optional, unsupported, unknown.
	server_side string // required, optional, unsupported, unknown.
	downloads   int
	// categories []string
	versions []int // list of version IDs
	// icon_url string?
	// issues_url
	// source_url
	// wiki_url
	// discord_url
	// donation_urls []Donation_link
}

// struct ModrinthLicense {}
// struct ModrinthDonationLink {}

struct ModrinthVersion { // Used with GET https://api.modrinth.com/api/v1/mod/${id}/version
	id        string
	mod_id    string
	author_id string
	// featured userID
	name           string
	version_number string
	// change_log "string?"
	date_published string
	// downloads int
	version_type  string // alpha, beta, release
	files         []ModrinthVersionFile
	dependencies  []int    // version IDs of dependancies
	game_versions []string // array of game versison
	loaders       []string //'array of mod loaders'
}

struct ModrinthVersionFile {
	hashes   map[string]string
	url      string
	filename string
}

// platform.list_mods:
fn modrinth_list_mods() []Mod { // fn(f SearchFilter). Looks like /*...*/ comments were removed or something.
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
		println('Modrinth: Making request ${n + 1} out of $cycles') // request 1 is actualy request 0

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

// platform.get_mod_details
fn modrinth_get_mod_details(m Mod) ModDetailed {
	// Terra has a lot of versions. id: FIlZB9L0
	// Sodium: AANobbMI
	println('Modrinth: Looking up info about $m.id')

	// Looks like the api doesn't actualy use the 'local-' part of the ID. Let's remove it
	id := if 'local-' in m.id { m.id[6..] } else { m.id }

	// Prep API requests. I think we can get away with only one config.
	config := http.FetchConfig{
		// See https://github.com/modrinth/labrinth/wiki/API-Documentation
		params: map{
			'index': 'updated'
			'limit': '100'
			// 'offset': ----
			// TODO: Limit versions to current prefered game version
		}
	}

	// Make api requests	// TODO: make paralel
	// Fetch detailed mod info
	responce_mod := http.fetch('https://api.modrinth.com/api/v1/mod/$id', config) or { panic(err) }
	mod := json.decode(ModrinthMod, responce_mod.text) or { panic(err) }

	// Fetch version info
	responce_versions := http.fetch('https://api.modrinth.com/api/v1/mod/$id/version',
		config) or { panic(err) }
	versions := json.decode([]ModrinthVersion, responce_versions.text) or { panic(err) }

	// Convert into generalized structs
	mut generalized_versions := []Version{}
	for mv in versions {
		// in case of multiple files
		mut files_list := []VersionFile{}
		for f in mv.files {
			files_list << VersionFile{
				hashes: f.hashes
				url: f.url
				filename: f.filename
			}
		}

		generalized_versions << Version{
			id: mv.id
			mod: m
			name: mv.name
			version_number: mv.version_number
			version_type: mv.version_type
			game_versions: mv.game_versions
			date_published: mv.date_published
			files: files_list
		}
	}

	detailed_mod := ModDetailed{
		Mod: m
		long_description: mod.body
		mod_versions: generalized_versions
	}

	return detailed_mod
}

// platform.download_mod:
fn modrinth_download_mod(mod_id_version string) string {
	return 'Mod downloading WIP.'
}
