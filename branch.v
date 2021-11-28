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

// syncronize_local_files TODO: Docs for syncronize_local_files
pub fn (mut a Api) syncronize_local_files() {
	// get list of file names required by installed mods in new branch
	// move any mod that is not in the list to mod_cache
	// move any mod that is in cache and in the list to mods dir
	// check if all mods in "installed mods" is present.
	// If yes, we're done.
	// If not, we're missing mods. Ask user to re-download their mods with their platforms.
	// If this process fails, ask user to re-sync branch files.
	// Actualy this whole logic block should go into it's own syncronize_files fn
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
	// TODO: prevent from attempting to download already installed mods

	println('Installing mod $mod.name')

	ver := a.get_mod_version_for_current_branch(mod) or {
		println(a.notifications)
		return
	}

	paths_to_move := a.download_mod_version(ver)

	// TODO: replace this section with syncronize_files() after adding ver to branch?
	mut finished_paths := []string{}
	for path in paths_to_move {
		target_path := os.join_path(a.mc_mods_dir, os.file_name(path))
		os.mv(path, target_path) or {
			a.notifications << new_alert('high', 'Failed to move file ${os.file_name(path)} to the mods dir.',
				err.msg)
			if finished_paths.len > 0 {
				a.notifications << new_alert('med', 'Resetting attempted downloads', 'moving $finished_paths back to mod cache...')
				for paths_to_reset in finished_paths {
					reset_target_path := os.join_path(mcpkg.mod_cache_dir_name, os.file_name(paths_to_reset))
					os.mv(paths_to_reset, reset_target_path) or {
						a.notifications << new_alert('high', 'Failed to move file ${os.file_name(paths_to_reset)} back to the cache dir!',
							err.msg)
					}
				}
			}
			return
		}
		finished_paths << target_path
	}

	a.branches[a.current_branch_id].installed_versions << ver

	a.save_branches()

	println('Successfuly installed $mod.name ($ver.name). \nFiles: $finished_paths')
}

// fn lock_mod(mod Mod) {} // if given mod is installed, move to branche's "locked mods"
// fn unlock_mod(mod Mod) {}
