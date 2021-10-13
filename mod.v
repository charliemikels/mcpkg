module mcpkg

struct Mod {
	ModId
	platform 				ModPlatform // This probably _should_ be &ModPlatform, but doing so currently throws a c error.
	author   				string
	description 		string
	game_versions		[]string
	icon_url				string
mut:
	extras          ModExtraDetails
	versions        ModVersion
}

struct ModId {
	name            string
	slug						string
	id              string
	platform_string string [json: platform]
	// installed_version := ModVersion
}

struct ModExtraDetails {
	page_url				string
	date_created		string
	date_modified		string
	// published					string	// same as date_created?
	// catagories				[]string
	downloads					int
	// follows				int
	description_full  string
	license						map[string]string
	links							map[string]string
	// client_side: 	string
	// server_side: 	string
}


// ModVersion is a specific version of a mod.
// When the author updates the mod, we'll see it as a new version.
struct ModVersion {
	ModVersionJson
	mod        &Mod
}

struct ModVersionJson {
	version_id string
	files      []ModVersionFile
}

struct ModVersionFile {
	// mod_version &ModVersion
	hashes   map[string]string
	url      string
	filename string
}
