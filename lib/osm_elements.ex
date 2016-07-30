defmodule OsmParse.OsmNode do
    defstruct id: 0, lon: 0, lat: 0, tags: %{}
end

defmodule OsmParse.OsmWay do
    defstruct id: 0, node_ids: [], tags: %{}
end

defmodule OsmParse.OsmRelation do
    defstruct id: 0, members: [], tags: %{}, type: nil
end

defmodule OsmParse.OsmMember do
    defstruct id: 0, type: "", role: ""
end