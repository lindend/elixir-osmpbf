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

## Usage

```
elements = OsmParse.parse(path)
```

This code will return a stream of the elements (OsmNode, OsmWay, OsmRelation), which are defined as follows:

```
defmodule OsmNode do
    defstruct id: 0, lon: 0, lat: 0, tags: []
end

defmodule OsmWay do
    defstruct id: 0, node_ids: [], tags: []
end

defmodule OsmRelation do
    defstruct id: 0, members: [], tags: [], type: nil
end

defmodule OsmMember do
    defstruct id: 0, type: "", role: ""
end
```