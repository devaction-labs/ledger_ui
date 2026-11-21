defmodule Parity.Cases.Forms do
  use Phoenix.Component
  use LedgerUI
  import Parity.Common

  def cases do
    assigns = %{}

    %{
      "input-basic" => ~H"""
      <.colm>
        <.input label="E-mail" placeholder="voce@empresa.com" icon="huge-mail" />
        <.input label="Valor" placeholder="0,00" prefix="R$" suffix="BRL" />
        <.input label="Nome" value="Bompreço" errors={["Campo obrigatório"]} />
        <.input label="Apelido" placeholder="Opcional" optional help="Aparece no recibo" />
      </.colm>
      """,
      "input-states" => ~H"""
      <.colm>
        <.input label="Cupom" value="ORBIT20" icon="huge-tag" state="success" help="Cupom válido: 20% por 3 meses." />
        <.input label="Senha" type="password" value="12345" icon="huge-lock" errors={["Mínimo de 8 caracteres."]} />
        <.input label="Obrigatório" placeholder="Digite" required />
        <.input placeholder="Plain" variant="plain" />
        <.input placeholder="Direita" value="1.234,00" align="right" />
        <.input placeholder="Filled sm" variant="filled" size="sm" />
        <.input placeholder="Pill lg" shape="pill" size="lg" />
        <.input placeholder="Erro sem rótulo" state="error" />
      </.colm>
      """,
      "input-inline-hint" => ~H"""
      <.colm>
        <.input layout="inline" label="Nome" placeholder="Seu nome" />
        <.input layout="inline" label="Valor" placeholder="0,00" prefix="R$" />
        <.input label="Telefone" hint="só números" placeholder="(11) 99999-0000" icon="huge-phone" />
      </.colm>
      """,
      "input-pill-sizes" => ~H"""
      <.colm>
        <.input :for={{v, s} <- for(v <- ~w(outlined filled plain), s <- ~w(sm md lg), do: {v, s})} placeholder={"#{v} #{s}"} variant={v} size={s} />
      </.colm>
      """,
      "input-variants" => ~H"""
      <.colm>
        <.input placeholder="Filled" variant="filled" />
        <.input placeholder="Small" size="sm" />
        <.input placeholder="Large" size="lg" />
        <.input placeholder="Pill" shape="pill" />
        <.input placeholder="Desabilitado" disabled />
      </.colm>
      """
    }
  end
end
