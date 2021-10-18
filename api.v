module mcpkg

import os
import x.json2

struct Api {
mut:
	mc_root_dir       string
	mc_mods_dir       string
	mcpkg_storage_dir string
	auth_keys_path    string
	config_path   		string
	mod_platforms 		map[string]ModPlatform
	auth_keys     		map[string]string
	// current_branch Branch
	// branches []Branch
	notifications			[]Notification
}

struct Notification {
	title   string
	msg     string
	urgency string = 'low' // "low", "med", "high"
}

pub fn (a Api) to_json() string {
	mut obj := map[string]json2.Any
	obj['mc_root_dir'] = a.mc_root_dir
	obj['mc_mods_dir'] = a.mc_mods_dir
	obj['mcpkg_storage_dir'] = a.mcpkg_storage_dir
	obj['auth_keys_path'] = a.auth_keys_path
	return obj.str()
}

pub fn (mut a Api) from_json(f json2.Any) {
	obj := f.as_map()
	for k, v in obj {
		match k {
			'mc_root_dir' {a.mc_root_dir = v.str()}
			'mc_mods_dir' {a.mc_mods_dir = v.str()}
			'mcpkg_storage_dir' {a.mcpkg_storage_dir = v.str()}
			'auth_keys_path' {a.auth_keys_path = v.str()}
			else {}
		}
	}
}

// load_api loads a configfile into an Api, or returns a default.
pub fn load_api(path string) Api {
	mut api := Api{}
	if path == 'tmp' {
		fake_mc_root := os.join_path(os.temp_dir(), 'mcpkg_fake_mc_root')
		api.mc_root_dir = fake_mc_root
		api.mc_mods_dir = os.join_path(fake_mc_root, 'mods')
		api.mcpkg_storage_dir = os.join_path(fake_mc_root, 'mcpkg')
		api.auth_keys_path = os.join_path(fake_mc_root, 'mcpkg', 'auth_keys.json')
	} else if path != '' {
		println('Loading config file at `${os.real_path(path)}`...')
		api_str := os.read_file(os.real_path(path)) or {
			panic('Failed to read a file at `${os.real_path(path)}`.\n$err')
		}
		api = json2.decode<Api>(api_str) or {
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

		api.mc_root_dir = os_default_mc_dir
		api.mc_mods_dir = os.join_path(os_default_mc_dir, 'mods')
		api.mcpkg_storage_dir = os.join_path(os_default_mc_dir, 'mcpkg')
		api.auth_keys_path = os.join_path(os_default_mc_dir, 'mcpkg', 'auth_keys.json')
	}

	// Generated data:

	// auth_keys
	if os.exists(os.real_path(api.auth_keys_path)) {
		auth_keys_json := os.read_file(os.real_path(api.auth_keys_path)) or { panic(err) }
		auth_keys_decoded := json2.raw_decode(auth_keys_json) or { panic(err) }
		for k, v in auth_keys_decoded.as_map() {
			api.auth_keys[k] = v.str()
		}
	} else if api.auth_keys_path != '' {
		panic( 'Path to auth file was given, but no file exists at $api.auth_keys_path' )
	}

	// branches
	// installed mods
	// etc...

	api.mod_platforms = api.load_mod_platforms()

	// println(api)
	return api
}

fn (n Notification) str() string {
	msg := if n.msg != '' {' >> $n.msg'} else {''}
	urg := if n.urgency != '' {'[$n.urgency] '} else {''}
	return urg + n.title + msg
}

pub fn err_msg_to_notification(err_msg string) Notification {
	urg := err_msg.find_between('[', '] ')
	title := err_msg.all_after('[$urg] ').all_before(' >> ')
	msg := err_msg.all_after(' >> ')
	return Notification{
		title: title
		msg: msg
		urgency: urg
	}
}
