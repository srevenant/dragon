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

Currently it must be installed within the application. Eventually we'd like it to
be a global install, so you don't have to have it per-project. For now:

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `dragon` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:dragon, "~> 0.1.0"}
  ]
end
```

## Using

```
mix build {target folder}
```

See also: [Example](example/)
