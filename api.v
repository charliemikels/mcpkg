module main

struct ApiJson {
	mc_root_dir string
	mc_mods_dir string
}
struct Api {
	ApiJson
	mut:
	config_path string
	// current_branch Branch
	// branches []Branch
}
