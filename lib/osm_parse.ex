defmodule OsmParse do
    alias OsmParse.{OsmNode, OsmWay, OsmRelation, OsmMember}
    
    def parse(path) do
        file = File.stream!(path, [], 2048)
        stream_blobs(file)
            |> Stream.map(&parse_block(&1))
            |> Stream.map(&parse_primitive_block(&1))
            |> Stream.concat
    end

    defp stream_blobs(file) do
        Stream.transform(file, {:no_header, <<>>}, fn i, {header, data} = acc->
            data = data <> i
            case data do
                <<>> -> {[], acc}
                _ -> parse_blobs(header, data, [])
            end
        end)
    end

    defp parse_blobs(header, data, blocks) do
        case parse_blob(header, data) do
            {[], acc} -> {blocks, acc}
            {[item], {header, data}} ->
                {rest_items, acc} = parse_blobs(header, data, blocks)
                {[item | rest_items], acc}
        end
    end

    defp parse_blob(:no_header, <<header_size :: integer-size(32), header :: binary-size(header_size), body :: binary >>) do
        parse_blob(OSMPBF.FileFormat.BlobHeader.decode(header), body)
    end

    defp parse_blob(%OSMPBF.FileFormat.BlobHeader{} = header, data) do
        datasize = header.datasize
        case data do
            <<body_data :: binary-size(datasize), rest :: binary>> -> {[OSMPBF.FileFormat.Blob.decode(body_data)], {:no_header, rest}}
            _ -> {[], {header, data}}
        end
    end

    defp parse_blob(header, data) do
        {[], {header, data}}
    end

    defp parse_block(block) do
        get_block_data(block) |> OSMPBF.OsmFormat.PrimitiveBlock.decode
    end

    defp get_block_data(block) do
        cond do
            block.raw -> block.raw
            block.zlib_data -> :zlib.uncompress(block.zlib_data)
        end
    end

    defp parse_primitive_block(block) do
        strings = List.to_tuple(block.stringtable.s)
        Enum.map(block.primitivegroup, fn pg ->
            cond do
                pg.dense -> parse_dense_nodes(block, pg.dense, strings)
                !Enum.empty?(pg.ways) -> parse_ways(block, pg.ways, strings)
                !Enum.empty?(pg.nodes) -> parse_nodes(block, pg.nodes, strings)
                !Enum.empty?(pg.relations) -> parse_relations(block, pg.relations, strings)
                true -> []
            end
        end) |> Enum.concat
    end

    defp parse_dense_nodes(block, dense_nodes, strings) do
        ids = delta_decode(dense_nodes.id)
        lats = delta_decode(dense_nodes.lat)
        lons = delta_decode(dense_nodes.lon)
        tags = split_key_value_list(dense_nodes.keys_vals)
            |> Enum.map(&decode_strings(&1, strings))
            |> Enum.map(fn lst -> Map.new(Enum.chunk(lst, 2), &List.to_tuple(&1)) end)

        Enum.map(List.zip([ids, lats, lons, tags]), fn {id, lat, lon, tag_list} ->
            {lat, lon} = convert_coords(block, lat, lon)
            %OsmNode{id: id, lat: lat, lon: lon, tags: tag_list}
        end)
    end

    defp decode_strings(items, stringtable) do
        Enum.map(items, &elem(stringtable, &1))
    end

    defp delta_decode(values) do
        {values, _} = 
            Enum.map_reduce(values, 0, fn v, acc ->
                {acc + v, acc + v}
            end)
        values
    end

    defp split_key_value_list(keys_vals) do
        {acc, rest} = Enum.split_while(keys_vals, fn itm -> itm != 0 end)
        case rest do
            [] -> acc
            [0 | rest] -> [acc | split_key_value_list(rest)]
        end
    end

    defp parse_ways(_block, ways, strings) do
        Enum.map(ways, fn %{id: id, keys: keys, vals: vals, refs: refs} ->
            tags = parse_tags(keys, vals, strings)
            node_ids = delta_decode(refs)
            %OsmWay{id: id, node_ids: node_ids, tags: tags}
        end)
    end

    defp parse_relations(_block, relations, strings) do
        Enum.map(relations, fn relation ->
            tags = parse_tags(relation.keys, relation.vals, strings)
            roles = decode_strings(relation.roles_sid, strings)
            member_ids = delta_decode(relation.memids)
            members = Enum.map(List.zip([roles, member_ids, relation.types]), 
                fn {role, member_id, type} ->
                    %OsmMember{id: member_id, type: type, role: role}
                end)
            %OsmRelation{id: relation.id, members: members, tags: tags}
        end)
    end

    defp parse_nodes(block, nodes, strings) do
        Enum.map(nodes, fn node ->
            tags = parse_tags(node.keys, node.vals, strings)
            {lat, lon} = convert_coords(block, node.lat, node.lon)
            %OsmNode{id: node.id, lat: lat, lon: lon, tags: tags}
        end)
    end

    defp parse_tags(keys, vals, strings) do
        Map.new(List.zip([decode_strings(keys, strings), decode_strings(vals, strings)]))
    end

    defp convert_coords(%{granularity: granularity, lat_offset: lat_offset, lon_offset: lon_offset}, lat, lon) do
        lat_offset = get_or_default(lat_offset, 0)
        lon_offset = get_or_default(lon_offset, 0)
        granularity = get_or_default(granularity, 100)
        {0.000000001 * (lat_offset + (granularity * lat)), 0.000000001 * (lon_offset + (granularity * lon))}
    end

    defp get_or_default(nil, default), do: default
    defp get_or_default(v, _), do: v
end
