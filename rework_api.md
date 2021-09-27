# cmd:
-h							| Help text
-l 							|	List installed mods
-lv							| Lists recognized game versions. Only includes release versions.
-ls							| Lists recognized game versions. Includes Snapshots, pre-release, and other versions.
-lb / bl				| Lists all branches.
-s Search 			|	List remote mods based on search
-u							| Check for updates for installed mods
-u ModId				| Check for updates for specific mod
-U GameVersion	| Attempts to upgrade installed mods to GameVersion
-i ModId				| Give detailed info about Mod
-I RemoteModID	| Installs givenRemoteID

-b BranchID			| Switches branch to BranchID
-bn (name) GameVersion | Creates new branch with BranchConfig.
-bd BranchID 		| Deletes branch BranchID. Error if current branch.

-c path					| Defines where the config file lives for this run. 
