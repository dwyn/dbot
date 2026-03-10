defmodule DbotWeb.PageController do
  use DbotWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
