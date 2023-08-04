defmodule BIPF.Utils do
  import Bitwise

  def create_tag(type, len) do
    Varint.LEB128.encode((len <<< 3) + type)
  end

  def parse_tag(tag) do
    len = tag >>> 3
    {tag - (len <<< 3), len}
  end

  def extract_tag(binary) do
    Varint.LEB128.decode(binary)
  end

  def int_byte_len(0), do: 0

  def int_byte_len(n) when n < 0 do
    int_byte_len(-n - 1)
  end

  def int_byte_len(n) do
    1 + int_byte_len(n >>> 8)
  end
end
