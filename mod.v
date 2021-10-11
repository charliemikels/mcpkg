module mcpkg

struct Mod{
	// ModJson
	source_platform string
	id 			string
	name		string
	author	string
// mut:
// 	versions ModVersions
}

// ModVersion is a specific version of a mod.
// When the author updates the mod, we'll see it as a new version.
struct ModVersion {
	mod 			 &Mod
	version_id string
	files 		 []ModVersionFile
}

struct ModVersionFile {
	// mod_version &ModVersion
	hashes   map[string]string
	url      string
	filename string
}
