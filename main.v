module main

// import net
// import net.http
// import net.html
// import json
import os
import os.cmdline
import mod_platforms as mp

// use https://api.modrinth.com/api/v1/tag/game_version to get a list of game versions in order.
// IDEA: Use this to compare if a game version is newer or older than others.

// AppConfig: Core app settings
struct AppConfig {
	mod_dir string
}

// BranchConfig: Settings related to a mod branch
// struct BranchConfig {
// 	game_versions []string
// }

// fn process_settings() AppConfig {
// 	os_default_path := $if linux {
// 		'~/.minecraft/mods'
// 	} $else $if macos {
// 		'~/Library/Application Support/minecraft/mods'
// 	} $else $if windows {
// 		'%appdata%\\.minecraft\\mods' // Might not work, intended for win+R shortcut
// 	} $else {
// 		''
// 	}
//
// 	return AppConfig {
// 	}
// }

fn get_config() ?AppConfig {
	// some defaults
	config_file_name := 'mcpkg_config.json'

	default_mc_dir := $if linux {
		'${os.home_dir()}/.minecraft/'
	} $else $if macos {
		'${os.home_dir()}/Library/Application Support/minecraft/'
	} $else $if windows {
		'%appdata%/.minecraft/' // QUESTION: Might not work, intended for win+R shortcut. Also, / is usualy \
	} $else {
		''
	}
	default_mc_mod_dir := 'mods/'

	// If user gave -c, try to use that
	arg_path := cmdline.option(os.args, '-c', '')
	if arg_path != '' {
		// check if path goes to a file.
		if os.is_file(arg_path) {
			return process_config( arg_path )
		}
		// Path isn't a file, maybe it's a directory
		else if os.is_dir(arg_path) {
			// Look for default config file.
			// check if there's a trailing /
			if arg_path.ends_with('/') || arg_path.ends_with('\\'){
				if os.is_file(arg_path + config_file_name) { return process_config( arg_path + config_file_name ) }
				else {
					eprintln('no file found in `$arg_path`')
					return create_config( arg_path + config_file_name )
				}
			}
			// no trailing /
			else {
				if os.is_file(arg_path + '/' + config_file_name) { return process_config( arg_path + '/' + config_file_name ) }
				else {
					eprintln('no file found in `$arg_path`')
					return create_config( arg_path + '/' + config_file_name )
				}
			}
		} // end is_dir()

		// Path isn't a file, or a directory. Maybe it's trying to create a file?
		// Last chance: Check if arg_path is trying to be a file.
		else if arg_path.to_lower().ends_with('.json') {
			eprintln('no file found at `$arg_path`')
			return create_config( arg_path )
		}
		// After all this, let's stop the program. If the user wanted to use the defaults, they wouldn't have passed -c.
		return error('Invalid path. No json config file found at `$arg_path`')
	} // End of (arg_path != '')

	else {
		// The user did not pass -c, we need to load a default path.

		// Check current working dir first:
		if os.is_file(config_file_name) {
			println('Loading config from ./${config_file_name}')
			return process_config( config_file_name )
		}

		// If there's no config at `.`, lets look at the prefered `.minecraft/mods`
		if os.is_file(default_mc_dir + default_mc_mod_dir + config_file_name) {
			return process_config(default_mc_dir + default_mc_mod_dir + config_file_name)
		}

		// Lastly, as a backup, we'll check mcpkg executable's root dir.
		if os.is_file( os.resource_abs_path(config_file_name) ) {
			println('Loading config from `${os.resource_abs_path(config_file_name)}`')
			return process_config( os.resource_abs_path(config_file_name) )
		}

		// If it's not in either of these places, then we need to create our own config file.
		// First see if `~/.minecraft` exists. If it does, then it's cool to create our own mods folder.
		if os.is_dir(default_mc_dir) {
			eprintln('Could not find a mcpkg config file in `${default_mc_dir}`')
			return create_config(default_mc_dir + default_mc_mod_dir + config_file_name)
		}

		else {
			// Could not find a .minecraft folder.
			eprintln('MCPKG can\'t find your minecraft directory. On ${os.user_os()}, it\'s suposed to be here: `$default_mc_dir`.')
			mut last_path := ''
			if os.is_writable_folder(os.resource_abs_path('')) or {panic} {
				last_path = os.resource_abs_path(config_file_name)
			} else { last_path = './'+config_file_name }

			println('MCPKG can create a config file for you at `$last_path`, but you will have to edit this file before continuing.')
			return create_config(last_path)
		}
	}
}

fn process_config(path string) ?AppConfig {
	// return AppConfig{}
	return  error('process_config not implemented yet, but you tried to load one at `$path`.')
}

fn create_config(path string) ?AppConfig {
	if os.input('Would you like to create a config file at `$path`?\n[yes/No] ').to_lower()[0] == `y` {
		println('got the "Yes"')
		// create a config file at path

	} else {
		println('got a "no"')
		exit(0)
	}

	return error('create_config not implemented yet, but you tried to make one at `$path`.')
}

fn main() {
	// println(os.args)
	// TODO: Load config files
	app_config := get_config() or {
		println(err)
		exit(0)	// TODO, set this back to a panic. exit(0) because I know
	}

	// --== Main outline ==--

	// Load local mod list
	// create_example_local_list()
	// mod_list_path := settings.mod_dir + './local_mod_list.json'
	// local_mod_list := load_local_mod_json(mod_list_path)
	// println(local_mod_list)

	// Download and compare remote info about local mods

	// mp.get_mod_info('modrinth', 'AANobbMI')
	// for lm in local_mod_list.mods {
	// 	mp.get_mod_info( lm.source, lm.id )
	// 	println(lm.name)
	// }

	// Limit remote mods to selected game version.

	// If local mod version is less than remote versions:
	// Prompt user of updates and prepare download

	// Update local mod list

	// --== TMP ==--
	search := mp.SearchFilter{
		// query: 'sodium'
		query:			cmdline.option(os.args, '-S', '')
		// query: 'fabric'
		platform_name: 'modrinth'
		// game_versions: ['1.16.1', '1.16.2', '1.16.3']
		// game_versions: ['']
	}
	mods := mp.search_for_mods(search) or {
		eprintln(err)
		return
	}

	println('Total mods returned: $mods.len')
	// println(mods)

	// mut wanted_mods := []mp.Mod{}
	// for m in mods {
	// 	for v in versions {
	// 		if v in m.game_versions {
	// 			wanted_mods << m
	// 			break
	// 		}
	// 	}
	// }
	// println('Mods with versions in $versions: $wanted_mods.len')

	return
}
