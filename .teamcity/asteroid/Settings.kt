package asteroid

import com.github.kittinunf.fuel.Fuel
import jetbrains.buildServer.configs.kotlin.v2019_2.DslContext
import org.json.JSONException
import org.json.JSONObject
import java.io.File

object Settings {
	val asteroidPackages = DslContext.getParameter("Packages")
		.split("[\\s,]".toRegex()).toList()
		.filterNot { it.isEmpty() }
	val communityPackages = DslContext.getParameter("CommunityPackages","")
		.split("[\\s,]".toRegex()).toList()
		.filterNot { it.isEmpty() }
	val devices = DslContext.getParameter("Devices")
		.split("[\\s,]".toRegex()).toList()
		.filterNot { it.isEmpty() }
	val cleanBuilds = DslContext.getParameter("CleanBuilds", "false").toBoolean()
	val withSstate = DslContext.getParameter("WithSstate", "true").toBoolean()

	val canHttp = fun(): Boolean {
		val request = Fuel.get("https://api.github.com")
		val response = request.response()
		val code = response.second.statusCode
		// This should be because of sandboxing
		if (code < 0)
			return false
		// TODO: Add warning
		return true
	}.invoke()
	val fork = DslContext.getParameter("Fork")
	val upstream = DslContext.getParameter("Upstream", "AsteroidOS")
	val deploySstate = DslContext.getParameter("DeploySstate", "false").toBoolean()

	object sstateServer {
		val url = DslContext.getParameter("SstateServerURL", "https://sstate.asteroid.org")
		val backendUrl = if (deploySstate)
			DslContext.getParameter("SstateServerBackendURL", "sstate.asteroid.org")
		else ""
		val user = if (deploySstate)
			DslContext.getParameter("SstateServerUser", "asteroidos")
		else ""
		val location = if (deploySstate)
			DslContext.getParameter("SstateServerLocation", "")
		else ""
	}

	// TODO: Change to Github app when available
	val GithubTokenID = DslContext.getParameter("GithubToken", "credentialsJSON:0b803d82-f0a8-42ee-b8f9-0fca109a14ab")
	val commitStatus = DslContext.getParameter("CommitStatus", "false").toBoolean()
	val commitUser = if (commitStatus)
		DslContext.getParameter("CommitUser", fork)
	else ""
	val pullRequests = DslContext.getParameter("PullRequests", "false").toBoolean()

	var overrides: JSONObject? = null

	init {
		val file = File(DslContext.baseDir, "overrides.json")
		if (file.exists()) {
			val text = file.readText()
			try {
				overrides = JSONObject(text)
			} catch (err: JSONException) {
				// TODO: Add warning not a JSON format
			}
		}
	}
}