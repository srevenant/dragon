1. Synchronize — Synchronize files from root folder into build folder as necessary (only changed files)
2. Scan — scan the build folder and build a tree of metadata — which files are matching things for the future
          stages, and keep track of their front matter separately
3. Templating — Walk the tree, and for those files that have templates, process the Eex as appropriate, storing
          the result back into the same file without frontal matter.
4. Rendering — Walk the tree, and where render files are found convert them appropriately.
            Currently: Markdown->Html, and Scss -> Css
5. Validation — Walk the tree, and where appropriate, validate the files and re-factor them if configured.
6. Deploy — if so directed, deploy the build content



--------------------------------------------------
PROJECT:

.dragon/context/data.yaml
.dragon/layout/default.html
.dragon/include/header.html

about/index.md
about/styles.scss
about/hero.jpg

1. SYNC

about/index.md    -> build/about/index.md
about/styles.scss -> build/about/styles.scss
about/hero.jpg    -> build/about/hero.jpg

2. SCAN

%{
  about: %{
    "index.md": %{ path: "build/about/index.md", frontmatter: %{...}, content: "..."},
    "styles.scss": %{ path: "build/about/styles.scss", frontmatter: %{...}, content: "..." },
    "hero.jpg": %{ path: "build/about/hero.jpg", frontmatter: %{...}, content: "..." }
  }
}

3. TEMPLATE (EVALUATE)

- frontmatter removed
- eex expressions evaluated

build/about/index.md      -> build/about/index.md
build/about/styles.scss   -> build/about/styles.scss
build/about/hero.jpg      -> build/about/hero.jpg

4. RENDER (POSTPROCESS/TRANSFORM)

build/about/index.md      -> build/about/index.html
build/about/styles.scss   -> build/about/styles.css
build/about/hero.jpg      -> build/about/hero.jgp

5. VALIDATE

yml/yaml  -> yaml validation
html/svg  -> markup validation
css       -> css validation


COMMENTS / CONCERNS:
- prefer SYNC as last step
    - that way anytime we see something in build we're confident that it has been fully transformed and validated
- we potentially need an additional EVALUATE step for context b/c markup can be embedded in data
    - we should disallow eex in eex in data so 1 EVAL pass would suffice


PROPOSED FLOW:
  1. SCAN
    - scan context, layout, includes, and user content to produce

