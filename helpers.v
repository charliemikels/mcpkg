module main

import os

const backup_max_depth = 3

// backup_file copies `path` to `.backup_#__path`. If the backup path already exists,
// it will slide all older backups down a number untill max_depth is hit.
// Will be usefull for undo functions.
pub fn backup_file(path string, max_depth int) {
	// maybe we cam make this a little less jank with `tmpl()`?
	pre := '.backup'
	sep := '--'
	// move current backups down a file
	println('debug stuff')
	for d := max_depth; d > 0;  d-- {
		println('for loop depth: $d')
		new_path := path.replace(os.file_name(path), pre+'$d'+sep+os.file_name(path) )
		if os.exists(new_path) {

			next_path := path.replace(os.file_name(path), pre+'${d+1}'+sep+os.file_name(path) )
			os.mv(new_path, next_path) or {panic(err)}
		}
	}
	os.cp( path, path.replace(os.file_name(path), pre+'1'+sep+os.file_name(path)) ) or {panic(err)}
}
