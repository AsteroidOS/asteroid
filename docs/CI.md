# Continuous Integration (CI) for AsteroidOS

In the various repositories managed by AsteroidOS, we provide a few portable CI configurations that you can use to setup
your own CI server. We offer two CI configurations:

- Monolith (this repository): Contains all CI subprojects
- Individual (project's repository): Links to/Contains the minimum parent CI projects to build the project

AsteroidOS relies on CI to:

- Build and deploy the images for each smartwatch at https://asteroidos.org/install/
- (TBD) Update the apps managed by AsteroidOS and deploy them to AsteroidOS Updater (TBD)
- Manage and provide a public bitbake cache server to speed up the compilation time, both for our developers and anyone
  who wishes to contribute

Due to the complex interconnection of the AsteroidOS project, for a bare minimum CI setup, we require that:

| Requirements                    | TeamCity |
|---------------------------------|:--------:|
| Trigger on third-party commits  |    V     |
| Bootstrap configurations [1]    |    V     |
| Trigger on changes of subfolder |    V     |
| Trigger on commit message       |    V     |

[1] You can setup/manage your own CI server by simply pointing to your own forks of the project.

|                         | TeamCity                                                                                          |
|-------------------------|---------------------------------------------------------------------------------------------------|
| Maintainers             | [LecrisUT](https://github.com/LecrisUT)                                                           |
| Open Source             | Closed Source                                                                                     |
| Main Advantage          | - Can be setup on local development setup <br/> - Can interconnect with external TeamCity servers |
| Limitations             | - 3 Free Build agents <br/> - 100 Build Configurations                                            |
| Docker integration      | - Can be run without Docker                                                                       |
| Integration with Github | - Minimal <br/> - Lacks PullRequest build approval <br/> - Lacks a proper Github app              |
| Other noteworthy points | - Integrates with some Cloud agents                                                               |

--------------

## Available CI workflows

### Build device

Builds a specific device's image and deploys it to https://asteroidos.org/install/. Triggerred by:

- Changes in files at `meta-smartwatch/meta-$DEVICE` if the commit comment does not start with `[NoBuild]:`
- Commits starting with a comma separated list formatted like `$DEVICE1,$DEVICE2:`, where the relevant device is in the
  list

### Rebuild device (from scratch)

Builds a specific device's image without using any `sstate-cache`. Triggerred by:

- Commits starting with `[Rebuild:$DEVICE]:` on either `meta-smarwatch` or `meta-asteroid`
- Trigger by `Rebuild all devices`

### Build package

Builds a specific app's package and deploys it to the package repository connected to AsteroidOS Updated (TBD).
Triggerred by:

- Changes in files at `meta-asteroid-apps/$PACKAGE` if the commit comment does not start with `[NoBuild]:`
- Changes to the repository managing the specific package

### Build all devices

Triggers a `Build device` for all smartwatches. Triggerred by:

- Daily check if any of the `Build package` was triggerred
- Weekly schedule if that week there were no local contributions

### Rebuild all devices

Triggers a `Rebuild device (from scratch)` for all smarwatches. Triggerred by:

- Monthly schedule