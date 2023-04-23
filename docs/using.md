# Using

See also: [Example](../example/)


- ___Reserved files / Folders___ — 
  - `_dragon.yml` — This is the only required file name. It is the top level
    configuration file and should be in the root of your site folder.
  - Layout files are located in a folder which is configured in your dragon
    config file as "layouts" — default is `_lib/layout`

- ___File management___ — all files in the target folder will be processed,
  depending on their content type. Files are either _meta_, _special_,
  or _plain_, and are identified in this same order. If a file is a meta file,
  it will not be considered as a special file. If it is a special file, then it
  is not considered as a plain file.
  - ___meta___ files are those that begin with an underscore.
    - Meta files are not included in the rendered content, unless they are
      included in another file.
    - Meta files may be referenced with or without beginning underscore. Example:

      `include "lib/to/file.html"`

      This will match `_lib/to/file.html` `_lib/to/_file.html` and other similar
      variations.
    - Contents below a meta folder will not be included, even if those
      files do not include an underscore.
  - ___special___ files either Templates, or are known by file extension/type
    (currently: ".scss"). Templates, which can be any file type, are text files
    which begin with a dragon template header `--- dragon-1.0`.
    Special files are processed before being saved into the build folder.
  - ___plain___ files are those which are neither meta nor special, and they are
    simply copied verbatim to the build folder, preserving modes, as well as
    modified and creation times.
  - ___File Extensions___ — File extensions align with desired/target file type,
    regardless of if its templated or not. Do not use `.eex` files, but rather
    `.html`, `.txt`, or others as appropriate.

- ___Data___ —
  - Data imports are specified in the dragon config file, and may be one of two
    types: _file_ (yml) and _collection_ (future: _ecto_).
  - __File__ data targets should be folders. All yml, yaml, and json files' contents
    are loaded into the dragon context, matching file/folder hierarchy to a
    deep-map structure. Location within the context is assigned in the data
    specification.

    If you have a lot of data, it's suggested to save it as json rather than
    yaml as it will load faster.
  - __Collection__ data targets are folders, where each file represents a timestamped
    file in a collective set (such as blog posts) (see Templates for info on
    file metadata). Collections are enumerated and in sorted order.
  - If you are used to using dot-syntax data paths these still work, except
    if the data path is not there. While in jekyll this would result in a null
    value, in elixir it will create an error.

    However, you can use the index operator instead, which can resolve against
    a nil value. So if your data tree might have `x.y.z` but `y` is undefined,
    and this causes an error. Instead you can use `x[:y][:z]` to get the same
    behavior as before.

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
  - __Helper Functions__ — A few functions are provided in addition to standard
    elixir:
      - `include` — at the heart of the template is being able to merge multiple
        files into one. This uses the `include` helper function. The first argument
        is a path, which is _RELATIVE TO THE CURRENT FILE_ unless you begin it
        with a slash. If it begins with a slash, it is then resolved based on
        the base of the project instead (an absolute path rather than relative).

        Remember: metafiles (beginning with an underscore) are ignored unless
        included through some means such as this, so you can place these within
        your build tree without concern.
      - `path` — a function that verifies files exist in the build folder, and
        converts them to the absolute version of the file using the same logic
        as is used with include.
      - `markdownify` — convert a string to html.
      - `peek` — load the headermatter of a target dragon template

- ___Elixir/EEX Template imports___ You can include additional standard elixir
  modules modules through the dragon config variable `imports:` which takes
  a list of module names. At this time you cannot import custom modules
  without adding it to the Dragon lib folder.
