# TeamCity CI setup

This setup was constructed so that it can be easily ported by anyone who want to contribute and develop on their own
forks. Just follow these steps to get your CI server up and running (order of opperations is important):

1. Install a local TeamCity server
2. Create a new project named `Asteroid` pointing to this repository and the specific branch you wish to track and/or
   push these settings to
3. Configure the Context Parameters
4. Resolve the red errors related to the missing authenthication by providing a Github access token with at least read
   permission to public repositories.
5. (optional) Change the settings repository to point to the project one.

Feel free to change, archive, delete any of the sub-projects to fit your needs and write access.

### Context Parameters

For a full list check `.teamcity/$Project/Settings.kt`.

- `Fork`: [AsteroidOS]<br/>
The fork that should be attached to the current CI project.
- `Devices`: [sturgeon,catfish]<br/>
A comma-separated list of devices you wish to manage.
- `Packages`: [asteroid-launcher]<br/>
A comma-separated list of Asteroid packages you wish to manage.
- (optional) `Upstream`: [AsteroidOS]<br/>
The upstream repository of all the other parent/child projects.
- (optional) `DeploySstate`: [false]<br/>
Enables uploading to the `sstate-cache` server.
- (optional) `PullRequests`: [false]<br/>
Enables tracking pull requests on `fork`.
- (optional) `CommitStatus`: [false]<br/>
Enables pushing commit status to the `fork`.
- (optional) `CommitUser`: [`Fork`]<br/>
The commit user pushing commit status.
*Required if `CommitStatus == true`*.

### Other configurations

- (optional) `$Project/SSH Keys/Sstate Server Key`<br/>
The SSH key used to upload to your own `sstate-cache` server.
*Required if `DeploySstate == true`*.
- (optional) `$Project/Versioned Settings/Tokens/credentialsJSON:0b803d82-f0a8-42ee-b8f9-0fca109a14ab`<br/>
Github OAuth token for `CommitUser` or your account.
*Required if `PullRequests || CommitStatus == true`*.

### Other Notes