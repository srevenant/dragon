- relative_include and stateful function injection
- builtin file watcher with phoenix serving files
- eex filter for data (along the lines of markdownify)
- ? opinionated use of dashes or underbars in filenames. Probably underbar so it's
  consistent with vars.
- include file/title enrichment for all files, not just collections.
- @spec.args: elements support dictionary/default key syntaxes for defaults
--------------------------------

Internal stages:

1. Synchronize — Synchronize files from root folder into build folder as necessary (only changed files)
2. Scan — scan the build folder and build a tree of metadata — which files are matching things for the future
          stages, and keep track of their front matter separately
3. Templating — Walk the tree, and for those files that have templates, process the Eex as appropriate, storing
          the result back into the same file without frontal matter.
4. Rendering — Walk the tree, and where render files are found convert them appropriately.
            Currently: Markdown->Html, and Scss -> Css
5. Validation — Walk the tree, and where appropriate, validate the files and re-factor them if configured.
6. Deploy — if so directed, deploy the build content

Notes: Synchronize and deploy should behave in an rsync manner (if not just using rsync)

Actions from command-line:

  `build [target:site]` — process everything up to Deploy stage (stopping at step 5)
  `serve [target:site] [port:5000]` — Do a build, and keep running, watching for content changes, and also serving a web service on the designated port.
  `deploy [target:site]` — take build folder and deploy it
