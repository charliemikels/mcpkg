module mod_platforms

const (
	platforms = [
		modrinth(),
		// add platforms here
	]
)

struct Mod {
	host        string
	id          string
	slug        string // like Title, but url safe and stuff
	author      string
	title       string
	description string
	// catagories []string
	game_versions []string
	// mod_versions	[]string (to build urls from)
	page_url      string
	icon_url      string
	date_created  string // datetime?
	date_modified string // datetime?
	// client_side
	// server_side
}

struct ModPlatform {
	name         string
	base_url     string
	list_mods    fn (/*SearchFilter*/) []Mod
	get_mod_info fn (string) //data
	download_mod fn (string) string
}

// struct SearchFilter {
// 	name         string
// 	game_version string
// 	limit        int = 10
// }


//
// struct RemoteModListFile {
// 	file_version		string
// 	last_updated		string // datetime?
// 	remote_mod_list	[]RemoteModList
// }
//
struct RemoteModList {
	platform			string // json cant do the functions, se let's just use the name
	last_updated	string // datetime?
	mods					[]Mod
}

// WIP
// pub fn update_mod_list(/*[]RemoteModList*/) /*RemoteModListFile*/  {
//
// 	mut remote_mod_list := []RemoteModList{}
//
// 	for p in platforms {
//
// 		// platform := p()
// 	// for p in RemoteModList.platform
// 		// println(mod_platforms)
// 		// println('mods from $platform.name: ')
// 		list_of_mods := p.list_mods(/*SearchFilter{limit: 0}*/)
// 		println(list_of_mods.len)
//
// 		remote_mod_list << {
// 			platform: p.name
// 			mods:			list_of_mods
// 			last_updated: 'today'
// 		}
//
// 		// mod_list := platform.list_mods( SearchFilter{limit: 0} )
// 		//
// 		// for i, mod in list_of_mods {
// 		// 	println('$i\t$mod.title')
// 		// }
// 	}
//
// 	// return {
// 	// 	file_version: '0.0.1'
// 	// 	last_updated: 'today'
// 	// 	remote_mod_list: remote_mod_list
// 	// }
//
//
// }

pub fn get_mod_info( source_name string, mod_id string ) {
	for p in platforms {
		if p.name == source_name {
			p.get_mod_info( mod_id )
			return	// p.get_mod_info( mod_id )
		}
	}
}
