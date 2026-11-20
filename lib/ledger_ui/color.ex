defmodule LedgerUI.Color do
  @moduledoc """
  Paleta semântica compartilhada (Button, Badge, Card, Avatar…). `light` is `white`; `current` follows the text colour of the parent.

  Cada cor define quatro variáveis locais lidas pelas variantes:
  `--c` (cheia), `--c-on` (texto sobre a cheia), `--c-soft` (fundo suave) e `--c-ink` (texto colorido).
  """

  @colors %{
    "neutral" =>
      "[--c:var(--lu-ink)] [--c-on:var(--lu-on-inverse)] [--c-soft:var(--lu-bg-sunken)] [--c-ink:var(--lu-ink)]",
    "primary" =>
      "[--c:var(--lu-teal-600)] [--c-on:var(--lu-on-accent)] [--c-soft:var(--lu-accent-soft)] [--c-ink:var(--lu-accent-ink)]",
    "secondary" =>
      "[--c:var(--lu-violet)] [--c-on:#fff] dark:[--c-on:#0e100f] [--c-soft:var(--lu-violet-soft)] [--c-ink:var(--lu-violet)]",
    "info" =>
      "[--c:var(--lu-info)] [--c-on:#fff] dark:[--c-on:#0e100f] [--c-soft:var(--lu-info-soft)] [--c-ink:var(--lu-info)]",
    "success" =>
      "[--c:var(--lu-pos)] [--c-on:#fff] dark:[--c-on:#0e100f] [--c-soft:var(--lu-pos-soft)] [--c-ink:var(--lu-pos)]",
    "warning" =>
      "[--c:var(--lu-warn)] [--c-on:#fff] dark:[--c-on:#0e100f] [--c-soft:var(--lu-warn-soft)] [--c-ink:var(--lu-warn)]",
    "error" =>
      "[--c:var(--lu-neg)] [--c-on:#fff] dark:[--c-on:#0e100f] [--c-soft:var(--lu-neg-soft)] [--c-ink:var(--lu-neg)]",
    "dark" =>
      "[--c:#141514] dark:[--c:#f2f3f2] [--c-on:#fff] dark:[--c-on:#141514] [--c-soft:#2a2e2c] [--c-ink:#141514] dark:[--c-ink:#f2f3f2]",
    "white" => "[--c:#fff] [--c-on:#141514] [--c-soft:#f4f4f2] [--c-ink:#141514]",
    "lime" =>
      "[--c:var(--lu-lime)] [--c-on:#0e100f] [--c-soft:var(--lu-lime-soft)] [--c-ink:var(--lu-lime)]",
    "light" => "[--c:#fff] [--c-on:#141514] [--c-soft:#f4f4f2] [--c-ink:#141514]",
    "mono" =>
      "[--c:var(--lu-ink)] [--c-on:var(--lu-bg-page)] [--c-soft:var(--lu-bg-sunken)] [--c-ink:var(--lu-ink)]",
    "current" =>
      "[--c:currentColor] [--c-on:var(--lu-bg-page)] [--c-soft:transparent] [--c-ink:currentColor]"
  }

  def names, do: Map.keys(@colors)
  def vars(color), do: Map.fetch!(@colors, color)
end
