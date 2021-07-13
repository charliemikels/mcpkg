module main

// import net
// import net.http
// import net.html
import json
import os
import os.cmdline
import mod_platforms as mp
import term

// use https://api.modrinth.com/api/v1/tag/game_version to get a list of game versions in order.
// IDEA: Use this to compare if a game version is newer or older than others.

// AppConfig: Core app settings
struct AppConfig {
	config_file_path string // TODO: Add `[skip]`. The file itself doesn't know where it is, and we get the path anyways from -c or one of the 3 default locations. Load in path when reading the file.
	mods_dir         string
	// 								= $if linux {'${os.home_dir()}/.minecraft/mods/'
	// } $else $if macos {'${os.home_dir()}/Library/Application Support/minecraft/mods/'
	// } $else $if windows {'%appdata%/.minecraft/mods/' // QUESTION: Might not work, intended for win+R shortcut. Also, / is usualy \
	// } $else {''}
}

// TODO: store the default paths in a const.
// Currently broken. Strange C error: `declaration of void object`
// const(
// 	default_mc_dir = $if linux {
// 		'${os.home_dir()}/.minecraft/'
// 	} $else $if macos {
// 		'${os.home_dir()}/Library/Application Support/minecraft/'
// 	} $else $if windows {
// 		'%appdata%/.minecraft/'
// 	} $else {
// 		''
// 	}
// 	default_mc_mod_dir = 'mods/'
// )

// BranchConfig: Settings related to a mod branch
// struct BranchConfig {
// 	game_versions []string
// }

fn get_config() ?AppConfig {
	// some defaults
	config_file_name := 'mcpkg_config.json'

	default_mc_dir := $if linux {
		'$os.home_dir()/.minecraft/'
	} $else $if macos {
		'$os.home_dir()/Library/Application Support/minecraft/'
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
			return parse_config_file(arg_path)
		}
		// Path isn't a file, maybe it's a directory
		else if os.is_dir(arg_path) {
			// Look for default config file.
			// check if there's a trailing /
			if arg_path.ends_with('/') || arg_path.ends_with('\\') {
				if os.is_file(arg_path + config_file_name) {
					return parse_config_file(arg_path + config_file_name)
				} else {
					eprintln('no file found in `$arg_path`')
					return create_config(arg_path + config_file_name)
				}
			}
			// no trailing /
			else {
				if os.is_file(arg_path + '/' + config_file_name) {
					return parse_config_file(arg_path + '/' + config_file_name)
				} else {
					eprintln('no file found in `$arg_path`')
					return create_config(arg_path + '/' + config_file_name)
				}
			}
			// end of is_dir()
		}
		// Path isn't a file, or a directory. Maybe it's trying to create a file?
		// Last chance: Check if arg_path is trying to be a file.
		else if arg_path.to_lower().ends_with('.json') {
			eprintln('no file found at `$arg_path`')
			return create_config(arg_path)
		}
		// After all this, let's stop the program. If the user wanted to use the defaults, they wouldn't have passed -c.
		return error('Invalid path. No json config file found at `$arg_path`')
		// end of (arg_path != '')
	} else {
		// The user did not pass -c, we need to load a default path.

		// Check current working dir first:
		// NOTE: you might have to use os.getwd() to find the path to the working directory.
		if os.is_file(config_file_name) {
			println('Loading config from ./$config_file_name')
			return parse_config_file(config_file_name)
		}

		// If there's no config at `.`, lets look at the prefered `.minecraft/mods`
		if os.is_file(default_mc_dir + default_mc_mod_dir + config_file_name) {
			return parse_config_file(default_mc_dir + default_mc_mod_dir + config_file_name)
		}

		// Lastly, as a backup, we'll check mcpkg executable's root dir.
		if os.is_file(os.resource_abs_path(config_file_name)) {
			println('Loading config from `${os.resource_abs_path(config_file_name)}`')
			return parse_config_file(os.resource_abs_path(config_file_name))
		}

		// If it's not in either of these places, then we need to create our own config file.
		// First see if `~/.minecraft` exists. If it does, then it's cool to create our own mods folder.
		if os.is_dir(default_mc_dir) {
			eprintln('Could not find a mcpkg config file in `$default_mc_dir`')
			return create_config(default_mc_dir + default_mc_mod_dir + config_file_name)
		} else {
			// Could not find a .minecraft folder.
			eprintln('MCPKG can\'t find your minecraft directory. On $os.user_os(), it\'s suposed to be here: `$default_mc_dir`.')
			mut last_path := ''
			if os.is_writable_folder(os.resource_abs_path('')) or { panic } {
				last_path = os.resource_abs_path(config_file_name)
			} else {
				last_path = './' + config_file_name
			}

			println('MCPKG can create a config file for you at `$last_path`, but you will have to edit this file before continuing.')
			return create_config(last_path)
		}
	}
}

