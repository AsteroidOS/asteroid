package asteroid

import com.github.kittinunf.fuel.Fuel
import com.github.kittinunf.fuel.core.Headers
import com.github.kittinunf.fuel.core.extensions.jsonBody
import com.github.kittinunf.fuel.json.responseJson

enum class GitRepoHubType {
	Github
}

interface GitAPIChecker {
	val repo: String
	val token: String
	val hubType: GitRepoHubType
	val commitUser: String
	fun checkCommitStatus(): Boolean
	fun checkPR(): Boolean
	fun checkToken(): Boolean

	companion object {
		fun Create(repo: String, token: String): GitAPIChecker? {
			with(repo) {
				when {
					contains("https://github.com") -> return GithubAPIChecker(repo, token)
					else -> return null
				}
			}
		}
	}
}

class GithubAPIChecker(override val repo: String, override val token: String) : GitAPIChecker {
	override val hubType = GitRepoHubType.Github
	override val commitUser = Settings.commitUser
	val repoAPIBase = repo.removeSuffix(".git")
		.replace("https://github.com", "https://api.github.com/repos")

	override fun checkToken(): Boolean {
		// Cannot check if sandboxing is enabled or the token is not plain-text
		if (!Settings.canHttp || token.startsWith("credentialsJSON:"))
			return false
		val request = Fuel.get("https://api.github.com")
			.appendHeader(Headers.AUTHORIZATION, "token $token")
		return when (request.response().second.statusCode) {
			401 -> false
			200 -> true
			else -> {
				// TODO: Add warning
				false
			}
		}
	}

	override fun checkCommitStatus(): Boolean {
		// Cannot check if sandboxing is enabled or the token is not plain-text
		if (!Settings.canHttp || token.startsWith("credentialsJSON:"))
			return true
		// If token is invalid throw warning
		if (!checkToken()) {
			// TODO: add warning
			return false
		}

		var request = Fuel.get("$repoAPIBase/commits/HEAD/status")
			.appendHeader(Headers.AUTHORIZATION, "token $token")
		var response = request.responseJson()
		when (response.second.statusCode) {
			// Token cannot access private repo
			404 -> return false
			// Token does not have repo:status:read access to the repo
			403 -> return false
			// Token has at least repo:status:read access to the repo
			200 -> {}
			else -> {
				// Unknown states
				// TODO: Add warning
				return false
			}
		}
		val sha = response.third.component1()!!.obj()["sha"].toString()
		request = Fuel.post("$repoAPIBase/commits/$sha/statuses")
			.appendHeader(Headers.AUTHORIZATION, "token $token")
			.jsonBody(
				"""
						{
							"context": "test-connection",
							"state": "dummy"
						}
					""".trimIndent()
			)
		response = request.responseJson()
		return when (response.second.statusCode) {
			// Token does not have repo:status:write access to the repo
			403 -> false
			// Token has repo:status:write access but we made ill-formed content
			422 -> true
			// Created status. This should not have occured
			201 -> {
				// TODO: Add warning
				true
			}
			// Unknown
			else -> false
		}
	}

	override fun checkPR(): Boolean {
		// Cannot check if sandboxing is enabled or the token is not plain-text
		if (!Settings.canHttp || token.startsWith("credentialsJSON:"))
			return true
		// If token is invalid throw warning
		if (!checkToken()) {
			// TODO: add warning
			return false
		}

		val request = Fuel.get("$repoAPIBase/pulls")
			.appendHeader(Headers.AUTHORIZATION, "token $token")
		return when (request.response().second.statusCode) {
			// Token cannot access private repo
			404 -> false
			// Token does not have repo:status:read access to the repo
			403 -> false
			// Token has at least repo:status:read access to the repo
			200 -> true
			else -> {
				// Unknown states
				// TODO: Add warning
				false
			}
		}
	}
}