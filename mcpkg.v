module main

// import net
// import net.http
// import net.html
// import json
// import os
// import os.cmdline

import mod_platforms



// get_search(): Demo fn to get OS arguments into the http request
// fn get_search() string {
// 	if '-S' in cmdline.only_options(os.args) {
// 		return cmdline.option(os.args, '-S', '') // TODO: look up documentation for this 3rd paramiter.
// 	}
// 	return ''
// }

struct McpkgConf {
	mod_dir		string
	// threads	int // when multithreaded
}

// fn parse_commands() {
//
// }

fn main() {
	// parse commands

	// load configs


	mod_platforms.list_all_mods()

	// println('yay')

	// list mods
	// for i, mod in hits.hits {
	// 	// println('$i - $mod.title: $mod.description')
	// 	println(mod)
	// 	break
	// }

	return
}
