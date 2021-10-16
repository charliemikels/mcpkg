module mcpkg

struct Mod {
mut:
	is_incomplete bool = true
	name          string
	slug          string
	platform      ModPlatform
	id            string
	// platform_string string [json: platform]	// generate on load w/ json2
	author        string
	description   string
	game_versions []string
	icon_url      string
	versions      []ModVersion
	page_url      string
	date_created  string
	date_modified string
	// published					string	// same as date_created?
	// catagories				[]string
	downloads int
	// follows				int
	description_full string
	// license          map[string]string	// TODO? convert to struct? Move to links?
	license string
	// id, name, url
	links map[string]string
	// client_side: 	string
	// server_side: 	string
}

// ModVersion is a specific version of a mod. Not to be confused with GameVersion
struct ModVersion {
mut:
	is_incomplete  bool = true
	platform       ModPlatform
	id             string
	mod            Mod
	name           string
	number         string // version number, as in '0.1.5' etc.
	version_type   string // "release" "beta" "alpha"
	game_versions  []string
	files          []ModVersionFile
	date_published string
	changelog      string
	dependencies   []Mod
	loaders        []string // merge with dependencies??
	downloads      int
	// author_id			string
}

struct ModVersionFile {
mut:
	// mod_version &ModVersion
	hashes   map[string]string
	url      string
	filename string
	// primary  bool
}
