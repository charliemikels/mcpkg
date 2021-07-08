module main

// import net
// import net.http
// import net.html
import json
import os
// import os.cmdline
import mod_platforms as mp

// get_search(): Demo fn to get OS arguments into the http request
// fn get_search() string {
// 	if '-S' in cmdline.only_options(os.args) {
// 		return cmdline.option(os.args, '-S', '') // TODO: look up documentation for this 3rd paramiter.
// 	}
// 	return ''
// }

struct McpkgConf {
	mod_dir string
	// threads	int // when multithreaded
}


fn main() {
	// Load config files
	// TODO
	settings := McpkgConf{
		mod_dir: './'	// TODO, provide an actual path when done
									// TODO, set path based on current OS (eg: ~/.minecraft/mods/ if linux)
	}

	// --== Main outline ==--

	// Load local mod list
	// create_example_local_list()
	mod_list_path := settings.mod_dir+'./local_mod_list.json'
	local_mod_list := load_local_mod_json(mod_list_path)
	// println(local_mod_list)

	// Download and compare remote info about local mods

	mp.get_mod_info( 'modrinth', 'AANobbMI' )
	// for lm in local_mod_list.mods {
	// 	mp.get_mod_info( lm.source, lm.id )
	// 	println(lm.name)
	// }


	// Limit remote mods to selected game version.

	// If local mod version is less than remote versions:
	// Prompt user of updates and prepare download

	// Update local mod list



	return
}
