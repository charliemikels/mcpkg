module main

// import net
// import net.http
// import net.html
import json
import os
import os.cmdline
import mod_platforms as mp
import term

const ( // QUESTION: Needed as const? We could stuff into load_app_config since it will likely only hapen once per run anyways.
	mc_root_dir = match os.user_os() {
		'linux' { '$os.home_dir()/.minecraft/' }
		'macos' { '$os.home_dir()/Library/Application Support/minecraft/' }
		'windows' { '%appdata%/.minecraft/' } // QUESTION: Might not work, intended for win+R shortcut. Also, / is usualy \
		else { '$os.home_dir()/' }
	}
	mc_mod_dir                = 'mods/'
	mc_mcpkg_dir              = 'mods/.mcpkg/'
	mc_mcpkg_conf_name        = 'mcpkg_conf.json'
	mc_mcpkg_branch_info_name = 'branch_BRANCHNAME_info.json'
)

// App: Core app settings and modules.
// See parse_config_file for [skip]ed fields values
struct App {
	// TODO: [skip] broke, watch V issue #10957 for updates
	// TODO: use struct embeding to get arround json loading funk while [skip] is broken.
	config_file_version string = '0.1'
	config_file_path    string = mc_root_dir + mc_mcpkg_dir + mc_mcpkg_conf_name // TODO: Add `[skip]`. The file itself doesn't know where it is, and we get the path anyways from -c or one of the 3 default locations. Load in path when reading the file.
	mods_dir            string = mc_root_dir + mc_mod_dir
	current_branch      string   // QUESTION: skip? We can generate this from whatever .json file is left in mc_mcpkg_dir (especialy if we format the name to 'branch_BRANCHNAME.json' or something)
	branches            []string // QUESTION: skip? We can generate this from the file system assuming we ignore DISABLED
	game_versions       []string = game_versions // TODO: add skip, we don't need to store this much info if we can generate it on the fly.
	game_releases       []string = get_mc_releases() // TODO: add skip, ^^
}

fn init_app() ?App {
	// basic app settings
	app := load_app_config() or { panic(err) }
	// check if branches exist
	// if branch_file_name in mod_dir files list, it exists. parse.
	// Else, create the file and return
	// app.create_branch_file()

	return app
}

fn load_app_config() ?App {
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
			if os.is_file(arg_path + mc_mcpkg_conf_name) {
				return parse_config_file(arg_path + mc_mcpkg_conf_name)
			}
			// no trailing /
			else if os.is_file(arg_path + '/' + mc_mcpkg_conf_name) {
				return parse_config_file(arg_path + '/' + mc_mcpkg_conf_name)
			}
			// end of is_dir()
		}
		// Path isn't a file, or a directory. Let's try to create the file at the given path.
		eprintln('no file found at `$arg_path`')
		if arg_path.to_lower().contains('.json') {
			return create_config(arg_path)
		}
		create_config(arg_path + '.json') ?
		// end of -C logic
	} else {
		// The user did not pass -c, we need to load a default path.

		// Check current working dir first:
		// NOTE: you might have to use os.getwd() to find the path to the working directory.
		if os.is_file(mc_mcpkg_conf_name) {
			println('Loading config from ./$mc_mcpkg_conf_name')
			return parse_config_file(mc_mcpkg_conf_name)
		}

		// If there's no config at `.`, lets look at the prefered `.minecraft/mods`
		if os.is_file(mc_root_dir + mc_mcpkg_dir + mc_mcpkg_conf_name) {
			return parse_config_file(mc_root_dir + mc_mcpkg_dir + mc_mcpkg_conf_name) // QUESTION: os.join_path() // https://modules.vlang.io/os.html#join_path
		}

		// Lastly, as a backup, we'll check mcpkg executable's root dir.
		if os.is_file(os.resource_abs_path(mc_mcpkg_conf_name)) {
			println('Loading config from `${os.resource_abs_path(mc_mcpkg_conf_name)}`')
			return parse_config_file(os.resource_abs_path(mc_mcpkg_conf_name))
		}

		// If it's not in any of these places, then we need to create our own config file.
		// First see if `~/.minecraft` exists. If it does, then it's cool to create our own mods folder.
		if os.is_dir(mc_root_dir) {
			eprintln('Could not find a mcpkg config file in `$mc_root_dir`')
			return create_config(mc_root_dir + mc_mcpkg_dir + mc_mcpkg_conf_name)
		} else {
			// Could not find a .minecraft folder.
			eprintln('MCPKG can\'t find your minecraft directory. On $os.user_os(), it\'s suposed to be here: `$mc_root_dir`.')
			mut last_path := ''
			if os.is_writable_folder(os.resource_abs_path('')) or { panic } {
				last_path = os.resource_abs_path(mc_mcpkg_conf_name)
			} else {
				last_path = './' + mc_mcpkg_conf_name
			}

			println('MCPKG can create a config file for you at `$last_path`, but you will have to edit this file before continuing.')
			return create_config(last_path)
		}
	}
}

