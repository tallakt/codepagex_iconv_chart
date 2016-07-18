defmodule Mix.Tasks.Codepagex.IconvChart do
  use Mix.Task

  @shortdoc "Run the benchmark comparing Codepagex and iconv"
  def run(_) do
    :application.ensure_all_started :iconv
    CodepagexIconvChart.main
  end
end
