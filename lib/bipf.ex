defmodule BIPF do
  @moduledoc """
  BIPF (Binary In Place Format) is an implementaion of [BIPF.tinySSB](https://github.com/ssbc/sips/blob/master/011.md),
  a binary serialization format for JSON designed for optimal use in memory.

  ## Examples

  iex> BIPF.loads(BIPF.dumps(nil))
  {:ok, nil, ""}


  """

  @doc """
  Turns an in-memory data item V into a series of bytes

  ## Examples

  iex> Base.encode16(BIPF.dumps(nil))
  "06"

  iex> Base.encode16(BIPF.dumps(false), case: :lower)
  "0e00"

  iex> Base.encode16(BIPF.dumps(true), case: :lower)
  "0e01"

  iex> Base.encode16(BIPF.dumps(123), case: :lower)
  "0a7b"

  iex> Base.encode16(BIPF.dumps(-123), case: :lower)
  "0a85"

  iex> Base.encode16(BIPF.dumps("¥€$!"), case: :lower)
  "39c2a5e282ac2421"

  # iex> BIPF.dumps(#ABCD#)
  # 11abcd

  iex> Base.encode16(BIPF.dumps([123,true]), case: :lower)
  "240a7b0e01"

  iex> Base.encode16(BIPF.dumps(%{123 => false}), case: :lower)
  "250a7b0e00"

  # iex> BIPF.dumps({#ABCD#:[123,null]}))
  # 3d11abcd1c0a7b06

  """
  @spec dumps(any()) :: binary()
  def dumps(v),
    do: BIPF.Encoder.encode(v, <<>>)

  @doc """
  Converts a BIPFencoded binary into native elixir data structures

  # ## Examples

  iex> BIPF.loads(<<6>>)
  {:ok, nil, ""}

  iex> Base.decode16("0e00", case: :lower)
  {:ok, <<14, 0>>}

  iex> BIPF.loads(<<14, 0>>)
  {:ok, false, ""}

  # iex> BIPF.loads(0e01)
  # {ok, true, ""}

  # iex> BIPF.loads(0a7b)
  # {ok, 123, ""}

  # iex> BIPF.loads(0a85)
  # {ok, -123, ""}

  # iex> BIPF.loads(39c2a5e282ac2421)
  # {ok, "¥€$!", ""}

  # iex> BIPF.loads(11abcd)
  # {ok, #ABCD#, ""}

  iex> BIPF.loads(BIPF.dumps(%{123 => true}))
  {:ok, %{123 => true}, ""}

  iex> BIPF.loads(BIPF.dumps(%{123 => false}))
  {:ok, %{123 => false}, ""}


  # iex> BIPF.loads(250a7b0e00)
  # {ok, {123:false}, ""}

  # iex> BIPF.loads(3d11abcd1c0a7b06)
  # {ok, {#ABCD#:[123,null]}, ""}

  """
  @spec loads(binary()) :: {:ok, any(), binary()} | {:error, atom}
  def loads(binary) do
    try do
      loading(binary)
    rescue
      FunctionClauseError -> {:error, :bipf_function_clause_error}
      MatchError -> {:error, :bipf_match_error}
    end
  end

  defp loading(binary) when is_binary(binary) do
    case BIPF.Decoder.decode(binary) do
      {value, rest} -> {:ok, value, rest}
      _other -> {:error, :bipf_decoder_error}
    end
  end

  defp loading(_value), do: {:error, :cannot_decode_non_binary_values}
end
