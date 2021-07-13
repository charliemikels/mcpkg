module mod_platforms

const (
	platforms = [
		modrinth(),
		// add platforms here
	]
)

// ModPlatforms is a holder for some basic info and functions to generalize various platform APIs
struct ModPlatform {
	name     string
	base_url string
	// list_mods 						fn () []Mod // fn (SearchFilter)
	get_mods_by_search    fn (SearchFilter) []Mod
	get_mod_details_by_id fn (string, SearchFilter) Mod
	re_get_mod            fn (Mod, SearchFilter) Mod // For updates
	get_mod_details       fn (Mod) ModDetailed
	// download_mod    			fn (string) string // download_version fn (Version) 	// Do we need to call the API for this? we're already given a URL in VersionFile
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
mut:
	platform ModPlatform [skip]
pub:
	// Json can't do ModPlatform's functions, so skip them, and on load, figure it out from host
	host          string
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

// THERE IS A COMPILER ERROR HERE:
// At the return in can't convert the Mod* `m` to a Mod
//
// pub fn (m Mod) get_detailed() ModDetailed {
// 	// Find the struct that hosts the mod
// 	p := m.get_platform() or {
// 		eprintln('Mod $m.title ($m.id) did not have a valid platform.')
// 		panic(err)
// 	}
// 	return p.get_mod_details(m)
// }

// ModDetailed is similar to Mod, but holds extra information including the list of versions.
pub struct ModDetailed {
	Mod // embeded struct, everything mod does, ModDetailed does naturaly
pub:
	long_description string
	mod_versions     []Version
	// extra_links		map[string]string	// Source, Website, Donations, etc.
}

// Version holds information about a specific version of a mod.
pub struct Version {
pub:
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
// ask which one to download, but recomend the first with `.jar` at the end.

// VersionFile
pub struct VersionFile {
pub:
	hashes   map[string]string
	url      string
	filename string
}

pub struct SearchFilter {
pub:
	query         string
	game_versions []string
	platform_name string // Usefull outside of module
}

// --== mod_platform api: ==--

pub fn search_for_mods(filter SearchFilter) ?[]Mod {
	if filter.platform_name == '' {
		// No platform given? Use all of them!
		// mut threads := []thread []Mod{}
		mut mods := []Mod{}
		for p in platforms {
			println('Making request to $p.name')
			// threads << go p.get_mods_by_search(filter)
			mods << p.get_mods_by_search(filter)
		}
		// threads_mods_split := threads.wait()
		// for tms in threads_mods_split {
		// 	mods << tms
		// }
		return mods

	} else {
		p := get_platform_by_name(filter.platform_name) or { return err }
		return p.get_mods_by_search(filter)
	}
}

pub fn get_mod_info(source_name string, mod_id string) {
	for p in mod_platforms.platforms {
		if p.name == source_name {
			// p.get_mod_info( mod_id )
			// p.get_mod_info( mod_id )
			return
		}
	}
}
