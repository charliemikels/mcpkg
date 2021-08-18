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
	mc_mod_dir         = 'mods/'
	mc_mcpkg_dir       = 'mcpkg/'
	mc_mcpkg_conf_name = 'mcpkg_conf.json'
		// mc_mcpkg_branch_info_name = 'branch_BRANCHNAME_info.json'
)

// App: Core app settings and modules.
// See parse_config_file for [skip]ed fields values
struct App {
	AppJson
mut:
	// TODO: [skip] broke, watch V issue #10957 for updates
	// We're using struct embeding to get arround json loading funk while [skip] is broken.
	config_dir       string
	config_file_path string
	current_branch   Branch
	branches         []string      // QUESTION: Remove? We already have a.list_branches()
	game_versions    []GameVersion = game_versions // I think we can generate this on the fly. Do we need to put it in App?
}

struct AppJson {
mut:
	current_branch_name string
	config_file_version string = '0.1'
	mc_dir              string = mc_root_dir
}

fn init_app() ?App {
	// basic app settings
	mut app := load_app_config() or { panic(err) }
	// Load branch info here.
	app.load_current_branch() or {
		if err.msg.contains('does not exist.') {
			// TODO: Check if there are mods in `mods/`. We should back them up if there are.
			eprintln('Can\' find current_branch: `$app.current_branch_name`')
			println(app)
			if os.input('Would you like to create a fresh branch file? [yes/No] ').to_lower()[0] or {
				`n`
			} != `y` {
				println('Exiting...')
				exit(0)
			} else {
				app.new_branch_wizard()
			}
		} else {
			panic(err)
		}
	}
	// Can't load it as a default, since they'll need to know where the mod dir is.
	return app
}

// QUESTION: With changes to use a .minecraft/mkdir as the default, load_app_config() might need to ajusted
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
	// TODO: WHEN [skip] FIXED, replace AppJson with App
	mut config_json := json.decode(AppJson, json_text) or {
		return error('Failed to decode config file json at `$path`.') // TODO: offer to create a fresh config. (Move file at path to 'old_$path_name')
	}
	// TODO: Catch file version errors. (json.decode will parse anything that's valid json and drops any tags that don't match.)
	// if false {} else...

	// TODO: Check validation errors.

	// Check for formatting errors.
	if json_text.trim_space() != json.encode_pretty(config_json) {
		backup_file(path, 3)
		mut updated_conf := os.create(path) or { panic(err) }
		updated_conf.write_string(json.encode_pretty(config_json)) or { panic(err) }
	}

	// We could load the current branch here, but it's easier to keep it as a method for app

	// HACK: workarround for [skip]
	config := App{
		AppJson: config_json
		config_dir: os.dir(path) + '/' // the config file location determins where branches live. We need to keep the path arround.
		config_file_path: path // small chance we'll want this???
	}

	return config
}

fn (a App) save_config() {
	backup_file(a.config_file_path, 3)
	mut json_struct := a.AppJson
	json_struct.current_branch_name = a.current_branch.name

	json_string := json.encode_pretty(json_struct)

	mut config_file := os.create(a.config_file_path) or { panic(err) }
	defer {
		config_file.close()
	}
	config_file.write_string(json_string) or { panic(err) }
}

fn create_config(path string) ?App {
	expected_conf_path := mc_root_dir + mc_mcpkg_dir + mc_mcpkg_conf_name
	// It is valid to give a path using `.` as in `./dir/conf.json`. TODO: This comparison might break in these situations. look into os.getwd().
	// println(expected_conf_path)
	// println(path)
	if path !in [expected_conf_path, os.resource_abs_path(mc_mcpkg_conf_name)] {
		eprintln('Heads up: The path `$path` is an unstandard config file location or name. Make sure to use `-c $path` to reload these setting.')
	}
	new_config := os.input('Would you like to create a new config file at `$path`? [yes/No] ').to_lower()
	if new_config[0] or { `n` } != `y` {
		// Not yes
		println('Exiting...')
		exit(0)
	}

	// Set mod dir
	mut mc_dir := mc_root_dir
	mut use_default_mc_path := os.input('Use default .minecraft path `$mc_root_dir`? [Yes/no] ').to_lower()
	for !(use_default_mc_path[0] or { `y` } == `y`) {
		mc_dir = os.input('Choose a new path to your .minecraft folder: ').replace('~',
			os.home_dir())
		if os.is_dir(mc_dir) {
			break
		}
		println('`$mc_dir` is not a directory. ')
	}

	// TODO: Set prefered game version / create_new_branch()

	println('creating config file...')

	// Creat default object
	config := App{
		mc_dir: mc_dir
		config_file_path: path
		config_dir: os.dir(path)
	}

	if !os.is_dir(os.dir(path)) {
		os.mkdir_all(os.dir(path)) or { panic(err) }
	}

	// os.write_file(path, json.encode_pretty(config)) or { panic(err) }
	mut config_file := os.create(path) or { panic(err) }
	config_file.write_string(json.encode_pretty(config.AppJson)) or { panic(err) }
	config_file.close()

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
	// reversed, so the most relevent item is displayed last
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
	mut app := init_app() or { panic(err) }

	if cmdline.option(os.args, '-b', '') != '' {
		app.change_branch(cmdline.option(os.args, '-b', '')) or { panic(err) }
		println(app.current_branch)
		println(app.list_branches())
		return
	}

	if '-B' in cmdline.only_options(os.args) {
		app.new_branch_wizard()
		println(app.current_branch)
		println(app.list_branches())
		return
	}

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

	// mods := mp.search_for_mods(search) or {
	// 	eprintln(err)
	// 	return
	// }
	// print_mod_selection(mods)

	println(app.current_branch)
	println(app.list_branches())

	return
}
