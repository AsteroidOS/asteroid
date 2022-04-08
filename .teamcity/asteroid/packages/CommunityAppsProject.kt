package asteroid.packages

import asteroid.GitVcsRoot_fallback
import asteroid.Settings
import jetbrains.buildServer.configs.kotlin.v2019_2.Project
import jetbrains.buildServer.configs.kotlin.v2019_2.vcs.GitVcsRoot

object CommunityAppsProject : Project({
	id("Packages_CommuityApps")
	name = "Asteroid Comunity Apps"
	description = "Additional community app packages"
}) {
	// Create the subProjects
	val packages = Settings.communityPackages.map { PackageProject(it, false) }
	val vcs: GitVcsRoot = GitVcsRoot_fallback {
		id("MetaCommunityVCS")
		name = "Meta Community"
		gitBase = "https://github.com/"
		url = "${Settings.fork}/asteroid.git"
		fallback_url = "${Settings.upstream}/asteroid.git"
		branch = "refs/heads/(master)"
	}

	init {
		for (pkg in packages)
			subProject(pkg)
		vcsRoot(vcs)
	}
}
