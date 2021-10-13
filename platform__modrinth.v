module mcpkg

import net.http
import json

struct PlatformModrinth {
	name     string = 'modrinth'
	home_url string = 'https://modrinth.com/'
}

// --== Api responce structs ==--

// ModrinthModResult: Simplified version of ModrinthMod returned after a search.
// Used with ModrinthHitList.
struct ModrinthModResult {
	mod_id         string
	slug           string
	author         string
	title          string
	description    string
	categories     []string
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
	client_side    string // (optional, required, unsupported, others?)
	server_side    string // (optional, required, unsupported, others?)
	host           string
	error 		 		 string
}

// ModrinthHitList: info about the search.
// Used with GET https://api.modrinth.com/v2/search
struct ModrinthHitList {
	hits       []ModrinthModResult
	offset     int // skip number of items
	limit      int // number of items per return
	total_hits int
	error 		  string
	description string // only used if error != ''
}

// --== Helper fns ==--
fn (p PlatformModrinth)mmr_to_mcpkg_mod(mmr ModrinthModResult) Mod{
	mod := Mod{
		platform: &p
		platform_string: p.name
		name: mmr.title
		slug: mmr.slug
		id: mmr.mod_id
		author: mmr.author
		description: mmr.description
		game_versions: mmr.versions
		downloads: mmr.downloads
		// follows: mmr.follows
		page_url: mmr.page_url
		icon_url: mmr.icon_url
		author_url: mmr.author_url
		date_created: mmr.date_created
		date_modified: mmr.date_modified
		latest_version: mmr.latest_version
		license: mmr.license
		// client_side: mmr.client_side
		// server_side: mmr.server_side
	}
	return mod
}

// --== ModPlatform interface fns ==--

// search_for_mods: wrapper for GET https://api.modrinth.com/v2/search
// See also: https://docs.modrinth.com/api-spec/#operation/searchProjects
fn (p PlatformModrinth) search_for_mods(search SearchFilter, page PageInfo) []Mod {

	// Build facets. See https://docs.modrinth.com/docs/tutorials/api_search/#facets
	mut facet_versions := ''
	if search.game_versions !in [[''], []] {
		for v in search.game_versions { facet_versions += '"versions:$v",' }
		facet_versions = facet_versions[..facet_versions.len - 1] // trim trailing `,`
		facet_versions = '[' + facet_versions + ']'
	}
	facets := '[$facet_versions]'

	// http prep...
	offset := page.number * page.items_per_page
	mut paramiters := {
		'limit':  '$page.items_per_page'
		'offset': '$offset'
		'query':  search.query
		'facets':  facets
	}
	if facets == '[]' {
		paramiters.delete('facets')
		// Modrinth passes whatever is in facets to its facets parser, but the
		// parser gets confused when it gets '[]' or even ''. So if don't have
		// any facets to give we need to send `null`, which isn't going to fly
		// with V, so we'll delete it instead.
	}

	config := http.FetchConfig{
		// url: 'https://api.modrinth.com/v2/search'
		// url: 'https://staging-api.modrinth.com/v2/search'
		url: 'https://api.modrinth.com/api/v1/mod'		// TODO: looks like v2 isn't quite ready yet. Using v1 for now, But check back and upgrade later.
		params: paramiters
	}

	responce := http.fetch(config) or { panic(err) }

	hit_list := json.decode(ModrinthHitList, responce.text) or { panic(err)	}
	if hit_list.error != '' {
		eprintln('Modrinth API returned an error: \n$responce.text')
		exit(1)
	}

	mod_list := hit_list.hits.map( p.mmr_to_mcpkg_mod(it) )
	return mod_list

	// TODO: Tell searcher how many pages there are. (Implement 'struct ModList{}'?)
	// return mod_list, PageInfo {
	// 	number:     		page.number
	// 	items_per_page: page.items_per_page
	// 	// total_pages:
	// 	total_items:		total_hits
	// }
}
