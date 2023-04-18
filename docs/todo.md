- builtin file watcher with phoenix serving files
- eex filter for data (along the lines of markdownify)
- ? opinionated use of dashes or underbars in filenames. Probably underbar so it's
  consistent with vars.
- include file/title enrichment for all files, not just collections.
- @spec.args: elements support dictionary/default key syntaxes for defaults
- validation stage
- add --minify flag which will run minification in the proper places
- deploy stage
- delayted work queue where lambdas or callbacks of some sort can be punted,
  and run after everything else is done (like for path validation warnings)
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
