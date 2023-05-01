- abort should not exit, so dragon.serve doesn't exit
- layouts are still a bit confusing and don't quite work as well as they could
  (they need more context of their parent)
- metadata always set: @frame
- collections need more work; see metadata & layouts problems.
- dragon.convert {file} as well as {folder}
- Helpers:
  "nil2str" — maybe not necessary?
  "date" (strftime)
  "datefrom" plugin (within siteindex.xml)
  "sitemap" plugin? ~ ala redirects
  "as_key" - correlate to data too
- Should header matter from site/layout template be visible to children?
- abs path on layout should not check _layout
- eex filter for data (along the lines of markdownify)
- ? opinionated use of dashes or underbars in filenames. Probably underbar so it's
  consistent with vars.
- include file/title enrichment for all files, not just collections.
- @spec.args: elements support dictionary/default key syntaxes for defaults
- validation stage
- add --minify flag which will run minification in the proper places
- deploy stage
- delayed work queue where lambdas or callbacks of some sort can be punted,
  and run after everything else is done (like for path validation warnings)
- Add an ignore file/path filter to the _dragon.yml config.
- when in 'serve' and changing data files after initial build, it synchronizes
  them but doesn't load them.
- parse more template errors/tracebacks and make them more human readable, like:

```
** (KeyError) key :title not found in: %{name: "A site wide name", url: "https://example.com"}
    nofile:8: (file)
    nofile:4: (file)
    (stdlib 4.1.1) erl_eval.erl:748: :erl_eval.do_apply/7
    (stdlib 4.1.1) erl_eval.erl:323: :erl_eval.expr/6
    (stdlib 4.1.1) erl_eval.erl:492: :erl_eval.expr/6
    (stdlib 4.1.1) erl_eval.erl:136: :erl_eval.exprs/6
```

- every so often in 'serve' a process error happens:
```
Creating build folder: cato.digital/_build
** (EXIT from #PID<0.95.0>) an exception was raised:
    ** (UndefinedFunctionError) function :sys.get_log/1 is undefined or private
        (stdlib 4.1.1) :sys.get_log([])
        (stdlib 4.1.1) gen_server.erl:1383: :gen_server.error_info/8
        (stdlib 4.1.1) gen_server.erl:1362: :gen_server.terminate/10
        (stdlib 4.1.1) proc_lib.erl:240: :proc_lib.init_p_do_apply/3
```

## Transmogrify

- snakecase & co should handle atoms as well as strings ingress
- as_key should be in transmog
