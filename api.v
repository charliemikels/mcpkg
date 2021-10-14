module mcpkg

import os
import json

struct ApiJson {
	mc_root_dir       string
	mc_mods_dir       string
	mcpkg_storage_dir string
	auth_keys_path 		string
}

pub struct Api {
	ApiJson
mut:
	config_path   string
	mod_platforms map[string]ModPlatform
	auth_keys 		map[string]string
	// current_branch Branch
	// branches []Branch
}

// load_api loads a configfile into an Api, or returns a default.
pub fn load_api(path string) Api {
	mut api_json := ApiJson{}

	if path == 'tmp' {
		// special case
		fake_mc_root := os.join_path(os.temp_dir(), 'mcpkg_fake_mc_root')
		api_json = ApiJson{
			mc_root_dir: fake_mc_root
			mc_mods_dir: os.join_path(fake_mc_root, 'mods')
			mcpkg_storage_dir: os.join_path(fake_mc_root, 'mcpkg')
			auth_keys_path: os.join_path(fake_mc_root, 'mcpkg', 'auth_keys.json')
		}
	} else if path != '' {
		println('Loading config file at `${os.real_path(path)}`...')
		api_str := os.read_file(os.real_path(path)) or {
			panic('Failed to read a file at `${os.real_path(path)}`.\n$err')
		}
		api_json = json.decode(ApiJson, api_str) or {
			panic('Failed to decode json at `${os.real_path(path)}`.\n$err')
		}
	} else {
		// No config given, create default json info
		os_default_mc_dir := match os.user_os() {
			'windows' { os.join_path('%appdata%', '.minecraft') } // QUESTION: Might not work? intended for win+R shortcut.
			'macos' { os.join_path(os.home_dir(), 'Library', 'Application Support', 'minecraft') }
			'linux' { os.join_path(os.home_dir(), '.minecraft') }
			else { os.join_path(os.home_dir(), '.minecraft') }
		}

		api_json = ApiJson{
			mc_root_dir: 			 os_default_mc_dir
			mc_mods_dir: 			 os.join_path(os_default_mc_dir, 'mods')
			mcpkg_storage_dir: os.join_path(os_default_mc_dir, 'mcpkg')
			auth_keys_path: 	 os.join_path(os_default_mc_dir, 'mcpkg', 'auth_keys.json')
		}
	}

	mut api := Api{
		ApiJson: api_json
		config_path: path
	}
	// Figure out other resources here
	// current_branch, mod files, etc...

	// TODO: load from file!
	auth_keys := {
		'one': 'red'
		'two': 'blue'
		'modrinth': '1234567890'
	}

	api.auth_keys = auth_keys.clone()

	api.mod_platforms = api.load_mod_platforms()

	println(api)
	return api
}
