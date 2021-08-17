module main

import os
import json
import mod_platforms as mp

const branch_file_name = 'branch_info.json'

// HACK: Struct embedning to save json
struct Branch {
	BranchJson // mut:
	// is_current 		 bool 	// [skip]
}

struct BranchJson {
pub mut:
	name           string = 'NO_BRANCH_NAME'
	file_version   string = '0.1'
	game_versions  []string
	last_updated   string       // datetime?	// The date/time that we last checked for updates.
	installed_mods []mp.Version // Installed mods files.
	locked_mods    []mp.Version // Installed mods, but these mods will not be automaticaly updated
	disabled_mods  []mp.Mod     // Mods that were removed, but not fully deleted yet. Handy for quickly testing some things, but switching branches is a better long term move.
	mod_queue      []mp.Mod     // Mods that haven't been upgraded yet. As soon as these mods are available for the current GameVersion, Install them.
}

// branch_dir returns the path to a branch's root dir.
fn (a App) branch_dir(name string) string {
	return a.config_dir + 'branches/' + name + '/' // TODO: better path building for windows?
}

struct BranchConfig {
	name          string   = 'NO_BRANCH_NAME'
	game_versions []string = []
	set_current   bool //		= false
}

// new_branch creates a new branch. It also saves the branch to a file
fn (mut a App) new_branch(bc BranchConfig) Branch {
	// TODO: Varify if the version list is a list of valid versions. See https://api.modrinth.com/api/v1/tag/game_version
	mut gv := []string{}
	for v in bc.game_versions {
		gv << v
	}
	// we need game versions. If we have none, let's use the latest release
	if gv == [] {
		lr := get_latest_release().name
		println('Using latest release: $lr')
		gv << lr
	}
	new_branch := Branch{
		name: bc.name
		game_versions: gv // TODO: Sort? not needed but might be pretty in the json
		// is_current: bc.set_as_current
	}

	a.save_branch(new_branch)
	return new_branch
}

fn (mut a App) new_branch_wizard() Branch {
	// TODO: new_branch_wizard
	// Ask the user questions to build BranchConfig
	println('TODO: new_branch_wizard()')
	config := BranchConfig{
		name: 'TODO__new_branch_wizard'
		game_versions: [get_latest_release().name]
		set_current: true
	}
	my_branch := a.new_branch(config)
	if config.set_current == true {
		a.change_branch(my_branch.name) or { panic(err) }
	}
	return my_branch
}

// save_branch writes/re-writes a branch to it's file.
fn (a App) save_branch(b Branch) {
	branch_backup_max := 3 // TODO: move max backup to App? (To const in helper.v??)
	branch_path := a.branch_dir(b.name) + branch_file_name
	if !os.exists(os.dir(branch_path)) {
		os.mkdir_all(os.dir(branch_path)) or { panic(err) }
	}
	if os.exists(branch_path) {
		backup_file(branch_path, branch_backup_max)
	}

	mut branch_file := os.create(branch_path) or { panic(err) }
	defer {
		branch_file.close()
	}
	branch_file.write_string(json.encode_pretty(b.BranchJson)) or { panic(err) }
}

fn (a App) list_branches() []string {
	mut branch_names := []string{}
	branch_dir_path := a.config_dir + 'branches/'
	if !os.exists(branch_dir_path) {
		return branch_names
	}
	items := os.ls(branch_dir_path) or { panic(err) }
	for i in items {
		// println('checking ${branch_dir_path+i+'/'+branch_file_name}')
		if os.exists(branch_dir_path + i + '/' + branch_file_name) {
			branch_names << i
		}
	}

	return branch_names
}

// change_branch deactivates the current branch and sets "new_branch_name" to the current branch
fn (mut a App) change_branch(new_branch_name string) ? {
	if new_branch_name !in a.list_branches() {
		return error('no branch `$new_branch_name`.')
	}

	// a.deactivate_branch(a.current_branch)
	a.save_branch(a.current_branch)

	// swap mod folders to their home
	mc_mods_dir := a.mc_dir + 'mods/'
	old_b_mods_dir := a.branch_dir(a.current_branch.name) + 'mods/'
	new_b_mods_dir := a.branch_dir(new_branch_name) + 'mods/'
	// We should be cool to rm this directory sice we're about to replace it with the existing mods again anyways.
	if os.exists(old_b_mods_dir) {
		os.rmdir_all(old_b_mods_dir) or { panic(err) }
	}
	if os.exists(mc_mods_dir) {
		os.mv(mc_mods_dir, old_b_mods_dir) or { panic(err) }
	}
	// on the off chance the branch exists, but mods/ doesn't, don't try to move it.
	if os.exists(new_b_mods_dir) {
		os.mv(new_b_mods_dir, mc_mods_dir) or { panic(err) }
	} else {
		os.mkdir(mc_mods_dir) or { panic(err) }
	}

	// Finaly...
	a.current_branch = a.read_branch(new_branch_name) or { panic(err) }
	a.save_config()
}

// read_branch is a wrapper for read_branch_file. Takes the name of a branch and returns the full branch struct.
fn (a App) read_branch(name string) ?Branch {
	branch_dir := a.branch_dir(name)
	expected_file_path := branch_dir + branch_file_name
	return read_branch_file(expected_file_path)
}

// read_branch_file is it's own function so we can bundle os.read and json.decode into one error
fn read_branch_file(path string) ?Branch {
	if !os.exists(path) {
		return error('`$path` does not exist.')
	}
	branch_json := os.read_file(path) or { return error('Issue reading file at `$path`') }
	branch_json_struct := json.decode(BranchJson, branch_json) or {
		return error('Issue decoding file at `$path`')
	}
	if branch_json_struct.game_versions == [] {
		return error('No game versions found when importing `$path`. Something might be wrong with this file.')
	}
	return Branch{
		BranchJson: branch_json_struct
	}
}

// load_current_branch takes the name of a branch and sets it as the current branch.
// This is used on app init. Use activate_branch() to set a new branch.
fn (mut a App) load_current_branch() ? {
	a.current_branch = a.read_branch(a.current_branch_name) or { return err }
}
