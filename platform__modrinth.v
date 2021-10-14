module mcpkg

import net.http
import json

struct PlatformModrinth {
	name                    string = 'modrinth'
	home_url                string = 'https://modrinth.com/'
	requires_authentication bool   = true
	auth_key                string
}

fn (a Api) new_platform_modrinth() ModPlatform {
	modrinth := PlatformModrinth{
		auth_key: a.auth_keys['modrinth'] or { '' }
	}
	return ModPlatform(modrinth)
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
	versions       []string // version here refers to minecraft game versions
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
	error          string
}

// ModrinthHitList: info about the search.
// Used with GET https://api.modrinth.com/v2/search
struct ModrinthHitList {
	hits        []ModrinthModResult
	offset      int // skip number of items
	limit       int // number of items per return
	total_hits  int
	error       string
	description string // only used if error != ''
}

// Detailed info about a mod
// Used with get_mod_by_id()
struct ModrinthModFull {
	id          string
	slug        string
	team        string // ID of team responcible for Mod.
	title       string
	description string
	body        string // longer description
	// body_url is still returned to us, but it allways null so far.
	published     string // same as date_created ?
	updated       string // same as date_modified ?
	status        string // Modinth upload status like "approved". Likely for mod devs.
	license       map[string]string
	client_side   string // (optional, required, unsupported, others?)
	server_side   string // (optional, required, unsupported, others?)
	downloads     int
	follows       int
	categories    []string
	versions      []string // IDs of versions of the mod.
	icon_url      string
	issues_url    string
	sources_url   string
	wiki_url      string
	discord_url   string
	donation_urls []map[string]string // Convert to struct?? (id, name, url)
}

struct ModrinthModVersion {
	id             string
	mod_id         string // TODO: This is called "project_id" in api v2
	name           string // name of the version
	version_number string
	changelog      string
	dependencies   []string // list of version IDs
	game_versions  []string
	version_type   string   // "release" "beta" "alpha"
	loaders        []string // mod loaders
	featured       bool
	author_id      string
	date_published string
	downloads      int
	files          []ModrinthModVersionFiles
}

struct ModrinthModVersionFiles {
	hashes   map[string]string // sha512, sha1
	url      string
	filename string
	primary  bool
}

// --== Helper fns ==--
fn (p PlatformModrinth) mmr_to_mcpkg_mod(mmr ModrinthModResult) Mod {
	urls := {
		'author': mmr.author_url
	}
	extras := ModExtraDetails{
		links: urls
		license: {
			'id': mmr.license
		}
		page_url: mmr.page_url
		date_created: mmr.date_created
		date_modified: mmr.date_modified
		downloads: mmr.downloads
		// follows: mmr.follows
		// client_side: mmr.client_side
		// server_side: mmr.server_side
	}

	mod := Mod{
		platform: &p
		platform_string: p.name
		name: mmr.title
		slug: mmr.slug
		id: if mmr.mod_id.contains('local-') { mmr.mod_id[6..] } else { mmr.mod_id }
		author: mmr.author
		description: mmr.description
		game_versions: mmr.versions
		icon_url: mmr.icon_url
		extras: extras
	}
	return mod
}

fn (p PlatformModrinth) mmf_to_mcpkg_mod(mmf ModrinthModFull) Mod {
	mod_id := if mmf.id.contains('local-') { mmf.id[6..] } else { mmf.id }

	mut urls := {
		// 'author': mmf.author_url
		'issues':  mmf.issues_url
		'wiki':    mmf.wiki_url
		'discord': mmf.discord_url
	}

	for donation_platform in mmf.donation_urls {
		urls[donation_platform['id']] = donation_platform['url']
	}

	extras := ModExtraDetails{
		links: urls
		license: mmf.license
		page_url: 'https://modrinth.com/mod/$mmf.slug'
		date_created: mmf.published
		date_modified: mmf.updated
		downloads: mmf.downloads
		description_full: mmf.body
		// follows: mmf.follows
		// client_side: mmf.client_side
		// server_side: mmf.server_side
	}

	mod := Mod{
		platform: &p
		platform_string: p.name
		name: mmf.title
		slug: mmf.slug
		id: mod_id
		author: mmf.team // TODO: Find list of members, and credit as []authors
		description: mmf.description
		// game_versions: ____	// TODO parse mmf.versions into ModVersions, then get game version numbers from them.
		icon_url: mmf.icon_url
		extras: extras
		versions: p.get_mod_versions_by_id(mod_id)
	}
	return mod
}

