# Developer notes

If you want to dig into the nitty gritty underbelly, this is the place.

Dragon works on stages:

1. __Synchronize__ — Scan files from root folder, copying plain files into build folder as necessary.
2. __PreEval__ — A stage plugins can be injected to do something before evaluation.
3. __Evaluation__ — Process all identified dragon/eex templates and Scss files, saving the result into the build folder.
4. __PostEval__ — After evaluation of each file plugins may be run to do additional work. Current plugins:
   - Markdown -> Html — convert Markdown content to HTML
   - Redirect links — generate redirecting files
5. __Postprocess__ — [WIP] Scan all files in build folder and validate/cleanup/minify as appropriate based on content type.
6. __Deploy__ — [Future] integration with deployment. First: S3 for CDN's


## Plugins

More detail on this eventually. But at a high level, just implement the
Dragon.Plugin behavior (see the code) and reference your plugin in the dragon
config.

For plugins beyond the standard included with Dragon, you'll need to run in
a "Mix Project" mode rather than "Standalone" mode.
