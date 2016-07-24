defmodule CodepagexIconvChart do
  @parallellism [1, 4, 20, 50]

  def main do
    _ = Codepagex.from_string!("æøå", :iso_8859_1) # load codepagex
    _ = :iconv.convert("utf-8", "iso-8859-1", "æøå")

    IO.puts Enum.join(~w(processes string_size codepagex iconv_ratio), "\t")
    for p <- @parallellism, s <- string_list do
      size = String.length s
      codepagex =
        take_time_many(p, fn _ -> Codepagex.from_string!(s, :iso_8859_1) end)
        |> time_to_per_megabyte(s)
      iconv =
        take_time_many(p, fn _ -> :iconv.convert("utf-8", "iso-8859-1", s) end)
        |> time_to_per_megabyte(s)
      IO.puts Enum.join([p, size, codepagex, iconv, codepagex / iconv], "\t")
    end
  end

  defp string_list do
    short = "StÆØ"
    1..12
    |> Enum.reduce([short], fn _, acc = [h | _] -> [h <> h | acc] end)
    |> Enum.reverse
  end

  defp time_to_per_megabyte(time, str), do: time / byte_size(str) * 1024 * 1024

  defp take_time_many(parallellism, fun) do
    t0 = take_time(fn -> run_many(parallellism, fn _ -> nil end) end)
    take_time(fn -> run_many(parallellism, fun) end) - t0
  end

  defp run_many(parallellism, fun) do
    n = div(5000, parallellism)
    tasks = for _ <- 1..parallellism, do: Task.async(fn -> Stream.map(1..n, fun) |> Enum.count end)
    Task.yield_many(tasks, 20_000)
    |> Stream.map(fn {_, {:ok, res}} -> res end)
    |> Enum.reduce(&(&1 + &2))
  end

  defp take_time(fun) do
    start = DateTime.utc_now |> DateTime.to_unix(:microseconds)
    _ = fun.()
    stop = DateTime.utc_now |> DateTime.to_unix(:microseconds)
    (stop - start) * 0.000_001
  end
end