fn parse_config_file(path string) ?App {
	// Dump json text
	json_text := os.read_file(path) or {
		eprintln('Failed to read file on path `$path`. I thought we already checked to see if it was a good file...')
		panic(err)
	}
	// decode json
	mut config := json.decode(App, json_text) or {
		return error('Failed to decode config file json at `$path`.') // TODO: offer to create a fresh config. (Move file at path to 'old_$path_name')
	}
	// TODO: Catch file version errors. (json.decode will parse anything that's valid json and drops any tags that don't match.)
	// if false {} else...

	// check for formatting errors.
	if json_text.trim_space() != json.encode_pretty(config) {
		println('Your config file looks fine, but the formatting is a bit off.')
		path_to_old := path.replace(os.file_name(path), 'old_' + os.file_name(path))
		os.mv(path, path_to_old) or { panic(err) }
		print('Backed up your current config to `$path_to_old`, ')

		mut updated_conf := os.create(path) or { panic(err) }
		updated_conf.write_string(json.encode_pretty(config)) or { panic(err) }
		println('and wrote a fresh file to `$path`.')
	}

	return config
}

fn create_config(path string) ?App {
	expected_conf_path := mc_root_dir + mc_mcpkg_dir + mc_mcpkg_conf_name
	// It is valid to give a path using `.` as in `./dir/conf.json`. TODO: This comparison might break in these situations. look into os.getwd().
	// println(expected_conf_path)
	// println(path)
	if path !in [expected_conf_path, os.resource_abs_path('')] {
		eprintln('Heads up: The path `$path` is an unstandard config file location or name. Make sure to use `-c $path` to reload these setting.')
	}
	new_config := os.input('Would you like to create a new config file at `$path`? [yes/No] ').to_lower()
	if new_config == '' || new_config[0] != `y` {
		// Not yes
		println('Exiting...')
		exit(0)
	}

	// Set mod dir
	mut mod_dir := mc_root_dir + mc_mod_dir
	mut use_default_mod_path := os.input('Use default mod path `$mod_dir`? [Yes/no] ').to_lower()
	for !(use_default_mod_path == '' || use_default_mod_path[0] == `y`) {
		mod_dir = os.input('Choose a new path to your mods folder: ').replace('~', os.home_dir())
		if os.is_dir(mod_dir) {
			break
		}
		println('`$mod_dir` is not a directory. ')
	}

	// TODO: Set prefered game version / create_new_branch()

	println('creating config file...')

	// Creat default object
	config := App{
		mods_dir: mod_dir
		config_file_path: path
	}

	if !os.is_dir(os.dir(path)) {
		os.mkdir_all(os.dir(path)) or { panic(err) }
	}

	// os.write_file(path, json.encode_pretty(config)) or { panic(err) }
	mut config_file := os.create(path) or { panic(err) }
	_ := config_file.write_string(json.encode_pretty(config)) or { panic(err) }

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
		println('$pre$m.title: ${term.dim(description)}')
		// println('(description_width | description)')
	}
	println('\nFound $mods.len mods')
}

fn main() {
	// println(os.args)
	// TODO: Load config files
	app := init_app() or { panic(err) }
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
	// search := mp.SearchFilter{
	// 	// query: 'sodium'
	// 	// query: 'fabric'
	// 	query: cmdline.option(os.args, '-S', cmdline.option(os.args, '-s', ''))
	// 	platform_name: ''
	// 	// game_versions: ['1.17.1']
	// 	// game_versions: ['1.16.1', '1.16.2', '1.16.3']
	//
	// 	// game_versions: ['']
	// }

	// println(app)

	// mods := mp.search_for_mods(search) or {
	// 	eprintln(err)
	// 	return
	// }
	// print_mod_selection(mods)

	return
}
