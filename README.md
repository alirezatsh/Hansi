hansi
=================

This is CLI tool for setup and structuring your projects


[![oclif](https://img.shields.io/badge/cli-oclif-brightgreen.svg)](https://oclif.io)
[![Version](https://img.shields.io/npm/v/hansi.svg)](https://npmjs.org/package/hansi)
[![Downloads/week](https://img.shields.io/npm/dw/hansi.svg)](https://npmjs.org/package/hansi)


<!-- toc -->
* [Usage](#usage)
* [Commands](#commands)
<!-- tocstop -->
# Usage
<!-- usage -->
```sh-session
$ npm install -g hansi
$ hansi COMMAND
running command...
$ hansi (--version)
hansi/0.0.6 linux-x64 node-v24.4.0
$ hansi --help [COMMAND]
USAGE
  $ hansi COMMAND
...
```
<!-- usagestop -->
# Commands
<!-- commands -->
* [`hansi local django init`](#hansi-local-django-init)
* [`hansi plugins`](#hansi-plugins)
* [`hansi plugins add PLUGIN`](#hansi-plugins-add-plugin)
* [`hansi plugins:inspect PLUGIN...`](#hansi-pluginsinspect-plugin)
* [`hansi plugins install PLUGIN`](#hansi-plugins-install-plugin)
* [`hansi plugins link PATH`](#hansi-plugins-link-path)
* [`hansi plugins remove [PLUGIN]`](#hansi-plugins-remove-plugin)
* [`hansi plugins reset`](#hansi-plugins-reset)
* [`hansi plugins uninstall [PLUGIN]`](#hansi-plugins-uninstall-plugin)
* [`hansi plugins unlink [PLUGIN]`](#hansi-plugins-unlink-plugin)
* [`hansi plugins update`](#hansi-plugins-update)

## `hansi local django init`

Initialize a Django project with optional DB, Docker, and docker-compose

```
USAGE
  $ hansi local django init [--db sqlite|postgres|cloud] [--dockerfile] [--dockercompose]

FLAGS
  --db=<option>    [default: sqlite] Database type
                   <options: sqlite|postgres|cloud>
  --dockercompose  Create docker-compose.yml
  --dockerfile     Create Dockerfile

DESCRIPTION
  Initialize a Django project with optional DB, Docker, and docker-compose
```

_See code: [src/commands/local/django/init.ts](https://github.com/alirezatsh/Hansi/blob/v0.0.6/src/commands/local/django/init.ts)_

## `hansi plugins`

List installed plugins.

```
USAGE
  $ hansi plugins [--json] [--core]

FLAGS
  --core  Show core plugins.

GLOBAL FLAGS
  --json  Format output as json.

DESCRIPTION
  List installed plugins.

EXAMPLES
  $ hansi plugins
```

_See code: [@oclif/plugin-plugins](https://github.com/oclif/plugin-plugins/blob/v5.4.47/src/commands/plugins/index.ts)_

## `hansi plugins add PLUGIN`

Installs a plugin into hansi.

```
USAGE
  $ hansi plugins add PLUGIN... [--json] [-f] [-h] [-s | -v]

ARGUMENTS
  PLUGIN...  Plugin to install.

FLAGS
  -f, --force    Force npm to fetch remote resources even if a local copy exists on disk.
  -h, --help     Show CLI help.
  -s, --silent   Silences npm output.
  -v, --verbose  Show verbose npm output.

GLOBAL FLAGS
  --json  Format output as json.

DESCRIPTION
  Installs a plugin into hansi.

  Uses npm to install plugins.

  Installation of a user-installed plugin will override a core plugin.

  Use the HANSI_NPM_LOG_LEVEL environment variable to set the npm loglevel.
  Use the HANSI_NPM_REGISTRY environment variable to set the npm registry.

ALIASES
  $ hansi plugins add

EXAMPLES
  Install a plugin from npm registry.

    $ hansi plugins add myplugin

  Install a plugin from a github url.

    $ hansi plugins add https://github.com/someuser/someplugin

  Install a plugin from a github slug.

    $ hansi plugins add someuser/someplugin
```

## `hansi plugins:inspect PLUGIN...`

Displays installation properties of a plugin.

```
USAGE
  $ hansi plugins inspect PLUGIN...

ARGUMENTS
  PLUGIN...  [default: .] Plugin to inspect.

FLAGS
  -h, --help     Show CLI help.
  -v, --verbose

GLOBAL FLAGS
  --json  Format output as json.

DESCRIPTION
  Displays installation properties of a plugin.

EXAMPLES
  $ hansi plugins inspect myplugin
```

_See code: [@oclif/plugin-plugins](https://github.com/oclif/plugin-plugins/blob/v5.4.47/src/commands/plugins/inspect.ts)_

## `hansi plugins install PLUGIN`

Installs a plugin into hansi.

```
USAGE
  $ hansi plugins install PLUGIN... [--json] [-f] [-h] [-s | -v]

ARGUMENTS
  PLUGIN...  Plugin to install.

FLAGS
  -f, --force    Force npm to fetch remote resources even if a local copy exists on disk.
  -h, --help     Show CLI help.
  -s, --silent   Silences npm output.
  -v, --verbose  Show verbose npm output.

GLOBAL FLAGS
  --json  Format output as json.

DESCRIPTION
  Installs a plugin into hansi.

  Uses npm to install plugins.

  Installation of a user-installed plugin will override a core plugin.

  Use the HANSI_NPM_LOG_LEVEL environment variable to set the npm loglevel.
  Use the HANSI_NPM_REGISTRY environment variable to set the npm registry.

ALIASES
  $ hansi plugins add

EXAMPLES
  Install a plugin from npm registry.

    $ hansi plugins install myplugin

  Install a plugin from a github url.

    $ hansi plugins install https://github.com/someuser/someplugin

  Install a plugin from a github slug.

    $ hansi plugins install someuser/someplugin
```

_See code: [@oclif/plugin-plugins](https://github.com/oclif/plugin-plugins/blob/v5.4.47/src/commands/plugins/install.ts)_

## `hansi plugins link PATH`

Links a plugin into the CLI for development.

```
USAGE
  $ hansi plugins link PATH [-h] [--install] [-v]

ARGUMENTS
  PATH  [default: .] path to plugin

FLAGS
  -h, --help          Show CLI help.
  -v, --verbose
      --[no-]install  Install dependencies after linking the plugin.

DESCRIPTION
  Links a plugin into the CLI for development.

  Installation of a linked plugin will override a user-installed or core plugin.

  e.g. If you have a user-installed or core plugin that has a 'hello' command, installing a linked plugin with a 'hello'
  command will override the user-installed or core plugin implementation. This is useful for development work.


EXAMPLES
  $ hansi plugins link myplugin
```

_See code: [@oclif/plugin-plugins](https://github.com/oclif/plugin-plugins/blob/v5.4.47/src/commands/plugins/link.ts)_

## `hansi plugins remove [PLUGIN]`

Removes a plugin from the CLI.

```
USAGE
  $ hansi plugins remove [PLUGIN...] [-h] [-v]

ARGUMENTS
  PLUGIN...  plugin to uninstall

FLAGS
  -h, --help     Show CLI help.
  -v, --verbose

DESCRIPTION
  Removes a plugin from the CLI.

ALIASES
  $ hansi plugins unlink
  $ hansi plugins remove

EXAMPLES
  $ hansi plugins remove myplugin
```

## `hansi plugins reset`

Remove all user-installed and linked plugins.

```
USAGE
  $ hansi plugins reset [--hard] [--reinstall]

FLAGS
  --hard       Delete node_modules and package manager related files in addition to uninstalling plugins.
  --reinstall  Reinstall all plugins after uninstalling.
```

_See code: [@oclif/plugin-plugins](https://github.com/oclif/plugin-plugins/blob/v5.4.47/src/commands/plugins/reset.ts)_

## `hansi plugins uninstall [PLUGIN]`

Removes a plugin from the CLI.

```
USAGE
  $ hansi plugins uninstall [PLUGIN...] [-h] [-v]

ARGUMENTS
  PLUGIN...  plugin to uninstall

FLAGS
  -h, --help     Show CLI help.
  -v, --verbose

DESCRIPTION
  Removes a plugin from the CLI.

ALIASES
  $ hansi plugins unlink
  $ hansi plugins remove

EXAMPLES
  $ hansi plugins uninstall myplugin
```

_See code: [@oclif/plugin-plugins](https://github.com/oclif/plugin-plugins/blob/v5.4.47/src/commands/plugins/uninstall.ts)_

## `hansi plugins unlink [PLUGIN]`

Removes a plugin from the CLI.

```
USAGE
  $ hansi plugins unlink [PLUGIN...] [-h] [-v]

ARGUMENTS
  PLUGIN...  plugin to uninstall

FLAGS
  -h, --help     Show CLI help.
  -v, --verbose

DESCRIPTION
  Removes a plugin from the CLI.

ALIASES
  $ hansi plugins unlink
  $ hansi plugins remove

EXAMPLES
  $ hansi plugins unlink myplugin
```

## `hansi plugins update`

Update installed plugins.

```
USAGE
  $ hansi plugins update [-h] [-v]

FLAGS
  -h, --help     Show CLI help.
  -v, --verbose

DESCRIPTION
  Update installed plugins.
```

_See code: [@oclif/plugin-plugins](https://github.com/oclif/plugin-plugins/blob/v5.4.47/src/commands/plugins/update.ts)_
<!-- commandsstop -->
