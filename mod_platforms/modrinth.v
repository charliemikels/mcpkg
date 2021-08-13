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
		// list_mods: modrinth_list_mods
		get_mods_by_search: modrinth_get_mods_by_search
		get_mod_details: modrinth_get_mod_details
		// download_mod: modrinth_download_mod
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
	date_created   string // IDEA: Date time type?
	date_modified  string // IDEA: Date time type?
	latest_version string
	license        string
	client_side    string // IDEA?: Enum (Optional, Required, other?)
	server_side    string // IDEA?: Enum (Optional, Required, other?)
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

// Since modrinth won't return a full list for /api/v1/mods, we can use this helper fn to make multipule requests easier
fn modrinth_make_mod_request(filter SearchFilter, limit int, cycle int) ModrinthHitList {
	// Prepare Modrinth Request
	offset := limit * cycle
	index := if filter.query == '' { 'updated' } else { 'relevance' }

	// build game_version facets
	mut facet_versions := ''
	if filter.game_versions !in [[''], []] {
		// println('There are game versions')
		for v in filter.game_versions {
			facet_versions += '"versions:$v",'
		}
		facet_versions = '[' + facet_versions[..facet_versions.len - 1] + ']'
	}

	// build facets string
	mut facets := '[' + facet_versions + ']'

	// build final paramaters map
	mut p := {
		'limit':  '$limit'
		'offset': '$offset'
		'index':  index
		'query':  filter.query
		// 'versions': version_string
	}

	// retroactively add in facets
	if facets != '[]' {
		p['facets'] = facets
	}
	// Facets are funky. If they're given nothing, then facets are ignored,
	// but if its '' or '[]', then they remove the other results, trying to
	// apply a non-existant filter. This doesn't play well with V's no nulls
	// rule, so I have to conditionally add it in after the fact.

	// println('cycle $cycle is using these params: $p')

	// make the request
	config := http.FetchConfig{
		params: p
	}

	responce := http.fetch('https://api.modrinth.com/api/v1/mod', config) or {
		println('http.fetch() failed')
		panic(err)
	}

	// Decode JSON
	hit_list := json.decode(ModrinthHitList, responce.text) or {
		println('JSON failed to decode responce.text from Modrinth.')
		panic(err)
	}

	// println('cycle $cycle is done, and got $hit_list.hits.len hits out of $hit_list.total_hits')

	return hit_list
}

// platform.get_mods_by_search:
fn modrinth_get_mods_by_search(filter SearchFilter) []Mod {
	println('Modrinth: Making request 1')

	// Make http request
	request_limit := 100

	hit_list_1 := modrinth_make_mod_request(filter, request_limit, 0)

	mut mod_result_list := []ModrinthModResult{}
	mod_result_list << hit_list_1.hits

	// calculate needed cycles to get full list.
	cycles := int(math.ceil(f64(hit_list_1.total_hits) / f64(request_limit))) // total items / slice. round up

	// println('Pass 1 returned $hit_list_1.hits.len items. There are $hit_list_1.total_hits in total, and we plan to make $cycles requests of $request_limit mods each.')

	// reppetedly make requests to finish list.
	mut threads := []thread ModrinthHitList{}
	for c in 1 .. cycles {
		println('Modrinth: Starting request ${c + 1} out of $cycles') // request 1 is actualy request 0
		threads << go modrinth_make_mod_request(filter, request_limit, c)
	}
	threaded_hit_lists := threads.wait()
	println('all requests done')
	// println('len mod_len pre = ${mod_result_list.len}')
	for thl in threaded_hit_lists {
		mod_result_list << thl.hits
	}
	// println('len mod_len post = ${mod_result_list.len}')

	// Convert hits into mcpkg mod list
	mut mod_list := []Mod{}
	for mod in mod_result_list {
		mod_list << Mod{
			host: modrinth().name
			platform: modrinth()
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
	id := if m.id.contains('local-') { m.id[6..] } else { m.id }

	// Prep API requests. I think we can get away with only one config.
	config := http.FetchConfig{
		// See https://github.com/modrinth/labrinth/wiki/API-Documentation
		params: {
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
