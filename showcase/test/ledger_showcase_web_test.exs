defmodule LedgerShowcaseWebTest do
  use ExUnit.Case, async: true
  import Phoenix.ConnTest
  @endpoint LedgerShowcaseWeb.Endpoint

  test "index lists ids and /c/icon renders icons" do
    conn = build_conn() |> get("/")
    assert html_response(conn, 200) =~ "/c/icon"
    conn = build_conn() |> get("/c/icon")
    assert html_response(conn, 200) =~ ~s(data-icon="download")
  end
end
