module main

// import net
// import net.http
// import net.html
// import json
// import os
// import os.cmdline
import mod_platforms as mp

// use https://api.modrinth.com/api/v1/tag/game_version to get a list of game versions in order.
// IDEA: Use this to compare if a game version is newer or older than others.

// get_search(): Demo fn to get OS arguments into the http request
// fn get_search() string {
// 	if '-S' in cmdline.only_options(os.args) {
// 		return cmdline.option(os.args, '-S', '') // not sure what this 3rd paramiter is for.
// 	}
// 	return ''
// }

// McpkgConf: Default config file and structure
struct McpkgConf {
	mod_dir string = $if linux {
		'~/.minecraft/mods'
	} $else $if macos {
		'~/Library/Application Support/minecraft/mods'
	} $else $if windows {
		'%appdata%\\.minecraft\\mods' // Might not work, intended for win+R shortcut
	} $else {
		''
	}
	// threads	int // when multithreaded
}

fn main() {
	// TODO: Load config files
	// mut settings := McpkgConf{
	// 	mod_dir: './'
	// }

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
		platform_name: 'modrinth'
		game_versions: ['1.16.1', '1.16.2', '1.16.3']
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
