defmodule OsmParseTest do
  use ExUnit.Case
  doctest OsmParse

  alias OsmParse.{OsmNode, OsmWay, OsmRelation, OsmMember}

  setup %{file: file} do
    {:ok, data_path: Path.join([Path.dirname(file), "data"])}
  end

  test "parse dense nodes", %{data_path: data_path} do
    fileName = Path.join([data_path, "dense_nodes.osm.pbf"])
    result = OsmParse.parse(fileName) |> Enum.to_list

    assert [%OsmNode{id: 1, lat: 50.0005, lon: 50.000600000000006},
            %OsmNode{id: 2, lat: 50.0007, lon: 50.000800000000005, tags: %{"name" => "Test node", "other" => "tag"}},
            %OsmNode{id: 3}
          ] = result
  end

  test "parse relations", %{data_path: data_path} do
    fileName = Path.join([data_path, "relations.osm.pbf"])
    result = OsmParse.parse(fileName) |> Enum.to_list

    assert [
      %OsmNode{id: 1},
      %OsmNode{id: 2},
      %OsmNode{id: 3},
      %OsmWay{id: 7},
      %OsmRelation{id: 10, members: [
                            %OsmMember{type: :NODE, id: 1, role: "role1"},
                            %OsmMember{type: :NODE, id: 2, role: "role2"},
                            %OsmMember{type: :NODE, id: 3, role: "role3"}
                            ],
                          tags: %{"name" => "Test relation", "another" => "tag"}},
      %OsmRelation{id: 11, members: [%OsmMember{type: :WAY, id: 7, role: "role1"}]}
    ] = result
  end

  test "parse ways", %{data_path: data_path} do
    fileName = Path.join([data_path, "ways.osm.pbf"])
    result = OsmParse.parse(fileName) |> Enum.to_list

    assert [
      %OsmNode{id: 1},
      %OsmNode{id: 2},
      %OsmNode{id: 3},
      %OsmWay{id: 21, node_ids: [1, 2, 1], tags: %{"name" => "this is way", "something" => "else"}},
      %OsmWay{id: 22, node_ids: [1]}
    ] = result
  end
end
