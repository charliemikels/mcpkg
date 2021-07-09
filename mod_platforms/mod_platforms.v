module mod_platforms

const (
	platforms = [
		modrinth(),
		// add platforms here
	]
)

// ModPlatforms is a holder for some basic info and functions to generalize various platform APIs
struct ModPlatform {
	name      string
	base_url  string
	list_mods fn () []Mod // fn (SearchFilter)
	// get_mod_details_from_id fn (string) //data
	get_mod_details fn (Mod) ModDetailed
	download_mod    fn (string) string
}

fn get_platform_by_name(name string) ?ModPlatform {
	mut list_of_names := []string{len: mod_platforms.platforms.len}
	for p in mod_platforms.platforms {
		if name.to_lower() == p.name.to_lower() {
			return p
		}
		list_of_names << p.name
	}
	return error('No known platform named `$name`. Available platforms: ${list_of_names}.')
}

// Mod is a generalized struct to display basic mod information. Use this for a long list of mods.
pub struct Mod {
	host string
	// platform			// TODO: We're doing a lot of for loops to get the platform, but we can't store the functions of Mod Platform in Json. Implement and do this lookup once at json import
	id            string
	slug          string // like Title, but url safe and stuff
	author        string
	title         string
	description   string
	game_versions []string
	page_url      string
	icon_url      string
	date_created  string // datetime?
	date_modified string // datetime?
	// client_side
	// server_side
}

pub fn (m Mod) get_platform() ?ModPlatform {
	return get_platform_by_name(m.host)
}

pub fn (m Mod) get_detailed() ModDetailed {
	p := m.get_platform() or {
		eprintln('Mod $m.title ($m.id) did not have a valid platform.')
		panic(err)
	}
	return p.get_mod_details(m)
}

// ModDetailed is similar to Mod, but holds extra information including the list of versions.
pub struct ModDetailed {
	Mod // embeded struct, everything mod does, ModDetailed does naturaly
	long_description string
	mod_versions     []Version
	// extra_links		map[string]string	// Source, Website, Donations, etc.
}

// Version holds information about a specific version of a mod.
pub struct Version {
	id  string
	mod Mod
	// mod_id string
	name           string
	version_number string
	version_type   string // 'alpha', 'beta', 'release'
	game_versions  []string
	date_published string
	files          []VersionFile //	See comment below
	// dependancies []Mod			//?? Not well supported on all sites.
	// loaders			[]string	//?? Forge / Fabric (/rift?)
}

// Modrinth supports multiple files per version. While it's not common,
// it can be useful in some cases. eg: Bundling the documentation with
// the mod. TODO: When downloading a version with more than one file,
// ask which one to download, but reccomend the first with `.jar` at the end.

// VersionFile
pub struct VersionFile {
	hashes   map[string]string
	url      string
	filename string
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
	platform     string // json cant do the functions, se let's just use the name
	last_updated string // datetime?
	mods         []Mod
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

pub fn get_mod_info(source_name string, mod_id string) {
	for p in mod_platforms.platforms {
		if p.name == source_name {
			// p.get_mod_info( mod_id )
			// p.get_mod_info( mod_id )
			return
		}
	}
}
