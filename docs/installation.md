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

Convert a Jekyll project: `dragon convert {target folder}`

Notes: This only does a few things to make it slightly easier:

* converts any '---' template into '--- dragon-1.0' template header
* makes a ham-fisted stab at converting liquid to eex — you WILL need to still review & cleanup
* moves _includes to _lib
* moves _layouts to _lib/layout
* converts `layout: XX` in header matter to `@spec:\n  layout: XX.html`
* moves Jekyll's _config.yml to _lib/site.yml
