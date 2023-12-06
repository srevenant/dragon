- get_data() should respect _template syntax;
- get_data() should have option for returning deep dict with path or not


- bug: setting default value in @spec.args always sets default value even if value is set
- collections need more work
  - metadata always set: @frame
- dragon.convert {file} as well as {folder}
- Helpers:
  "datefrom" plugin (within siteindex.xml)
  "sitemap" plugin? ~ ala redirects
- Should header matter from site/layout template be visible to children?
- eex filter for data (along the lines of markdownify)
- ? opinionated use of dashes or underbars in filenames. Probably underbar so it's
  consistent with vars.
- validation stage
  - add --minify flag which will run minification in the proper places
- deploy stage
- delayed work queue where lambdas or callbacks of some sort can be punted,
  and run after everything else is done (like for path validation warnings)
- Add an ignore file/path filter to the _dragon.yml config.
