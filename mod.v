module mcpkg

struct Mod {
	ModJson
	platform 				ModPlatform // This probably _should_ be &ModPlatform, but doing so currently throws a c error.
	author   				string
	description 		string
	game_versions		[]string
	downloads				int
	// follows				int
	page_url				string
	icon_url				string
	author_url			string
	date_created		string
	date_modified		string
	latest_version	string
	license					string
	// client_side: 	string
	// server_side: 	string

	// mut:
	// 	versions []ModVersions
}

struct ModJson {
	name            string
	slug						string
	id              string
	platform_string string [json: platform]
	// installed_version := ModVersion
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
