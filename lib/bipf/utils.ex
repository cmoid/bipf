defmodule BIPF.Utils do
  import Bitwise

  def tag(type, len) do
    Varint.LEB128.encode((len <<< 3) + type)
  end

  def int_byte_len(0), do: 0

  def int_byte_len(n) when n < 0 do
    int_byte_len(-n - 1)
  end

  def int_byte_len(n) do
    1 + int_byte_len(n >>> 8)
  end
end
