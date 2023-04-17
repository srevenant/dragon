# Installation

***Pre-Requisites:***

* Elixir
  - MacOS: `brew install elixir`
* Http server

  For the time being it temporarily uses an npm http server. Choose one:

  ```
  brew install http-server
  ```
  or
  ```
  yarn global add http-server
  ```

You can run it in one of two ways: Standalone and Mix Project

### Standalone / Global app

From within cloned dragon repo:

```
mix deps.get
mix escript.install
```

Then you run the command 'dragon' wherever you are.

### Mix Project (Elixir)

```
mix deps.get
mix compile
```

With this setup you must run `mix` instead of `dragon` and you have
to stay within the same dragon repo folder.  You can symlink your
project folders into this, or create some other sort of command wrapper.

### Running as a command

See Installation.

Use script `./start.sh` (modify to suit).

Or run:

```
mix build {target folder}
```
