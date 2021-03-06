module mcpkg

import os
import x.json2

struct Api {
mut:
	mc_root_dir       string
	mc_mods_dir       string
	mcpkg_storage_dir string
	auth_keys_path    string
	config_path       string
	mod_platforms     map[string]ModPlatform
	auth_keys         map[string]string
	current_branch_id int
	branches          map[int]Branch
	game_versions     []GameVersion
	alerts            []Alert
}

struct Alert {
	title   string
	msg     string
	urgency string = 'low' // "low", "med", "high"
	// actions []Action
}

// struct Action {
// 	title string
// 	description string
// 	function fn()
// }

// for use with json2.encode
pub fn (a Api) to_json() string {
	mut obj := map[string]json2.Any{}
	obj['mc_root_dir'] = a.mc_root_dir
	obj['mc_mods_dir'] = a.mc_mods_dir
	obj['mcpkg_storage_dir'] = a.mcpkg_storage_dir
	obj['auth_keys_path'] = a.auth_keys_path
	return obj.str()
}

// for use with json2.decode
pub fn (mut a Api) from_json(f json2.Any) {
	obj := f.as_map()
	for k, v in obj {
		match k {
			'mc_root_dir' { a.mc_root_dir = v.str() }
			'mc_mods_dir' { a.mc_mods_dir = v.str() }
			'mcpkg_storage_dir' { a.mcpkg_storage_dir = v.str() }
			'auth_keys_path' { a.auth_keys_path = v.str() }
			else {}
		}
	}
}

// new_api returns a default Api struct. These can be over written by load_config_file and initilize.
pub fn new_api() Api {
	os_default_mc_dir := match os.user_os() {
		'windows' { os.join_path('%appdata%', '.minecraft') } // QUESTION: Might not work? intended for win+R shortcut.
		'macos' { os.join_path(os.home_dir(), 'Library', 'Application Support', 'minecraft') }
		'linux' { os.join_path(os.home_dir(), '.minecraft') }
		else { os.join_path(os.home_dir(), '.minecraft') }
	}

	return Api{
		mc_root_dir: os_default_mc_dir
		mc_mods_dir: os.join_path(os_default_mc_dir, 'mods')
		mcpkg_storage_dir: os.join_path(os_default_mc_dir, 'mcpkg')
		auth_keys_path: os.join_path(os_default_mc_dir, 'mcpkg', 'auth_keys.json')
	}
}

// load_config_file modifies an api based on a config.json file at `path`
pub fn (mut a Api) load_config_file(path string) {
	println('Loading config file at `${os.real_path(path)}`...')
	api_str := os.read_file(os.real_path(path)) or {
		a.new_alert('high', '${@FN} failed to read a file at `${os.real_path(path)}`.',
			err.msg)
		return
	}
	api_decoded := json2.raw_decode(api_str) or {
		a.new_alert('high', '${@FN} failed to decode json at `${os.real_path(path)}`.',
			err.msg)
		return
	}
	a.config_path = path
	for k, v in api_decoded.as_map() {
		match k.str() {
			'mc_root_dir' { a.mc_root_dir = v.str() }
			'mc_mods_dir' { a.mc_mods_dir = v.str() }
			'mcpkg_storage_dir' { a.mcpkg_storage_dir = v.str() }
			'auth_keys_path' { a.auth_keys_path = v.str() }
			else {}
		}
	}
}

// save_config_file writes the current api to a file at `path`. If path is `''`, use api.config_path.
pub fn (mut a Api) save_config_file(path string) {
	mut p := if path != '' {
		path
	} else {
		if os.is_dir(a.config_path) {
			os.join_path(a.config_path, 'config.json')
		} else {
			a.config_path
		}
	}
	println('Writing config file to `$p`')
	panic('TODO: api.save_config_file() is not implemented yet!!!')
}

// initialize populates the rest of the api using the basic source paths
pub fn (mut a Api) initialize() {
	// Test dir validity
	a.load_auth_keys()
	a.load_mod_platforms()
	a.load_branches()
	// TODO: check un-tracked filenames in minecraft/mods/ (add to branch?)

	// Don't initilize []game_versions. see api.get_game_versions()
}

fn (mut a Api) load_auth_keys() {
	// TODO: update to alerts
	if os.exists(os.real_path(a.auth_keys_path)) {
		auth_keys_json := os.read_file(os.real_path(a.auth_keys_path)) or { panic(err) }
		auth_keys_decoded := json2.raw_decode(auth_keys_json) or { panic(err) }
		for k, v in auth_keys_decoded.as_map() {
			a.auth_keys[k] = v.str()
		}
	} else if a.auth_keys_path != '' {
		eprintln('Path to auth file was given, but no file exists at $a.auth_keys_path')
	}
}

pub fn (mut a Api) get_game_versions() []GameVersion {
	if a.game_versions == [] {
		a.game_versions << a.get_remote_game_versions()
	}
	return a.game_versions
}

pub fn (a Api) get_alerts() []Alert {
	return a.alerts
}

fn (n Alert) str() string {
	msg := if n.msg != '' { ' >> $n.msg' } else { '' }
	urg := if n.urgency != '' { '[$n.urgency] ' } else { '' }
	return urg + n.title + msg
}

pub fn err_msg_to_alert(err_msg string) Alert {
	urg := err_msg.find_between('[', '] ')
	title := err_msg.all_after('[$urg] ').all_before(' >> ')
	msg := err_msg.all_after(' >> ')
	return Alert{
		title: title
		msg: msg
		urgency: urg
	}
}

// Shorthand to generate new alerts rather than the full Alert {.. .. ..} syntax
fn new_alert(level string, title string, msg string) Alert {
	// level = quiet/log, notif(ication)/alert, warn/error
	return Alert{
		title: title
		msg: msg
		urgency: level
	}
}

// Shorthand to generate new alerts
fn (mut a Api) new_alert(level string, title string, msg string) {
	a.alerts << new_alert(level, title, msg)
}

// fn new_alert_from_string
// fn alert_to_string
