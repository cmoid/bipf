defmodule BIPF do
  @moduledoc """
  SPDX-License-Identifier: GPL-2.0-only
  Copyright (C) 2023 Charles Moid

  BIPF (Binary In Place Format) is an implementaion of [BIPF.tinySSB](https://github.com/ssbc/sips/blob/master/011.md),
  a binary serialization format for JSON designed for optimal use in memory.

  ## Examples

  iex> BIPF.loads(BIPF.dumps(nil))
  {:ok, nil, ""}

  iex> BIPF.loads(BIPF.dumps("foo"))
  {:ok, "foo", ""}

  iex> BIPF.loads(BIPF.dumps(123))
  {:ok, 123, ""}

  iex> BIPF.loads(BIPF.dumps(-123))
  {:ok, -123, ""}

  iex> BIPF.loads(BIPF.dumps("¥€$!"))
  {:ok, "¥€$!", ""}

  ## let's get two bytes
  iex> BIPF.loads(BIPF.dumps(345))
  {:ok, 345, ""}

  iex> BIPF.loads(BIPF.dumps(-345))
  {:ok, -345, ""}

  ## Now an object
  iex> BIPF.loads(BIPF.dumps(%{123 => true}))
  {:ok, %{123 => true}, ""}

  iex> BIPF.loads(BIPF.dumps(%{123 => false}))
  {:ok, %{123 => false}, ""}

  ## Now a list with ints, booleans, sublists, and objects
  iex> BIPF.loads(BIPF.dumps([123, true, -345, nil, [-345, false, %{57 => true}]]))
  {:ok, [123, true, -345, nil, [-345, false, %{57 => true}]], ""}


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

  iex> Base.encode16(BIPF.dumps([123,true]), case: :lower)
  "240a7b0e01"

  iex> Base.encode16(BIPF.dumps(%{123 => false}), case: :lower)
  "250a7b0e00"

  """
  @spec dumps(any()) :: binary()
  def dumps(v),
    do: BIPF.Encoder.encode(v, <<>>)

  @doc """
  Converts a BIPFencoded binary into native elixir data structures

  ## Examples

  iex> BIPF.loads(<<6>>)
  {:ok, nil, ""}

  iex> Base.decode16("0e00", case: :lower)
  {:ok, <<14, 0>>}

  iex> BIPF.loads(<<14, 0>>)
  {:ok, false, ""}

  iex> Base.decode16("0e01", case: :lower)
  {:ok, <<14, 1>>}

  iex> BIPF.loads(<<14, 1>>)
  {:ok, true, ""}

  iex> Base.decode16("0a7b", case: :lower)
  {:ok, "\n{"}

  ## escape newline, ugh!!!
  iex> BIPF.loads("\\n{")
  {:ok, 123, ""}

  iex> Base.decode16("0a85", case: :lower)
  {:ok, <<10, 133>>}

  iex> BIPF.loads(<<10, 133>>)
  {:ok, -123, ""}

  iex> Base.decode16("39c2a5e282ac2421", case: :lower)
  {:ok, "9¥€$!"}

  iex> BIPF.loads("9¥€$!")
  {:ok, "¥€$!", ""}

  iex> Base.decode16("250a7b0e00", case: :lower)
  {:ok, <<37, 10, 123, 14, 0>>}

  iex> BIPF.loads(<<37, 10, 123, 14, 0>>)
  {:ok, %{123 => false}, ""}

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
