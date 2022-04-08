package asteroid

import asteroid.devices.DevicesProject
import asteroid.packages.CommunityAppsProject
import com.github.kittinunf.fuel.Fuel
import jetbrains.buildServer.configs.kotlin.v2019_2.VcsSettings
import jetbrains.buildServer.configs.kotlin.v2019_2.vcs.GitVcsRoot
import org.json.JSONObject

object CoreVCS : CoreVCSDefault() {
	init {
		// Override default values with thise in overrides.json
		val json = Settings.overrides?.optJSONObject("coreVCS")
		val vcsList = allVcs.toMutableList()
		vcsList.add(DevicesProject.vcs)
		vcsList.add(CommunityAppsProject.vcs)
		if (json != null)
			for (vcs in vcsList) {
				val json2 = json.optJSONObject(vcs.name)
				if (json2 != null)
					checkVcsOverride(vcs,json2)
			}
	}
}

fun checkVcsOverride(vcs: GitVcsRoot, json: JSONObject) {
	val branchRegex = "\\((.*?)\\)".toRegex()
	val branch = json.optString("branch", branchRegex.find(vcs.branch!!)!!.value)
	val url = json.optString("url", vcs.url)
	vcs.branch = "refs/heads/($branch)"
	vcs.url = url
}

open class CoreVCSDefault {
	val Asteroid: GitVcsRoot
	val OpenEmbeddedCore: GitVcsRoot
	val Bitbake: GitVcsRoot
	val MetaOpenEmbedded: GitVcsRoot
	val MetaQt5: GitVcsRoot
	val MetaSmartphone: GitVcsRoot
	val MetaAsteroid: GitVcsRoot

	fun attachVCS(init: VcsSettings, forDevice: Boolean = false) {
		init.root(OpenEmbeddedCore, "+:.=>src/oe-core")
		init.root(Bitbake, "+:.=>src/oe-core/bitbake")
		init.root(MetaOpenEmbedded, "+:.=>src/meta-openembedded")
		init.root(MetaQt5, "+:.=>src/meta-qt5")
		init.root(MetaSmartphone, "+:.=>src/meta-smartphone")
		init.root(MetaAsteroid, "+:.=>src/meta-asteroid")
		if (forDevice)
			init.root(DevicesProject.vcs, "+:.=>src/meta-smartwatch")

		init.cleanCheckout = true
	}

	init {
		Asteroid = GitVcsRoot_fallback {
			id("AsteroidVCS")
			name = "Asteroid"
			gitBase = "https://github.com/"
			url = "${Settings.fork}/asteroid.git"
			fallback_url = "${Settings.upstream}/asteroid.git"
			branch = "refs/heads/(master)"
		}
		OpenEmbeddedCore = GitVcsRoot {
			id("OpenEmbeddedVCS")
			name = "OpenEmbedded Core"
			url = "https://github.com/openembedded/openembedded-core.git"
			branch = "refs/heads/(honister)"
		}
		Bitbake = GitVcsRoot {
			id("BitBakeVCS")
			name = "Bitbake"
			url = "https://github.com/openembedded/bitbake.git"
			branch = "refs/heads/(1.52)"
		}
		MetaOpenEmbedded = GitVcsRoot {
			id("MetaOpenEmbeddedVCS")
			name = "Meta OpenEmbedded"
			url = "https://github.com/openembedded/meta-openembedded.git"
			branch = "refs/heads/(honister)"
		}
		MetaQt5 = GitVcsRoot {
			id("MetaQt5VCS")
			name = "Meta Qt5"
			url = "https://github.com/meta-qt5/meta-qt5"
			branch = "refs/heads/(master)"
		}
		MetaSmartphone = GitVcsRoot {
			id("MetaSmartphoneVCS")
			name = "Meta Smartphone"
			url = "https://github.com/shr-distribution/meta-smartphone"
			branch = "refs/heads/(honister)"
		}
		MetaAsteroid = GitVcsRoot_fallback {
			id("MetaAsteroidVCS")
			name = "Meta Asteroid"
			gitBase = "https://github.com/"
			url = "${Settings.fork}/meta-asteroid"
			fallback_url = "${Settings.upstream}/meta-asteroid"
			branch = "refs/heads/(master)"
		}
	}
	val allVcs = listOf<GitVcsRoot>(
		Asteroid,
		OpenEmbeddedCore,
		Bitbake,
		MetaOpenEmbedded,
		MetaQt5,
		MetaSmartphone,
		MetaAsteroid
	)
}

class GitVcsRoot_fallback(init: GitVcsRoot_fallback.() -> Unit) : GitVcsRoot() {
	var gitBase: String? = null
	var fallback_url: String? = null

	init {
		init.invoke(this)
		val json = Settings.overrides?.optJSONObject("coreVCS")?.optJSONObject(name)
		if (json != null){
			checkVcsOverride(this,json)
		} else {
			if (!gitBase.isNullOrEmpty()) {
				url = gitBase + url
				if (!fallback_url.isNullOrEmpty())
					fallback_url = gitBase + fallback_url
			}
			if (!fallback_url.isNullOrEmpty()) {
				if (Settings.canHttp) {
					var testURL: String = url ?: ""
					var code = Fuel.get(testURL).response().second.statusCode
					if (code == 404) {
						testURL = fallback_url ?: ""
						code = Fuel.get(testURL).response().second.statusCode
					}
					if (code != 200) {
						// TODO: Resolve other excetions
					}
					url = testURL
				} else
					url = fallback_url
			}
		}
	}
}