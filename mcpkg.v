module main

import net
import net.http
// import net.html
import json
import os
import os.cmdline

// JSON objects as V structs
struct Mod {
	mod_id         string
	slug           string
	author         string
	title          string
	description    string
	categories     []string // TODO?: parse into enums?
	versions       []string // TODO: parse into versions struct
	downloads      int
	follows        int
	page_url       string
	icon_url       string
	author_url     string
	date_created   string // TODO: Date time type?
	date_modified  string // TODO: Date time type?
	latest_version string // TODO: parse into versions struct
	license        string
	client_side    string // TODO?: Enum (Optional, Required, other?)
	server_side    string // TODO?: Enum (Optional, Required, other?)
	host           string
}

struct HitList {
	hits       []Mod
	offset     int
	limit      int
	total_hits int
}

// get_search(): Demo fn to get OS arguments into the http request
fn get_search() string {
	if '-S' in cmdline.only_options(os.args) {
		return cmdline.option(os.args, '-S', '') // TODO: look up documentation for this 3rd paramiter.
	}
	return ''
}

fn main() {
	// create demo HTTP request
	config := http.FetchConfig{
		// user_agent: 'Mozilla/5.0 (X11; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0'
		params: map{
			'query': get_search()
		}
	}
	responce := http.fetch('https://api.modrinth.com/api/v1/mod', config) or {
		println('http.fetch() failed')
		return
	}

	// Parse json results
	hits := json.decode(HitList, responce.text) or {
		println('JSON failed to decode responce.text')
		return
	}

	// --== print output ==--
	println('$hits.total_hits results found')
	if hits.total_hits > hits.limit {
		println('showing $hits.limit mods')
	}
	println('')

	// list mods
	for i, mod in hits.hits {
		println('$i - $mod.title: $mod.description')
	}

	return
}
