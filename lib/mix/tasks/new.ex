defmodule Mix.Tasks.Dragon.New do
  @moduledoc false
  @shortdoc "Create a new Dragon Project"
  use Mix.Task
  import Mix.Generator

  @impl true
  def run([target]), do: new(target)
  def run(_), do: IO.puts("Syntax: mix new {target}")

  ##############################################################################
  def new(target) do
    p = fn x -> Path.join(target, x) end
    create_file(p.("_dragon.yml"), dragon_config_template([]))
    create_file(p.("_data/site.yml"), data_site_template([]))
    create_file(p.("_lib/layout/default.html"), layout_default_template([]))
    create_file(p.("_lib/head.html"), lib_head_template([]))
    create_file(p.("_lib/footer.html"), lib_footer_template([]))
    create_file(p.("_lib/navbar.html"), lib_navbar_template([]))
    create_file(p.("_news/2023-04-04-File-name-here.md"), news_template([]))
    create_file(p.("index.html"), index_template([]))
    create_file(p.("assets/js/index.js"), index_js_template([]))
    create_file(p.("assets/img/favicon.svg"), icon_template([]))
    create_file(p.("assets/css/main.scss"), main_scss_template([]))
    create_file(p.("assets/css/plain.css"), plain_css_template([]))
    create_file(p.("assets/css/_included.scss"), included_scss_template([]))
  end

  ################################################################################
  embed_template(:plain_css, """
  body { font-weight: bold; }
  """)

  embed_template(:main_scss, """
  @import "included";
  """)

  embed_template(:included_scss, """
  body { font-weight: italic; }
  """)

  embed_template(:icon, """
  """)

  embed_template(:index_js, """
  """)

  embed_template(:data_site, """
  # There are no Dragon assumptions in this file. All content is up to
  # the site implementation.
  url: "https://example.com"
  name: "A site wide name"
  """)

  embed_template(:lib_head, """
  --- dragon-1.0
  --- eex
  <head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <meta property="og:locale" content="en_US">
  <meta property="og:url" content="<%%= @site.url %>" />
  <link rel="canonical" href="<%%= @site.url %>" />
  <meta property="og:site_name" content="<%%= @site.name %>" />
  <meta property="og:title" content="<%%= @site.name %>" />
  <meta name="og:type" content="website" />
  <title><%%= @site.name %></title>
  <link rel="icon" href="<%%= path "/assets/img/favicon.svg" %> ">
  <link rel="stylesheet" href="<%%= path "/assets/css/main.css" %>">
  <link rel="stylesheet" href="<%%= path "/assets/css/plain.css" %>">
  <script defer src="<%%= path "/assets/js/index.js" %>"></script>
  </head>
  """)

  embed_template(:lib_footer, """
  --- dragon-1.0
  --- eex
  <div>
  </div>
  """)

  embed_template(:lib_navbar, """
  <%%# Files without dragon template headermatter may also be used %>
  <%%# This is a comment; put navbar things here %>
  """)

  embed_template(:news, """
  --- dragon-1.0
  title: Optional Collection
  --- eex

  A news post
  """)

  embed_template(:index, """
  --- dragon-1.0
  @spec:
    layout: default.html
  title: A site!
  --- eex

  Contents of the index!
  """)

  embed_template(:layout_default, """
  --- dragon-1.0
  @spec:
    args:
    - content
  --- eex
  <!DOCTYPE html>
  <html lang="en">
  <%%= include "/lib/head.html" %>
  <body id="body" class="light flex flex-column navbar-offset">
  <%%= include "/lib/navbar.html" %>
  <%%= @page.content %>
  <div class="flex-grow-1"></div>
  <%%= include "/lib/footer.html" %>
  </body>
  </html>
  """)

  def dragon_config(opts), do: dragon_config_template(opts)

  embed_template(:dragon_config, """
  version: 1.0
  ## a list of data sources. Currently supported are type: file and collection
  data:
    - type: collection
      path: _news
      # The "into" keyword inserts the data into the context using this keyword.
      # if it is unspecified, the contents are inserted at the root of the context.
      into: news
    - type: file
      path: _data

  # where are layout files located? (multi accepted)
  layouts:
    - _lib/layout

  # where does the "built" version of the site go?
  staging: _build
  """)
end
