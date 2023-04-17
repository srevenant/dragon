# Dragon

<b><i>Website Content Management System using Embedded Elixir templates (EEX)</i></b>

<div style="float: right; width: 25%; margin-left: 1rem;">
<img src="docs/dragon-w500.webp" alt="Dragon Mascot">
</div>

___ALPHA - WORK IN PROGRESS___

Dragon is a content management system similar to Jekyll, but using Elixir and
EEX templates, along with some improvements to behavior. It is the static-site
generator counterpoint to the Elixir Phoenix appserver.

If you are familiar with Jekyll, you should be able to migrate fairly easily.

Benefits of Dragon:

* Templates using powerful EEX rather than liquid. This comes with a feature-rich
  environment for all sorts of functionality (limited only by Elixir/EEX).
* Robust and extensible data handling system
* Very little "magic" and hard assertions. Other than the top level configuration
  file, the rest of it is up to how you configure your project.
* Relative includes! No need for files scattered all over in include folders,
  just include it from your local path. You can still use library folders if you
  so desire, in any location you choose.

To better understand how it behaves, see [Conventions](docs/conventions.md).

Additional topics:

* [Installation](docs/installation.md)
* [Using](docs/using.md)
* [FAQ](docs/faq.md)
* [TODO](docs/todo.md)
* [Contributors](docs/contributors.md)
* [Developer Notes](docs/developer-notes.md)
