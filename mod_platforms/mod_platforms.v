module mod_platforms

const (
	mod_platforms = [
		modrinth(),
		// add platforms here
	]
)

pub struct Mod {
	host	ModPlatform
	id string
	slug string	// like Title, but url safe and stuff
	author string
	title string
	description string
	//catagories []string
	game_versions []string
	// mod_versions	[]string (to build urls from)
	page_url string
	icon_url string
	date_created	string	//datetime?
	date_modified string	//datetime?
	// client_side
	// server_side
}

// pub fn (m Mod)download() {
// 	host.download_mod(  )
//
// }

struct SearchFilter {
	name					string
	game_version	string
	limit					int 		= 10
}

struct ModPlatform {
	name string
	base_url string
	list_mods 		fn( SearchFilter )	[]Mod
	download_mod	fn( string )				string
}

pub fn list_all_mods() {
	for platform in mod_platforms {
		// println(mod_platforms)
		// println('mods from $platform.name: ')
		list_of_mods := platform.list_mods( SearchFilter{limit: -1} )
		println(list_of_mods.len)

		// mod_list := platform.list_mods( SearchFilter{limit: 0} )

		for i, mod in list_of_mods {
			println('$i\t$mod.title')
		}

	}
}
