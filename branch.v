module mcpkg

import os
import x.json2
import json
import net.http

struct Branch {
mut:
	id                 int
	name               string
	game_version       string
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

// vv Move to Api? (a.paths[mod_cache]) vv
const mod_cache_dir_name = 'mod_cache'

pub struct BranchConfig {
	game_version string [required]
	name         string
	make_current bool
}

pub fn (mut a Api) new_branch(c BranchConfig) Branch {
	b := Branch{
		id: a.next_branch_id()
		game_version: c.game_version
		name: if c.name == '' { c.game_version } else { c.name }
	}

	a.branches[b.id] = b
	if c.make_current {
		a.set_current_branch(b.id)
	} else {
		a.save_branches()
	}
	return b
}

fn (b Branch) get_required_mod_versions() []ModVersion {
	return b.installed_versions // TODO: + b.locked_versions // Question: Include dependencies?
}

fn (b Branch) get_required_mods() []Mod {
	return b.get_required_mod_versions().map(it.mod)
}

// get_required_file_names is a shortcut to get every file name required by a branch
fn (b Branch) get_required_file_names() []string {
	required_mod_versions := b.get_required_mod_versions()
	// required_mod_version_files := required_mod_versions.map(it.files)	// Actualy returns [][]ModVersionFile ([[file1],[file2],[file3]])
	// required_mod_version_file_names := required_mod_version_files.map(it.map(it.filename)) // Actualy returns [][]string ([[file1],[file2],[file3]])

	mut required_file_names := []string{}
	for mod_ver in required_mod_versions {
		for mod_ver_file in mod_ver.files {
			required_file_names << mod_ver_file.filename
		}
	}

	return required_file_names
}

fn (mut a Api) next_branch_id() int {
	mut counter := 0
	for {
		if counter in a.branches.keys() {
			counter++
		} else {
			return counter
		}
	}
	panic('exeted the loop without hitting the return. somehow...')
}

fn (b Branch) to_json() json2.Any {
	mut json_map := map[string]json2.Any{}
	json_map['id'] = b.id
	json_map['name'] = b.name
	json_map['game_version'] = b.game_version
	json_map['installed_versions'] = b.installed_versions.map(it.to_json())
	// json_map['upgrade_backlog']    = b.upgrade_backlog.map(it.to_json())
	return json_map
}

fn (mut a Api) json_to_branch(json json2.Any) Branch {
	mut branch := Branch{}
	for k, v in json.as_map() {
		match k {
			'id' { branch.id = v.int() }
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
	branches_path := os.join_path(a.mcpkg_storage_dir, mcpkg.branches_file_name)
	branches_str := os.read_file(branches_path) or {
		a.notifications << new_alert('high', 'branch.json not found', err.msg)
		// TODO: Create blank file?
		return
	}
	branches_json := json2.raw_decode(branches_str) or {
		a.notifications << new_alert('high', 'Failed to parse branch.json into json',
			err.msg)
		return
	}

	mut current_branch_id := -1
	mut branches := []Branch{}
	for k, v in branches_json.as_map() {
		match k {
			'current_branch_id' {
				current_branch_id = v.int()
			}
			'branches' {
				for b in v.arr() {
					branches << a.json_to_branch(b)
				}
			}
			else {}
		}
	}

	for i, mut b in branches {
		b.id = i
		a.branches[b.id] = b
	}

	if current_branch_id !in a.branches.keys() {
		panic('the given current_branch_id ($current_branch_id) was not found in the map of branches.')
		// TODO: convert to notification, and create a system to handle this err
		a.current_branch_id = -1
	} else {
		a.current_branch_id = current_branch_id
	}
}

pub fn (mut a Api) set_current_branch(branch_id int) {
	// swaps the current branch + mod files with another branch.
	old_current_branch_id := a.current_branch_id
	if branch_id in a.branches.keys() {
		a.current_branch_id = branch_id
	}
	a.save_branches()
	a.syncronize_local_files()
}

pub fn (a Api) save_branches() {
	mut branches_arr := []Branch{}
	for _, b in a.branches {
		branches_arr << b
	}

	mut json_map := map[string]json2.Any{}
	json_map['current_branch_id'] = a.current_branch_id
	json_map['branches'] = branches_arr.map(it.to_json())
	json_str := json_map.str()
	println("We'll try to save this json string: $json_str")

	path := os.join_path(a.mcpkg_storage_dir, mcpkg.branches_file_name)
	os.write_file(path, json_str) or {
		eprintln('save_branches panic!')
		panic(err)
	}
}

// syncronize_local_files moves all files not required by the current branch from the mods_dir to mods_cache,
// and moves all required files found in mod_cache to mods_dir.
// TODO: Also create syncronize_remote_files?
pub fn (mut a Api) syncronize_local_files() {
	// TODO: a lot of panic() calls. upgrade safely handle
	if !os.exists(os.join_path(a.mcpkg_storage_dir, mcpkg.mod_cache_dir_name)) {
		os.mkdir(os.join_path(a.mcpkg_storage_dir, mcpkg.mod_cache_dir_name)) or { panic(err) }
	}

	required_files := a.branches[a.current_branch_id].get_required_file_names()

	files_in_mods_dir := os.ls(a.mc_mods_dir) or { panic(err) }
	non_required_files_in_mods_dir := files_in_mods_dir.filter(!required_files.contains(it))

	files_in_cache := os.ls(os.join_path(a.mcpkg_storage_dir, mcpkg.mod_cache_dir_name)) or {
		panic(err)
	}
	required_files_in_cache := files_in_cache.filter(required_files.contains(it)
		&& !files_in_mods_dir.contains(it))

	for file_name in non_required_files_in_mods_dir {
		os.mv(os.join_path(a.mc_mods_dir, file_name), os.join_path(a.mcpkg_storage_dir,
			mcpkg.mod_cache_dir_name, file_name)) or { panic(err) }
	}

	for file_name in required_files_in_cache {
		os.mv(os.join_path(a.mcpkg_storage_dir, mcpkg.mod_cache_dir_name, file_name),
			os.join_path(a.mc_mods_dir, file_name)) or { panic(err) }
	}
}

// fn (a Api) check_for_missing_mods() []ModVersion {
// 	required_file_names := a.branches[a.current_branch_id].get_required_file_names()
//
// 	files_in_mods_dir := os.ls(a.mc_mods_dir) or { panic(err) }
// 	mut missing_file_names :=
//
// 	for filename in required_file_names {
// 		if !( filename in files_in_mods_dir ) {
// 			missing_versions << filename
// 		}
// 	}
//
// 	mut missing_versions := []ModVersion{}
// 	return missing_versions
// }

// a.clean_mod_cache() // Search every branch. if a mod in cache isn't needed by any branch, remove it.
// a.wipe_mod_cache()  // Delete contents of mod_cache

fn (mut a Api) download_mod_version(ver ModVersion) []string {
	mod_version := if ver.is_incomplete { a.get_full_version(ver) } else { ver }

	download_dir := os.join_path(a.mcpkg_storage_dir, mcpkg.mod_cache_dir_name)
	if !os.exists(download_dir) {
		os.mkdir(download_dir) or {
			a.notifications << new_alert('high', 'Failed to create cache dir', err.msg)
			return []string{}
		}
	}

	mut downloaded_file_paths := []string{}
	for file in mod_version.files {
		file_path := os.join_path(download_dir, file.filename)
		if os.exists(file_path) {
			a.notifications << new_alert('low', 'Skipping unnessesary download', 'File `$file.filename` already exists in `$download_dir`.')
		} else {
			http.download_file(file.url, file_path) or {
				a.notifications << new_alert('high', 'Failed to download $file.filename',
					err.msg)
				continue
			}
		}
		downloaded_file_paths << file_path
	}
	println(a.notifications)
	return downloaded_file_paths
}

fn (mut a Api) get_mod_version_for_current_branch(m Mod) ?ModVersion {
	mod := if m.is_incomplete { a.get_full_mod(m) } else { m }

	current_branch := a.branches[a.current_branch_id]

	all_versions := a.get_mod_versions(mod)
	mut compatable_versions := all_versions.filter(it.game_versions.contains(current_branch.game_version))
	if compatable_versions.len == 0 {
		return error(new_alert('med', 'Failed to find a ModVersion for current branch.',
			'None of the versions support the branch\'s game version `$current_branch.game_version`.').str())
	}

	compatable_versions.sort(a.date_published > b.date_published) // Likely a redundant step
	latest_compatable_version := compatable_versions[0]
	return latest_compatable_version
}

// install_mod trys to install a mod for the current game branch.
// It finds the correct ModVersion, adds version to the branch,
// Downloads the relevent files, put them in the mod folder,
// and finaly write the changes to the branches file.
pub fn (mut a Api) install_mod(mod Mod) {
	if mod.id in a.branches[a.current_branch_id].get_required_mods().map(it.id) {
		a.notifications << new_alert('med', 'Mod `$mod.name` ($mod.id) is already installed.',
			'Checking for updates...')
		// TODO: implement check for updates
		return
	}

	println('Installing mod $mod.name')
	ver := a.get_mod_version_for_current_branch(mod) or {
		println(a.notifications)
		return
	}

	paths_to_move := a.download_mod_version(ver)

	a.syncronize_local_files()

	a.branches[a.current_branch_id].installed_versions << ver

	a.save_branches()

	println('Successfuly installed $mod.name ($ver.name).')
}

// fn lock_mod(mod Mod) {} // if given mod is installed, move to branche's "locked mods"
// fn unlock_mod(mod Mod) {}
