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