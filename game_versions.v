// TODO: Version comparison fns (methods?)
import net
import net.http

const game_versions = get_mc_versions()

// get_mc_versions returns a full list of every version of Minecraft in order.
// In reality it gets every version tag from Modrinth, but at time of writing,
// it works just fine.
fn get_mc_versions() []string {
	config := http.FetchConfig{}
	responce := http.fetch('https://api.modrinth.com/api/v1/tag/game_version', config) or {
		panic(err)
	}
	// responce is a javascript array. There might be a method to import directly
	// from responce, but for now: Trim out extra caracters untill we use .split()
	versions := responce.text.after('[').before(']').replace('"', '').split(',')

	return versions
}

// is_release checks to see if a game version is a release or a snapshot.
// This assumes every release number looks like #.##.#, and every snapshot
// or pre-release has at least one extra character, like letters or dashes.
fn is_release(version string) bool {
	// We are cheesing the behavior of `.int()` pretty good. (it stops at the first non-number, or returns 0). An `is_int()` method would still be better.
	return version.replace('.', '').int().str() == version.replace('.', '')
}

// get_mc_releases returns a list of release version numbers. This is basicaly just a wrapper for is_release.
fn get_mc_releases() []string {
	return game_versions.filter(is_release(it))
}

// get_mc_snapshots returns a list of snapshot version numbers. This is the inverse of get_mc_releases.
fn get_mc_snapshots() []string {
	return game_versions.filter(!is_release(it))
}
