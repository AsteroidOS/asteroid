package asteroid.devices

import asteroid.*
import jetbrains.buildServer.configs.kotlin.v2019_2.BuildType
import jetbrains.buildServer.configs.kotlin.v2019_2.Project
import jetbrains.buildServer.configs.kotlin.v2019_2.PublishMode
import jetbrains.buildServer.configs.kotlin.v2019_2.buildFeatures.PullRequests
import jetbrains.buildServer.configs.kotlin.v2019_2.buildFeatures.commitStatusPublisher
import jetbrains.buildServer.configs.kotlin.v2019_2.buildFeatures.pullRequests
import jetbrains.buildServer.configs.kotlin.v2019_2.buildFeatures.sshAgent
import jetbrains.buildServer.configs.kotlin.v2019_2.buildSteps.script
import jetbrains.buildServer.configs.kotlin.v2019_2.triggers.vcs

class DeviceProject(val device: String) : Project({
	id("Devices_${device}")
	name = device
}) {
	val buildImage: BuildType
	val buildImageFromScratch: BuildType
	val architecture: String
	val meta: String

	init {
		val json = Settings.overrides?.optJSONObject("devices")?.optJSONObject(device)
		meta = json?.optString("meta") ?: device
		architecture = json?.optString("architecture") ?: "armv7vehf-neon"
		buildImage = BuildImage(device, architecture, meta)
		buildImageFromScratch = BuildImageFromScratch(device, architecture, meta)
		buildType(buildImage)
		if (Settings.cleanBuilds)
			buildType(buildImageFromScratch)
	}
}

/**
 * Template for device image builder
 */
open class BuildImage(device: String, architecture: String, meta: String = device) : BuildType({
	id("Devices_${device}_BuildImage")
	name = "Build Image"
	description = "Build Asteroid image for $device with latest sstate-cache"

	artifactRules = """
		+:build/tmp-glibc/deploy/images/${device}/asteroid-image-${device}*.ext4
		+:build/tmp-glibc/deploy/images/${device}/zImage-dtb-${device}*.fastboot
	""".trimIndent()
	publishArtifacts = PublishMode.SUCCESSFUL

	vcs {
		CoreVCS.attachVCS(this, true)
	}
	params {
		param("system.image.dev-suffix","")
	}

	steps {
		script {
			initScript(this, device, architecture, meta)
		}
		script {
			name = "Build Image"
			bitbakeBuild(this)
		}
		if (Settings.deploySstate) {
			script {
				updateSstate(this, device, architecture)
			}
		}
	}

	triggers {
		vcs {
			triggerRules = """
				+:root=${DevicesProject.vcs.id}:/meta-$meta/**
			""".trimIndent()

			branchFilter = "+:<default>"
		}
		vcs {
			triggerRules = """
				+:root=${DevicesProject.vcs.id};comment=^(?!\[NoBuild\]:).+:/meta-$meta/**
				+:root=${DevicesProject.vcs.id};comment=^\[(?:[^\]\n]*)($device)(?:[^\]\n]*)\][:]:/**
			""".trimIndent()

			branchFilter = "+:pull/*"
			buildParams.param("system.image.dev-suffix","-dev")
		}
	}

	features {
		if (Settings.deploySstate) {
			sshAgent {
				teamcitySshKey = "Sstate Server Key"
			}
		}
		var gitChecker: GitAPIChecker?
		if (Settings.pullRequests) {
			gitChecker = GitAPIChecker.Create(DevicesProject.vcs.url!!, Settings.GithubTokenID)
			if (gitChecker?.checkPR() == true)
				pullRequests {
					vcsRootExtId = "${DevicesProject.vcs.id}"
					when (gitChecker!!.hubType) {
						GitRepoHubType.Github -> {
							provider = github {
								authType = token {
									token = Settings.GithubTokenID
								}
								filterAuthorRole = PullRequests.GitHubRoleFilter.MEMBER_OR_COLLABORATOR
							}
						}
					}
				}
		}
		if (Settings.commitStatus) {
			gitChecker = GitAPIChecker.Create(DevicesProject.vcs.url!!, Settings.GithubTokenID)
			if (gitChecker?.checkCommitStatus() == true)
				commitStatusPublisher {
					vcsRootExtId = "${DevicesProject.vcs.id}"
					when (gitChecker!!.hubType) {
						GitRepoHubType.Github -> {
							publisher = github {
								githubUrl = "https://api.github.com"
								authType = personalToken {
									token = Settings.GithubTokenID
								}
							}
							param("github_oauth_user", gitChecker!!.commitUser)
						}
					}
				}
		}
	}
})

open class BuildImageFromScratch(device: String, architecture: String, meta: String = device) : BuildType({
	id("Devices_${device}_BuildImageFromScratch")
	name = "Build Image (from scratch)"
	description = "Build Asteroid image for $device from scratch and update the sstate-cache"

	artifactRules = "sstate-cache-${device}.tar.gz"
	maxRunningBuilds = 1
	publishArtifacts = PublishMode.SUCCESSFUL

	vcs {
		CoreVCS.attachVCS(this, true)
	}
	params {
		param("system.image.dev-suffix","-dev")
	}

	steps {
		script {
			initScript(this, device, architecture, meta, false)
		}
		script {
			bitbakeBuild(this)
		}
		if (Settings.deploySstate) {
			script {
				updateSstate(this, device, architecture, true)
			}
		}
		script {
			name = "Compress sstate-cache"
			scriptContent = """
				tar -cf sstate-cache-${device}.tar.gz build/sstate-cache
			""".trimIndent()
		}
	}

	triggers {
		vcs {
			triggerRules = """
				+:root=${DevicesProject.vcs.id};comment=^\[Rebuild:(?:[^\]\n]*)(${device})(?:[^\]\n]*)\][:]:**
				+:root=${CoreVCS.MetaAsteroid.id};comment=^\[Rebuild:(?:[^\]\n]*)(${device})(?:[^\]\n]*)\][:]:**
			""".trimIndent()

			branchFilter = "+:<default>"
		}
	}

	features {
		if (Settings.deploySstate) {
			sshAgent {
				teamcitySshKey = "Sstate Server Key"
			}
		}
	}
})