module main

import os

// const backup_max_depth = 3

// backup_file copies `path` to `.backup_#__path`. If the backup path already exists,
// it will slide all older backups down a number untill max_depth is hit.
// Will be usefull for undo functions.
pub fn backup_file(path string, max_depth int) {
	replace_path := path.replace(os.file_name(path), '.backup_##__' + os.file_name(path))
	// move current backups down a file
	for d := max_depth; d > 0; d-- {
		check_path := replace_path.replace('##', '$d')
		if os.exists(check_path) {
			slide_path := replace_path.replace('##', '${d + 1}')
			os.mv(check_path, slide_path) or { panic(err) }
		}
	}
	// copy current file to backup 1
	os.cp(path, replace_path.replace('##', '1')) or { panic(err) }
}
