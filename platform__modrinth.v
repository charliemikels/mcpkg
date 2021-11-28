module mcpkg

import net.http
import x.json2

struct PlatformModrinth {
	name                    string = 'modrinth'
	home_url                string = 'https://modrinth.com/'
	requires_authentication bool // = true
	auth_key                string
}

fn (a Api) new_platform_modrinth() ModPlatform {
	modrinth := PlatformModrinth{
		auth_key: a.auth_keys['modrinth'] or { '' }
	}
	return ModPlatform(modrinth)
}

// Helpers:
// fn (p PlatformModrinth) mod_json_to_mcpkg_mod(j Json2.Any) Mod {}
// fn (p PlatformModrinth) version_json_to_mcpkg_version(j Json2.Any) ModVersion {}
// fn (p PlatformModrinth) version_file_json_to_mcpkg_version_file(j Json2.Any) ModVersionFile {}

// interface:

// search_for_mods: wrapper for GET https://api.modrinth.com/v2/search
// See also: https://docs.modrinth.com/api-spec/#operation/searchProjects
fn (p PlatformModrinth) search_for_mods(search SearchFilter, page PageInfo) ?[]Mod {
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

	responce := http.fetch(config) or {
		return error(Notification{
			title: '${@FN} failed to fetch json'
			msg: err.msg
		}.str())
	}
	responce_decoded := json2.raw_decode(responce.text) or {
		return error(Notification{
			title: '${@FN} failed to decode json'
			msg: err.msg
		}.str())
	}

	mut mod_list := []Mod{}
	// Maybe put this decoding into a helper fn, but this set will only ever be ran here anyways...
	for key, val in responce_decoded.as_map() {
		match key {
			'error' {
				return error(Notification{
					title: 'Modrinth.${@FN} includes an error.'
					msg: responce_decoded.as_map().str()
				}.str())
			}
			'limit' {} // items per return. 	num_pages := total_hits / limit
			'offset' {} // cuurent_page := offset / limit
			'total_hits' {} // total items found
			'hits' {
				for hit in val.arr() {
					mut mod := Mod{
						is_incomplete: true
						platform: &p
					}
					for k, v in hit.as_map() {
						match k {
							'mod_id' { mod.id = v.str().replace('local-', '') } // All other parts of the api will fail anyways, if 'local-' is sent to modrinth
							'slug' { mod.slug = v.str() }
							'author' { mod.author = v.str() }
							'title' { mod.name = v.str() }
							'description' { mod.description = v.str() }
							'categories' {} // []string
							'versions' { mod.game_versions = v.arr().map(it.str()) } // yes, 'version' here does not refer to VersionFiles
							'downloads' { mod.downloads = v.int() }
							'follows' {} // int
							'page_url' { mod.page_url = v.str() }
							'icon_url' { mod.icon_url = v.str() }
							'author_url' { mod.links['author'] = v.str() }
							'date_created' { mod.date_created = v.str() } // v.datetime() ?
							'date_modified' { mod.date_modified = v.str() }
							'latest_version' {} // still game_versions, and can be generated from game_versions anyways.
							'license' { mod.license = v.str() }
							'client_side' {}
							'server_side' {}
							'host' {} // ModPlatform.name
							else {}
						}
					}
					mod_list << mod
				}
			}
			else {}
		}
	}
	return mod_list // TODO: also return remaining search pages. see offset, limit, and total_hits
}

