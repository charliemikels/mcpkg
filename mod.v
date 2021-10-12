module mcpkg

struct Mod {
	ModJson
	platform ModPlatform // TODO: This probably _should_ be &ModPlatform, but doing so currently throws a c error.
	author   string
	// mut:
	// 	versions ModVersions
}

struct ModJson {
	name            string
	id              string
	platform_string string [json: platform]
}

// ModVersion is a specific version of a mod.
// When the author updates the mod, we'll see it as a new version.
struct ModVersion {
	mod        &Mod
	version_id string
	files      []ModVersionFile
}

struct ModVersionFile {
	// mod_version &ModVersion
	hashes   map[string]string
	url      string
	filename string
}
