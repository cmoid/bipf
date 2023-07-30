defmodule BIPF.Decoder do
  import Bitwise

  def decode(binary) do
    {tag, rest} = extract_tag(binary)
    decode_tag(tag, rest)
  end

  defp extract_tag(binary) do
    Varint.LEB128.decode(binary)
  end

  defp decode_tag(tag, binary) do
    {type, len} = parse(tag)
    decode_type(type, len, binary)
  end

  defp decode_type(1, len, binary) do
    <<ans::binary-size(len), rest::binary>> = binary
    {ans, rest}
  end

  defp decode_type(2, len, binary) do
    <<n::size(len * 8), rest::binary>> = binary
    <<ans::size(len * 8), _foo::binary>> = <<n::little-32>>
    {ans, rest}
  end

  defp decode_type(4, len, binary) do
    <<n::binary-size(len), rest::binary>> = binary
    {decode_list(n, []), rest}
  end

  defp decode_type(5, len, binary) do
    <<n::binary-size(len), rest::binary>> = binary
    {decode_map(n, %{}), rest}
  end

  defp decode_type(6, len, binary) do
    <<n::binary-size(len), rest::binary>> = binary

    val =
      case len do
        1 -> n == <<1>>
        0 -> nil
      end

    {val, rest}
  end

  defp parse(tag) do
    len = tag >>> 3
    {tag - (len <<< 3), len}
  end

  defp decode_list(<<>>, acc) do
    acc
  end

  defp decode_list(binary, acc) do
    {val, rest} = decode(binary)
    decode_list(rest, acc ++ [val])
  end

  defp decode_map(<<>>, acc) do
    acc
  end

  defp decode_map(binary, acc) do
    {key, rest} = decode(binary)
    {val, rest2} = decode(rest)
    decode_map(rest2, Map.put(acc, key, val))
  end
end
