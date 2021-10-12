module mcpkg

struct PlatformModrinth{
	name string = 'modrinth'
	home_url string = 'https://modrinth.com/'
}

// --== Api responce structs ==--

// ModrinthModResult: Simplified version of ModrinthMod returned after a search.
// Used with ModrinthHitList.
struct ModrinthModResult {
	mod_id         string
	slug           string
	author         string
	title          string
	description    string
	categories     []string
	versions       []string
	downloads      int
	follows        int
	page_url       string
	icon_url       string
	author_url     string
	date_created   string // IDEA: Date time type?
	date_modified  string // IDEA: Date time type?
	latest_version string
	license        string
	client_side    string // (Optional, Required, others?)
	server_side    string // (Optional, Required, others?)
	host           string
}

// ModrinthHitList: info about the search.
// Used with GET https://api.modrinth.com/api/v1/mod/
struct ModrinthHitList {
	hits       []ModrinthModResult
	offset     int 	//
	limit      int 	// number of items per return
	total_hits int
}

// --== Helper fns ==--

// --== ModPlatform interface fns ==--
fn (p PlatformModrinth) search_for_mods(search SearchFilter) []Mod {

	mut mod_list := []Mod{}
	mod_list << Mod{
		name: 'bad mod'
		id: '5'
		platform_string: p.name
		platform: &p			// NOTE: If C errors crop up again, remove the &
	}
	return mod_list
}
