ExUnit.start()

defmodule TestHelpers do
  def create_client() do
    Two.new(:test, "WITH_ARMS_WIDE_TOKAN")
  end

  def get_header_value(headers, key) do
    case headers |> Enum.find(&(String.downcase(elem(&1, 0)) == String.downcase(key))) do
      {_, value} when is_binary(value) -> value
      _ -> nil
    end
  end
end
