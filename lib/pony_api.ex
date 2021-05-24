defmodule Maze.PonyApi do
  def get_map_id() do
    id =
      HTTPoison.post!(
        "https://ponychallenge.trustpilot.com/pony-challenge/maze",
        init_json_values(),
        [{"Content-Type", "application/json"}]
      )
      |> convert_from_json
      |> get_id

    IO.puts("Map ID: #{id}")
    id
  end

  def move_pony(maze_id, direction) do
    resp =
      HTTPoison.post!(
        "https://ponychallenge.trustpilot.com/pony-challenge/maze/#{maze_id}",
        Jason.encode!(%{"direction" => direction}),
        [{"Content-Type", "application/json"}]
      )

    resp
    |> convert_from_json
    |> is_valid_move(direction)

    resp
  end

  def print_maze(maze_id) do
    HTTPoison.get!("https://ponychallenge.trustpilot.com/pony-challenge/maze/#{maze_id}/print")
    |> get_body
    |> IO.puts()
  end

  def get_current_state(maze_id) do
    HTTPoison.get!("https://ponychallenge.trustpilot.com/pony-challenge/maze/#{maze_id}")
    |> get_body
    |> Jason.decode!
  end

  ## Private methods

  defp init_json_values(width \\ 25, height \\ 25, pony_name \\ "Applejack", difficulty \\ 10) do
    Jason.encode!(%{
      "maze-width" => width,
      "maze-height" => height,
      "maze-player-name" => pony_name,
      "difficulty" => difficulty
    })
  end

  defp convert_from_json(%HTTPoison.Response{body: body}), do: Jason.decode!(body)
  defp get_body(%HTTPoison.Response{body: body}), do: body
  defp get_id(%{"maze_id" => maze_id}), do: maze_id

  defp is_valid_move(%{"state-result" => "You won. Game ended"}, direction) do
    IO.puts("Moving #{direction} is winning move")
  end

  defp is_valid_move(%{"state-result" => "You lost. Killed by monster"}, direction) do
    IO.puts("Moving #{direction} is loss. Killed by monster")
  end

  defp is_valid_move(%{"state-result" => "Can't walk in there"}, direction) do
    IO.puts("Moving #{direction} is invalid")
  end

  defp is_valid_move(%{"state-result" => "Move accepted"}, direction) do
    IO.puts("Moved #{direction}")
  end

end