// get_mod_by_id: wrapper for GET 'https://api.modrinth.com/v2/project/${mod_id}'
// See also: https://docs.modrinth.com/api-spec/#operation/getProject
fn (p PlatformModrinth) get_mod_by_id(mod_id string) ?Mod {
	mut config := http.FetchConfig{
		// url: 'https://api.modrinth.com/v2/project/${mod_id}'
		url: 'https://api.modrinth.com/api/v1/mod/$mod_id' // TODO: looks like v2 isn't quite ready yet. Using v1 for now, But check back and upgrade later.
	}
	config.header.add(http.CommonHeader.authorization, p.auth_key)

	responce := http.fetch(config) or {
		return error(Notification{
			title: '${@FN} failed to fetch json'
			msg: err.msg
		}.str())
	}
	responce_decoded := json2.raw_decode(responce.text) or {
		return error(Notification{
			title: '${@FN} failed to decode json'
			msg: err.msg
		}.str())
	}

	mut mod := Mod{
		platform: &p
	}
	for k, v in responce_decoded.as_map() {
		match k {
			'error' {
				return error(Notification{
					title: 'Modrinth.${@FN} includes an error.'
					msg: responce_decoded.as_map().str()
				}.str())
			}
			'id' {
				mod.id = v.str()
			}
			'slug' {
				mod.slug = v.str()
			}
			'team' {} // Team ID. But there's no API request that utalizes team ID
			'title' {
				mod.name = v.str()
			}
			'description' {
				mod.description = v.str()
			}
			'body' {
				mod.description_full = v.str()
			}
			'body_url' {} // Never actualy utilized.
			'published' {
				mod.date_created = v.str()
			}
			'updated' {
				mod.date_modified = v.str()
			}
			'status' {} // Approved, pending, ect. Useful for mod authors.
			'license' {
				license := v.as_map()['id'] or { continue }.str()
				mod.license = license
			} // map[string]string | keys: id, name, url
			'client_side' {}
			'server_side' {}
			'downloads' {
				mod.downloads = v.int()
			}
			'followers' {} // int
			'categories' {} // []string
			'versions' {
				mod.versions = v.arr().map(ModVersion{
					id: it.str()
					platform: &p
					mod: &mod // Can I do this? while it's being built??
					is_incomplete: true
				})
			}
			'icon_url' {
				mod.icon_url = v.str()
			}
			'issues_url' {
				if v.str() != 'null' {
					mod.links['issues'] = v.str()
				}
			}
			'source_url' {
				if v.str() != 'null' {
					mod.links['source'] = v.str()
				}
			}
			'wiki_url' {
				if v.str() != 'null' {
					mod.links['wiki'] = v.str()
				}
			}
			'discord_url' {
				if v.str() != 'null' {
					mod.links['discord'] = v.str()
				}
			}
			'donation_urls' {
				for i in v.arr() {
					donation_platform_name := i.as_map()['platform'] or { continue }.str()
					donation_platform_url := i.as_map()['url'] or { '' }.str()
					mod.links[donation_platform_name] = donation_platform_url
				}
			}
			else {}
		}
	}

	// Modrinth does not provide game version info when geting a project by id.
	// TODO: Mesage modrinth api team about this behavior.
	// I think the mod object should include game_versions
	// without needing to make a second request for mod versions.

	// As a work arround, we'll make a second request for all versions, and then manualy build game afterwards.
	// TODO: to save time, start this request concurrently before the main mod request. change this line to a .wait() line.
	versions := p.get_versions_by_mod_id(mod.id) or { []ModVersion{} }
	mod.versions = versions // since we're here, might as well apply the versions list

	mod_game_versions_2d := versions.map(it.game_versions)
	mut mod_game_versions := []string{}
	for v_arr in mod_game_versions_2d {
		mod_game_versions.insert(0, v_arr.filter(it !in mod_game_versions))
	}
	mod_game_versions.sort(a > b)

	mod.game_versions = mod_game_versions

	mod.is_incomplete = false
	return mod
}

