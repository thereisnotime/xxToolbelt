#!/usr/bin/env elixir
defmodule Template do
    def print(arg) do
        "ARGV #{arg}"
    end
end
for arg <- System.argv do
    IO.puts Template.print(arg)
end
