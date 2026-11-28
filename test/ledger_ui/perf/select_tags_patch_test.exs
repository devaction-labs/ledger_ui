defmodule LedgerUI.Perf.SelectTagsPatchTest do
  # #95 triage: `select` `errors` and `tags_input` `value`, what the client gets again when they change.
  use ExUnit.Case, async: true
  use Phoenix.Component
  import LedgerUI.DiffCase
  import LedgerUI.Components.Select
  import LedgerUI.Components.TagsInput

  @options for i <- 1..5, do: {"Opt #{i}", "o#{i}"}
  @tag_class "group inline-flex cursor-pointer"

  defp count(string, part), do: length(String.split(string, part)) - 1

  defp t_select(assigns) do
    ~H"""
    <.select id="s" name="s" value="a" options={@options} errors={@errors} label={@label} />
    """
  end

  defp t_tags(assigns) do
    ~H"""
    <.tags_input
      id="g"
      name="g"
      value={@value}
      options={@options}
      removable
      loop={@loop}
      loop_text={@loop_text}
      shape={@shape}
    />
    """
  end

  @tags %{value: "o1", options: @options, loop: false, loop_text: nil, shape: "rounded"}

  describe "tags_input value" do
    test "a tag that stays does not send its class again when one is added" do
      patch = patch(&t_tags/1, @tags, value: "o1,o2")

      # Before: the class of every tag (349 B each); now only the one of the new tag.
      assert count(patch, @tag_class) == 1
      # (1_400 before the 24px touch target of the remove button, #122: +133 B on the new tag)
      assert byte_size(patch) < 1_550
      assert patch =~ ~s(data-lu-value=\\"o2\\")
      refute patch =~ ~s(data-lu-value=\\"o1\\")
    end

    test "a tag that goes away sends nothing but the key" do
      patch = patch(&t_tags/1, %{@tags | value: "o1,o2"}, value: "o1")
      assert count(patch, @tag_class) == 0
      assert byte_size(patch) < 700
    end

    test "every source, also the demo loop" do
      each_source(&t_tags/1, @tags, value: "o1,o2", shape: "pill", options: ["x"])
      each_source(&t_tags/1, %{@tags | value: "o1,o2"}, value: "o1", value: "o1,o2,o3")
      each_source(&t_tags/1, %{@tags | value: "o1,o2"}, loop: true)
      each_source(&t_tags/1, %{@tags | loop: true}, loop_text: "typing")
      each_source(&t_tags/1, %{@tags | loop: true, loop_text: "t"}, value: "o1,o2", loop: false)
    end

    test "a repeated value does not break the keys" do
      assert is_binary(patch(&t_tags/1, %{@tags | value: "o1,o1"}, value: "o1,o1,o2"))
    end

    test "the demo loop animates the last tag only" do
      html = html(&t_tags/1, %{@tags | value: "o1,o2,o3", loop: true})
      assert count(html, "animate-[mo-stg_6s") == 1
      assert html =~ ~r/animate-\[mo-stg_6s[^"]*"[^>]*data-lu-value="o3"/
      assert count(html(&t_tags/1, %{@tags | value: "o1,o2"}), "animate-[mo-stg_6s") == 0
    end
  end

  describe "select errors" do
    @sel %{options: @options, errors: [], label: "L"}

    test "with a label, showing an error sends the message and the border, not the list" do
      patch = patch(&t_select/1, @sel, errors: ["ruim"])
      assert patch =~ "ruim"
      refute patch =~ "Opt 1"
      refute patch =~ "shadow-popover"
      assert byte_size(patch) < 1_300
    end

    test "changing one error for another is a small patch" do
      patch = patch(&t_select/1, %{@sel | errors: ["ruim"]}, errors: ["outro"])
      assert patch =~ "outro"
      assert byte_size(patch) < 700
    end

    test "every source" do
      each_source(&t_select/1, @sel, errors: ["ruim"], label: nil)
      each_source(&t_select/1, %{@sel | label: nil}, errors: ["ruim"])
    end

    test "without label, help or errors the field has no wrapper, so the first error draws it" do
      # What stays as it is, and why: `Options.shell` is bare (no wrapper element) until there is
      # something to caption, and a patch cannot turn the content of one template into the content of
      # another: the whole field is sent. A wrapper that is always there would change the default HTML.
      bare = %{@sel | label: nil}
      patch = patch(&t_select/1, bare, errors: ["ruim"])
      assert patch =~ "Opt 1"
      refute html(&t_select/1, bare) =~ ~s(data-part="field")
      assert html(&t_select/1, %{bare | errors: ["ruim"]}) =~ ~s(data-part="field")
    end
  end
end
