module mcpkg

import net.http

// load into api instead
// const game_versions = get_mc_versions()
//
// const game_version_map = versions_to_map(game_versions)

struct GameVersion {
	index int
	name  string
	// series string	// 1.17, 1.16, 1.15 ...
	kind string // release, snapshot, experamental, alpha, beta, infdev
	// next							&GameVersion // version newer than this
	// previous					&GameVersion // version older than this
	// next_release			&GameVersion // version newer than this
	// previous_release	&GameVersion // version older than this
}

// fn (gv GameVersion) str() string {
// 	return gv.name
// }

// get_mc_versions returns a full list of every version of Minecraft in order.
// In reality it gets every version tag from Modrinth, but it works pretty well.
fn (mut a Api) get_remote_game_versions() []GameVersion {
	config := http.FetchConfig{
		url: 'https://api.modrinth.com/api/v1/tag/game_version'
	}
	responce := http.fetch(config) or {
		a.notifications << new_alert('high', 'HTTP fetch failed', 'Could not connect to `$config.url`.')
		return []
	}
	// responce is a json array.
	versions := responce.text.after('[').before(']').replace('"', '').split(',')

	mut version_list := []GameVersion{}
	for i, v in versions {
		version_list << GameVersion{
			index: i
			name: v
			kind: if is_release(v) {
				'release'
			} else if v.contains('w') || v.to_lower().contains('pre') || v.contains('rc') {
				'snapshot'
			} else if v[0] == `b` {
				'beta'
			} else if v[0] == `a` {
				'alpha'
			} else if v[0] == `i` {
				'infdev'
			} else if v[0] == `c` {
				'c'
			} else if v[0] == `r` {
				'rd'
			} else {
				a.notifications << new_alert('low', 'Version type parser failed', 'Could not parse the version type of version `$v` (#$i).')
				'other'
			}
		}
	}

	return version_list
}

fn versions_to_map(versions []GameVersion) map[string]GameVersion {
	mut version_map := map[string]GameVersion{}
	for v in versions {
		version_map[v.name] = v
	}
	return version_map
}

// is_release checks to see if a game version is a release or a snapshot.
// This assumes every release number looks like #.##.#, and every snapshot
// or pre-release has at least one extra character, like letters or dashes.
fn is_release(version string) bool {
	// HACK: We are cheesing the behavior of `.int()` pretty good. (it stops at the first non-number, or returns 0). An `is_int()` method would still be better.
	return version.replace('.', '').int().str() == version.replace('.', '')
}

// fn next_version(current_version GameVersion) ?GameVersion {
// 	return game_versions[current_version.index - 1] or { return error('at latest version') }
// }

// fn previous_version(current_version GameVersion) ?GameVersion {
// 	return game_versions[current_version.index + 1] or { return error('at oldest version') }
// }

// fn next_release(current_version GameVersion) ?GameVersion {
// 	// There's a better way to do this, but we shouldn't need to run this too often anyways...
// 	mut nv := next_version(current_version) ?
// 	for nv.kind != 'release' {
// 		nv = next_version(nv) or { return error('no newer releases') }
// 	}
// 	return nv
// }

// fn previous_release(current_version GameVersion) ?GameVersion {
// 	// There's a better way to do this, but we shouldn't need to run this too often anyways...
// 	mut pv := previous_version(current_version) ?
// 	for pv.kind != 'release' {
// 		pv = previous_version(pv) or { return error('No older releases.') }
// 	}
// 	return pv
// }

// fn get_latest_release() GameVersion {
// 	mut r := game_versions[0]
// 	if r.kind != 'release' {
// 		r = previous_release(r) or {
// 			panic('get_latest_release() failed. Was game_versions successfuly created?')
// 		}
// 	}
// 	return r
// }
