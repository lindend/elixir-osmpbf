# OsmParse

Elixir parser of .osm.pbf files. My first elixir project, so the code is probably awful. Definitely not production ready.


## Installation

  1. Add `osm_parse` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:osm_parse, git: "git://github.com/lindend/elixir-osmpbf.git"}]
    end
    ```

  2. Ensure `osm_parse` is started before your application:

    ```elixir
    def application do
      [applications: [:osm_parse]]
    end
    ```

