# Installation

***Pre-Requisites:***

* Elixir
  - MacOS: `brew install elixir`
  - Linux: ...
  - Windows: ... ([see notes!](windows-notes.md))

You can run it in one of two ways: Standalone and Mix Project

### Standalone / Global app

Note: If you are curious about escript vs this install, [see Developer Notes](developer-notes.md).

To install as a standalone app, run:

```
./bin/install /usr/local
```

With that, you can then run the command 'dragon' wherever you are. This is only
for one user, and doesn't support multi-user setups.

### Mix Project (Elixir)

To run it locally as a mix project, just run:

```
mix deps.get
mix compile
```

With this setup you must run `mix` instead of `dragon` and you have
to stay within the same dragon repo folder.  You can symlink your
project folders into this, or create some other sort of command wrapper.

### File watching server

This will run a server on port 5000, which watches for changes and updates
as necessary: `dragon serve {target folder}` example:

```
dragon serve folder/path
```

#### Build

To just do a single build pass: `dragon build {target folder}` example:

```
dragon build my.site.folder
```

Where my.site.folder is local to where you are running the command.

#### New

Create a new project: `dragon new {target folder}`

#### Convert

Future: A script to do some initial conversion of Jekyll projects to Dragon.
