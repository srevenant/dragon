defmodule Dragon do
  @moduledoc """
  """


  * Crawl file tree
    - if file is .md, content is markdown (Earmark)
    - if file is .html, content is html — no content rendering required
  * Render Cycle:
    * Separate Header Matter from Content
    * Identify file content type and if content renderer is needed (Markdown)
    * Build context map with header matter and site data config
    * Enrich with meta-data
      - dates from filename
      - previous / next for all files in a folder sorted by date if folder
        configured for such
    * Process phoenix template to create first render
    * Process second content render if needed (Markdown)
  * Read templates and split header matter from content
end