fn parse_config_file(path string) ?AppConfig {
	// Dump json text
	json_text := os.read_file(path) or {
		eprintln('Failed to read file on path `$path`. I thought we already checked to see if it was a good file...')
		panic(err)
	}
	// decode json
	config := json.decode(AppConfig, json_text) or {
		// eprintln('Failed to decode config file json at `$path`.')
		return error('Failed to decode config file json at `$path`.') // TODO: offer to create a fresh config. (Move file at path to 'old_$path_name')
	}
	// TODO: Once we've set up our config, overwrite the cuurent json file with it. That way, any new elements get written to the config file.
	return config
}

fn create_config(path string) ?AppConfig {
	// defaults. TODO: these should be in a const, but there's a c error I don't want to deal with yet.
	default_mc_mods_dir := $if macos {
		'$os.home_dir()/Library/Application Support/minecraft/mods/'
	} $else $if windows {
		'%appdata%/.minecraft/mods/' // QUESTION: Might not work, intended for win+R shortcut. Also, / is usualy \
	} $else { // Linux default
		'$os.home_dir()/.minecraft/mods/'
	}

	// Warn if path in in an unstandard location. "Remember to run mcpkg with `-c path/to/this/file`"
	if path !in [default_mc_mods_dir + 'mcpkg_config.json', os.resource_abs_path('')] {
		println('Heads up: mcpkg is going to create a config file at unstandard path: `$path`.')
		println('Run mcpkg with the argument `-c $path` to load this config file next time.')
	}
	if os.input('Would you like to create a config file at `$path`? [yes/No] ').to_lower()[0] != `y` {
		// Not yes
		println('Exiting...')
		exit(0)
	}

	// User said "yes", so let's make them a file.
	println('creating config file...')

	// Creat default object
	config := AppConfig{
		mods_dir: default_mc_mods_dir
		config_file_path: path
	}

	os.write_file(path, json.encode_pretty(config)) or { panic(err) }

	println('Config file written to `$path`.')
	return config
}

fn print_mod_selection(mods []mp.Mod) {
	max_spacing := mods.len.str().len
	mut max_name_len := 0
	for m in mods {
		if m.title.len > max_name_len {
			max_name_len = m.title.len
		}
	}
	t_width, _ := term.get_terminal_size()
	// reversed, so the most relevent item is desplayed last
	mods_r := mods.reverse()
	for i, m in mods_r {
		spaces := ' '.repeat(max_spacing - (mods.len - i).str().len)
		pre := '${mods.len - i}$spaces| '
		title := '$m.title: '
		description_width := t_width - pre.len - title.len
		description := if description_width < m.description.len {
			m.description[0..description_width - 3] + '...'
		} else {
			m.description
		}
		println('${mods.len - i}$spaces| $m.title: ${term.dim(description)}')
		// println('(description_width | description)')
	}
	println('\nFound $mods.len mods')
}

fn main() {
	// println(os.args)
	// TODO: Load config files
	app_config := get_config() or {
		println(err)
		exit(0) // TODO, set this back to a panic. exit(0) because I know
	}
	// println(app_config)

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
		// query: 'fabric'
		query: cmdline.option(os.args, '-S', cmdline.option(os.args, '-s', ''))
		platform_name: ''
		// game_versions: ['1.17.1']
		// game_versions: ['1.16.1', '1.16.2', '1.16.3']

		// game_versions: ['']
	}
	mods := mp.search_for_mods(search) or {
		eprintln(err)
		return
	}
	print_mod_selection(mods)



	return
}