fn (p PlatformModrinth) mmv_to_mcpkg_mod_version(mmv ModrinthModVersion) ModVersion {
	version := ModVersion{
		name: mmv.name
		version_number: mmv.version_number
		version_id: mmv.id
		mod_id: mmv.mod_id
		changelog: mmv.changelog
		dependencies: mmv.dependencies.map(ModId{ // convert to external var??
			id: it
			platform_string: p.name
		})
		game_versions: mmv.game_versions
		version_type: mmv.version_type
		loaders: mmv.loaders
		date_published: mmv.date_published
		downloads: mmv.downloads
		files: mmv.files.map(ModVersionFile{
			hashes: it.hashes
			url: it.url
			filename: it.filename
		})
	}

	// println(version)
	return version
}

// --== ModPlatform interface fns ==--

// search_for_mods: wrapper for GET https://api.modrinth.com/v2/search
// See also: https://docs.modrinth.com/api-spec/#operation/searchProjects
fn (p PlatformModrinth) search_for_mods(search SearchFilter, page PageInfo) []Mod {
	// Build facets. See https://docs.modrinth.com/docs/tutorials/api_search/#facets
	mut facet_versions := ''
	if search.game_versions !in [[''], []] {
		for v in search.game_versions {
			facet_versions += '"versions:$v",'
		}
		facet_versions = facet_versions[..facet_versions.len - 1] // trim trailing `,`
		facet_versions = '[' + facet_versions + ']'
	}
	facets := '[$facet_versions]'

	mut paramiters := {
		'limit':        '$page.items_per_page'
		'offset':       '${page.number * page.items_per_page}'
		'query':        search.query
		'facets':       facets
		'project_type': 'mod'
	}
	if facets == '[]' {
		paramiters.delete('facets')
		// Modrinth passes whatever is in facets to its facets parser, but the
		// parser gets confused when it gets '[]' or even ''. So if don't have
		// any facets to give we need to send `null`, which isn't going to fly
		// with V, so we'll delete it instead.
	}

	mut config := http.FetchConfig{
		// url: 'https://api.modrinth.com/v2/search'
		// url: 'https://staging-api.modrinth.com/v2/search'
		url: 'https://api.modrinth.com/api/v1/mod' // TODO: looks like v2 isn't quite ready yet. Using v1 for now, But check back and upgrade later.
		params: paramiters
	}
	config.header.add(http.CommonHeader.authorization, p.auth_key)

	responce := http.fetch(config) or { panic(err) }

	hit_list := json.decode(ModrinthHitList, responce.text) or { panic(err) }
	if hit_list.error != '' {
		eprintln('Modrinth API returned an error: \n$responce.text')
		exit(1)
	}

	mod_list := hit_list.hits.map(p.mmr_to_mcpkg_mod(it))
	return mod_list

	// TODO: Tell searcher how many pages there are. (Implement 'struct ModList{}'?)
	// return mod_list, PageInfo {
	// 	number:     		page.number
	// 	items_per_page: page.items_per_page
	// 	// total_pages:
	// 	total_items:		total_hits
	// }
}

// get_mod_by_id: wrapper for GET 'https://api.modrinth.com/v2/project/${mod_id}'
// See also: https://docs.modrinth.com/api-spec/#operation/getProject
fn (p PlatformModrinth) get_mod_by_id(mod_id string) Mod {
	mut config := http.FetchConfig{
		// url: 'https://api.modrinth.com/v2/project/${mod_id}'
		url: 'https://api.modrinth.com/api/v1/mod/$mod_id' // TODO: looks like v2 isn't quite ready yet. Using v1 for now, But check back and upgrade later.
		// params: {}
	}
	config.header.add(http.CommonHeader.authorization, p.auth_key)

	responce_mod := http.fetch(config) or { panic(err) }
	mod_full := json.decode(ModrinthModFull, responce_mod.text) or { panic(err) }

	return p.mmf_to_mcpkg_mod(mod_full)
}

fn (p PlatformModrinth) get_mod_versions_by_id(mod_id string) []ModVersion {
	mut config := http.FetchConfig{
		url: 'https://api.modrinth.com/api/v1/mod/$mod_id/version'
	}
	config.header.add(http.CommonHeader.authorization, p.auth_key)

	versions_responce := http.fetch(config) or { panic(err) }
	versions := json.decode([]ModrinthModVersion, versions_responce.text) or { panic(err) }

	return versions.map(p.mmv_to_mcpkg_mod_version(it))
}
