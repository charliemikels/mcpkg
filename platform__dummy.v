module mcpkg

// PlatformDummy is an empty ModPlatform.
// By setting this as the default platform for Mods and ModVersions,
// we can surpresses the "platform must be initialized" warnings when building mod info from json.
struct PlatformDummy {
	name                    string = 'dummy'
	home_url                string
	requires_authentication bool
	auth_key                string
}

fn (a Api) new_platform_dummy() ModPlatform {
	return ModPlatform(PlatformDummy{})
}

fn (p PlatformDummy) search_for_mods(search SearchFilter, page PageInfo) ?[]Mod {
	return []Mod{}
}

fn (p PlatformDummy) get_mod_by_id(mod_id string) ?Mod {
	return Mod{}
}

fn (p PlatformDummy) get_versions_by_mod_id(mod_id string) ?[]ModVersion {
	return []ModVersion{}
}

fn (p PlatformDummy) get_version_by_id(version_id string) ?ModVersion {
	return ModVersion{}
}