// get_mod_by_id: wrapper for GET 'https://api.modrinth.com/api/v1/mod/$mod_id/version'
// See also: ____
fn (p PlatformModrinth) get_versions_by_mod_id(mod_id string) ?[]ModVersion {
	mut config := http.FetchConfig{
		url: 'https://api.modrinth.com/api/v1/mod/$mod_id/version'
	}
	config.header.add(http.CommonHeader.authorization, p.auth_key)

	responce := http.fetch(config) or {
		return error(Notification{
			title: '${@FN} failed to fetch json'
			msg: err.msg
		}.str())
	}
	responce_decoded := json2.raw_decode(responce.text) or {
		return error(Notification{
			title: '${@FN} failed to decode json'
			msg: err.msg
		}.str())
	}

	parrent_mod := Mod{
		is_incomplete: true
		id: mod_id
		platform: &p
	}

	mut mod_versions := []ModVersion{}
	for version in responce_decoded.arr() {
		mut mod_version := ModVersion{
			is_incomplete: false
			mod: parrent_mod
			platform: &p
		}
		for k, v in version.as_map() {
			match k {
				'error' {
					return error(Notification{
						title: 'Modrinth.${@FN} includes an error.'
						msg: responce_decoded.as_map().str()
					}.str())
				}
				'id' {
					mod_version.id = v.str()
				}
				'mod_id' {} // Parrent mod handled in init statement
				'author_id' {} // currently: author stored w/ Mod
				'featured' {}
				'name' {
					mod_version.name = v.str()
				}
				'version_number' {
					mod_version.number = v.str()
				}
				'changelog' {
					mod_version.changelog = v.str()
				}
				'changelog_url' {} // like body_url, this isn't used anymore
				'date_published' {
					mod_version.date_published = v.str()
				} // 2021-03-07T00:22:03.038655Z
				'downloads' {
					mod_version.downloads = v.int()
				}
				'version_type' {
					mod_version.version_type = v.str()
				}
				'files' {
					mut files := []ModVersionFile{}
					for f in v.arr() {
						mut file := ModVersionFile{}
						for fk, fv in f.as_map() {
							match fk {
								'hashes' {
									mut hashes := map[string]string{}
									for hk, hv in fv.as_map() {
										hashes[hk] = hv.str()
									}
									file.hashes = hashes.move()
								}
								'url' {
									file.url = fv.str()
								}
								'filename' {
									file.filename = fv.str()
								}
								'primary' {}
								else {}
							}
						}
						files << file
					}
					mod_version.files = files
				}
				'dependencies' {
					mod_version.dependencies = v.arr().map(Mod{ id: it.str(), platform: &p })
				}
				'game_versions' {
					mod_version.game_versions = v.arr().map(it.str())
				}
				'loaders' {
					mod_version.loaders = v.arr().map(it.str())
				}
				else {}
			}
		}
		mod_versions << mod_version
	}
	return mod_versions
}

// get_version_by_id: wrapper for GET 'https://api.modrinth.com/v2/version/$version_id'
fn (p PlatformModrinth) get_version_by_id(version_id string) ?ModVersion {
	mut config := http.FetchConfig{
		url: 'https://api.modrinth.com/api/v1/mod/version/$version_id'
	}
	config.header.add(http.CommonHeader.authorization, p.auth_key)

	responce := http.fetch(config) or {
		return error(Notification{
			title: '${@FN} failed to fetch json'
			msg: err.msg
		}.str())
	}
	responce_decoded := json2.raw_decode(responce.text) or {
		return error(Notification{
			title: '${@FN} failed to decode json'
			msg: err.msg
		}.str())
	}

	mut version := ModVersion{
		is_incomplete: false
		platform: &p
		id: version_id
	}
	for k, v in responce_decoded.as_map() {
		match k {
			'error' {
				return error(Notification{
					title: 'Modrinth.${@FN} includes an error.'
					msg: responce_decoded.as_map().str()
				}.str())
			}
			'name' {
				version.name = v.str()
			}
			'version_number' {
				version.number = v.str()
			}
			'changelog' {
				version.changelog = v.str()
			}
			'changelog_url' {}
			'dependencies' {
				version.dependencies << Mod{
					id: v.str()
					platform: &p
				}
			}
			'game_versions' {
				version.game_versions << v.str()
			}
			'version_type' {
				version.version_type = v.str()
			}
			'loaders' {
				version.loaders << v.str()
			}
			'id' {
				version.id = v.str()
			}
			// 'project_id'		{}	// upgrade from mod_id in the future
			'mod_id' {
				version.mod = Mod{
					id: v.str()
					platform: &p
				}
			}
			'date_published' {
				version.date_published = v.str()
			}
			'downloads' {
				version.downloads = v.int()
			}
			'files' {
				mut files := []ModVersionFile{}
				for f in v.arr() {
					mut file := ModVersionFile{}
					for fk, fv in f.as_map() {
						match fk {
							'hashes' {
								mut hashes := map[string]string{}
								for hk, hv in fv.as_map() {
									hashes[hk] = hv.str()
								}
								file.hashes = hashes.move()
							}
							'url' {
								file.url = fv.str()
							}
							'filename' {
								file.filename = fv.str()
							}
							'primary' {}
							else {}
						}
					}
					files << file
				}
				version.files = files
			}
			else {}
		}
	}
	return version
}
