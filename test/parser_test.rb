require 'test_helper'

class ParserTest < Minitest::Test
  def initialize(_)
    super
    @l = Rupine::Lexer.new
    @p = Rupine::Parser.new
  end

  def test_it_returns_something

    tokens = @l.lex('study()')
    res = @p.parse(tokens)
    refute_empty res
  end

  def test_multipar_fun_call
    tokens = @l.lex('study(var1, var2)')
    res = @p.parse(tokens)
    assert res[0][:args].length == 2
  end

  def test_nested_fun_call
    tokens = @l.lex('study(rsi(8, close))')
    res = @p.parse(tokens)
    assert res[0][:args][0][:type] == :fun_call
  end

  def test_simple_binary_operation
    tokens = @l.lex('2 + 2')
    res = @p.parse(tokens)
    assert res[0][:type] == :binary
  end

  def test_complex_binary_operation
    tokens = @l.lex('2 * 4 + 4')
    res = @p.parse(tokens)
    assert res[0][:op] == :plus
    assert res[0][:left][:left][:value] == 2
  end

  def test_complex_binary_operation2
    tokens = @l.lex('(6 + 8) * 4')
    res = @p.parse(tokens)
    assert res[0][:op] == :mul
    assert res[0][:left][:right][:value] == 8
  end

  def test_very_complex_binary
    tokens = @l.lex('5 * ((4-7) / 3 ) + 4')
    res = @p.parse(tokens)
    assert res[0][:op] == :plus
    assert res[0][:left][:right][:left][:right][:value] == 7
    assert res[0][:left][:left][:value] == 5
  end

  def test_unary_minus
    tokens = @l.lex('-10')
    res = @p.parse(tokens)
    assert_equal :unary, res[0][:type]
  end

  def test_unary_minus_in_exp
    tokens = @l.lex('5 + -10')
    res = @p.parse(tokens)
    assert_equal :unary, res[0][:right][:type]
    assert_equal :minus, res[0][:right][:op]
  end

  def test_not_keyword
    tokens = @l.lex('not true')
    res = @p.parse(tokens)
    assert_equal :unary, res[0][:type]
    assert_equal :not, res[0][:op]
  end
end