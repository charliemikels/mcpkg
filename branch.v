module main

import os
import json
import mod_platforms as mp

struct BranchInfo {
	file_version		string = '0.1'
	branch_name			string
	game_versions 	[]string
	last_updated		string	// datetime?
	mod_queue				[]mp.Mod
	installed_mods	[]mp.Version
}

// fn create_example_local_list() {
// 	// Create struct
// 	// TODO: This is pretty close, but a lot was done by hand. Actualy download
// 	local_list := LocalModList{
// 		file_version: '0.0.0'
// 		mod_group: '1.16'
// 		last_updated: 'today'
// 		mods: [
// 			LocalMod{
// 				source: 'Modrinth'
// 				id: 'local-AANobbMI'
// 				name: 'Sodium'
// 				version: '0.1.0'
// 				game_version: '1.16.3'
// 				filename: 'sodium-fabric-mc1.16.3-0.1.0.jar'
// 			},
// 			LocalMod{
// 				source: 'Modrinth'
// 				id: 'local-P7dR8mSH'
// 				name: 'Fabric API'
// 				version: '0.30.0'
// 				game_version: '1.16'
// 				filename: 'fabric-api-0.30.0+1.16.jar'
// 			},
// 		]
// 	}
//
// 	// json and send to file
// 	mut file := os.create('./local_mod_list.json') or { panic(err) }
//
// 	file.write_string(json.encode_pretty(local_list)) or { return }
// }

// load_branch_info takes a path to a file and converts it to a BranchInfo
fn load_branch_info(path string) BranchInfo {
	// TODO: Check if mod_list_path exists, or if we need to create it?
	branch_info_string := os.read_file(path) or {
		eprintln('Failed to open the local mod list ${path}.')
		panic(err)
	}
	local_mod_list := json.decode(BranchInfo, branch_info_string) or {
		eprintln('Failed to decode modlist at $path to json.')
		panic(err)
	}
	return local_mod_list
}