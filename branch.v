module mcpkg

import os
import x.json2

struct Branch {
mut:
	id					 int
	name         string
	game_version string
	// mods []Mod
	installed_versions []ModVersion
	upgrade_backlog    []Mod // When upgrading a branch, Mods that don't have a valid version yet will be stored here.
	// locked_versions ModVersion[]
}

// File structure
// MC mods dir
//		mod_1.jar
//		mod_N.jar
// mcpkg storage
//		config.json	// may or may not actualy liv here.
//		branches.json	// branches always live in mcpkg_storage
//		mod_cache
//			old_mod_1.jar
//			old_mod_N.jar

const branches_file_name = 'branches.json'

struct BranchConfig {
	game_version string [required]
	name string
	make_current bool
}

fn (mut a Api) next_branch_id() int {
	mut counter := 0
	for {
		if counter in a.branches.keys() { counter++ }
		else {
			return counter
		}
	}
	panic('exeted the loop without hitting the return. somehow...')
}

pub fn (mut a Api) new_branch(c BranchConfig) Branch {
	b := Branch {
		id: a.next_branch_id()
		game_version: c.game_version
		name: if c.name == '' {c.game_version} else {c.name}
	}

	a.branches[b.id] = b
	if c.make_current {
		// a.set_current_branch(b.id)
		panic('make_current not built yet')
	}
	return b
}

// fn (b Branch) to_json() string {
// 	json_map := map[string]json2.Any{}
// 	json_map['name']               = b.name
// 	json_map['game_version']       = b.game_version
// 	// json_map['mods']               = b.mods.map(it.to_json())
// 	// json_map['installed_versions'] = b.installed_versions.map(it.to_json())
// 	// json_map['upgrade_backlog']    = b.upgrade_backlog.map(it.to_json())
// }

fn (mut a Api) json_to_branch(json json2.Any) Branch {
	mut branch := Branch{}
	for k, v in json.as_map() {
		match k {
			'id'	 { branch.id = v.int() }
			'name' { branch.name = v.str() }
			'game_version' { branch.game_version = v.str() }
			'installed_versions' { branch.installed_versions = v.arr().map(a.json_to_mod_version(it)) }
			'upgrade_backlog' { branch.upgrade_backlog = v.arr().map(a.json_to_mod(it)) }
			else {}
		}
	}
	return branch
}

// load_branches attempts to load data from a json file in mcpkg_storage into Api
pub fn (mut a Api) load_branches() {
	branches_path := os.join_path(a.mcpkg_storage_dir, branches_file_name)
	branches_str := os.read_file(branches_path) or {
		a.notifications << new_alert('high', 'branch.json not found', err.msg)
		// TODO: Create blank file?
		return
	}
	branches_json := json2.raw_decode(branches_str) or {
		a.notifications << new_alert('high', 'Failed to parse branch.json into json', err.msg)
		return
	}

	mut current_branch_id := -1
	mut branches := []Branch{}
	for k, v in branches_json.as_map() {
		match k {
			'current_branch' { current_branch_id = v.int() }
			'branches' {
				for b in v.arr() {
					branches << a.json_to_branch(b)
				}
			}
			else {}
		}
	}

	mut branch_id_counter := 0
	for i, mut b in branches {
		b.id = i
		a.branches[b.id] = b
	}


	if current_branch_id !in a.branches.keys() {
		panic('the given current_branch_id ($current_branch_id) was not found in the map of branches.')
		// TODO: convert to notification, and create a system to handle this err
	}
	else {
		a.current_branch_id = current_branch_id
	}
}

// fn (mut a Api) set_current_branch(branch_key string) {
// 	eprintln('${@FN} not implemented yet!')
//	swaps the current branch + mod files with another branch.
// }

pub fn (a Api) save_branches() {
	path := os.join_path(a.mcpkg_storage_dir, branches_file_name)
	panic('save_branches not built yet!')

	// {
	// 	current_branch: branch_c.name
	// 	branches: [{branch_1},{branch_2},{branch_n}]
	// }
}

//	vv Do we need this FN? vv
// pub fn (mut a Api) save_branch(b Branch) {
// 	path := os.join_path(a.mcpkg_storage_dir, 'branches', 'branch_${b.safe_name()}.json' )
//
// 	if os.exists(os.dir(path)) == false {
// 		os.mkdir_all(os.dir(path)) or { panic(err) }	// TODO: notification
// 	}
// 	json_str := b.to_json()
// 	os.write_file(path, json_str) or { panic(err) }
// }
//
// pub fn (mut a Api) save_current_branch() {
// 	save_branch(a.current_branch)
// }

// a.clean_mod_cache() // Search every branch. if a mod in cache isn't needed by any branch, remove it.
// a.wipe_mod_cache()  // Delete contents of mod_cache
