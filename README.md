# Dragon

<b><i>Website Content Management System using Embedded Elixir templates (EEX)</i></b>

<div style="float: right; width: 25%; margin-left: 1rem;">
<img src="doc/dragon-w500.webp" alt="Dragon Mascot">
</div>

___ALPHA - WORK IN PROGRESS___

Dragon is a content management system similar to Jekyll, but using Elixir and
EEX templates, along with some improvements to behavior. It is the static-site
generator counterpoint to the Elixir Phoenix appserver.

If you are familiar with Jekyll, you should be able to migrate fairly easily.

Benefits of Dragon:

* Templates using EEX rather than liquid.
* More robust data handling system (future: handler for db/ecto integration).
* Simpler templating:
  - No requirements for includes or layouts folders. Templates can be inline
    in the current folder, or separately elsewhere.

Additional topics:

* [Installation](#Installation)
* [Using](#Using)
* [Conventions](doc/conventions.md)
* [Contributors](doc/contributors.md)

## Installation

Again: Work in progress.

Currently it cannot be installed as a standalone app (that's coming).

For now, create a folder "site" and build your service in there.

### 1. Pre-Requisites:

* Elixir
  - MacOS: `brew install elixir`

### 2. Install

```
mix deps.get
mix compile
```

For the time being it temporarily uses an npm http server. Choose one:

```
brew install http-server
```
or
```
yarn global add http-server
```

## Using

See Installation.

Use script `./start.sh` (modify to suit).

Or run:

```
mix build {target folder}
```

See also: [Example](example/)
