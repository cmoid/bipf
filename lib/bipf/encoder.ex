defprotocol BIPF.Encoder do
  @doc """
  Converts an Elixir data type to its representation in BiPF.
  """

  def encode(element, acc)
end

defimpl BIPF.Encoder, for: Atom do
  def encode(false, acc) do
    <<acc::binary, BIPF.Utils.tag(6, 1)::binary, 0>>
  end

  def encode(true, acc) do
    <<acc::binary, BIPF.Utils.tag(6, 1)::binary, 1>>
  end

  def encode(nil, acc) do
    <<acc::binary, BIPF.Utils.tag(6, 0)::binary>>
  end

  def encode(v, acc) do
    encode(Atom.to_string(v), acc)
  end
end

defimpl BIPF.Encoder, for: Integer do
  def encode(i, acc) do
    sz = BIPF.Utils.int_byte_len(i) * 8
    <<num::size(sz), _z2::binary>> = <<i::little-32>>
    tag = BIPF.Utils.tag(2, BIPF.Utils.int_byte_len(i))
    <<acc::binary, tag::binary, num::size(sz)>>
  end
end

defimpl BIPF.Encoder, for: BitString do
  def encode(i, acc) do
    tag = BIPF.Utils.tag(1, byte_size(i))
    <<acc::binary, tag::binary, i::binary>>
  end
end

defimpl BIPF.Encoder, for: List do
  def encode([], acc), do: <<acc::binary, BIPF.Utils.tag(4, 0)::binary>>

  def encode(list, acc) do
    {tot_len, encoded_terms} =
      Enum.reduce(list, {0, <<>>}, fn e, {l, collect} ->
        t_code = BIPF.Encoder.encode(e, <<>>)
        {l + byte_size(t_code), <<collect::binary, t_code::binary>>}
      end)

    <<acc::binary, BIPF.Utils.tag(4, tot_len)::binary, encoded_terms::binary>>
  end
end

defimpl BIPF.Encoder, for: Map do
  def encode([], acc), do: <<acc::binary, BIPF.Utils.tag(5, 0)::binary>>

  def encode(map, acc) do
    {tot_len, encoded_terms} =
      Enum.reduce(map, {0, <<>>}, fn {k, v}, {l, collect} ->
        k_code = BIPF.Encoder.encode(k, <<>>)
        v_code = BIPF.Encoder.encode(v, <<>>)

        {l + byte_size(k_code) + byte_size(v_code),
         <<collect::binary, k_code::binary, v_code::binary>>}
      end)

    <<acc::binary, BIPF.Utils.tag(5, tot_len)::binary, encoded_terms::binary>>
  end
end
