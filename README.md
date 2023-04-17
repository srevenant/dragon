# Dragon — Content Management System using Embedded Elixir templates (EEX)

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
* [Conventions](#Conventions)

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

## Conventions

- ___Meta Files___ — Files & folders beginning with underscore are "meta" files:
  - Meta files are not included in the rendered content, unless they are included
    in some other file.
  - Meta files may be referenced with or without beginning underscore. Example:

    `include "lib/to/file.html"`

    This will match `_lib/to/file.html` `_lib/to/_file.html` and other similar
    variations.

  - Contents below a meta folder will not be included, even if those
    files do not include an underscore.
- ___File Extensions___ — File extension aligns with desired/target file type,
  regardless of if its templated or not.

- ___Special files___ — 
  - `_dragon.yml` -> top level configuration, should be in the root of your site.
  - layout files are located in a folder which is configured in your dragon
    config file as "layouts" — default is `_lib/layout`

- ___Data___ —
  - Data imports are specified in the dragon config file, and may be one of two types: file(yml) and collection.
  - __File__ data targets should be folders. All yml file contents are loaded into the dragon context,
    matching file/folder heirarchy to a deep-map structure. Location within the context
    is assigned in the data specification.
  - __Collection__ data targets are folders, where each file represents a timestamped
    file in a collective set (such as blog posts) (see Templates for info on
    file metadata). Collections are enumerated and in sorted order.

- ___Templates___ —
  - Any file can be a template, if it begins with `--- dragon-1.0`
  - Templates have two sections: header matter, and content.
  - Content is separated from header matter with `--- eex`. Example:

     ```
     --- dragon-1.0
     title: Document Title
     --- eex
     <h1><%= @page.title %></h1>
     ```

  - All data loaded by the config file is available to all templates.
  - Data in the header matter of a file is available in `@page.{..}`
  - Data passed as arguments to an include are available in `@page.{..}`
  - Similar to Jekyll header matter is YML syntax.
  - Known header matter values:

    - `date:` — publish date (ISO 8601 syntax) — if unspecified, the date is
      taken from the filename, or if no date is in the filename, it is taken
      from the file's creation time.
    - `title:` — if unspecified the filename is converted to a title.
    - `date_modified:` — the last modification timestamp for the file.
    - `@spec:` — special data giving dragon information about the template, including:
      - `args:` — a list of required argument keywords for an include file. If
        the file is included in another and these keywords are not specified
        as arguments, an error is generated.
      - `layout:` — A layout file for the template. The template is included within
        the layout file, referenced as `@page.content`. Templates are located
        in the folder specified in the dragon config file as `layouts`.
