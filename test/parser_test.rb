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
    assert_equal 2, res[:script][0][:args].length
  end

  def test_nested_fun_call
    tokens = @l.lex('study(rsi(8, close))')
    res = @p.parse(tokens)
    assert res[:script][0][:args][0][:type] == :fun_call
  end

  def test_kw_arg
    tokens = @l.lex('study(overlay = false)')
    res = @p.parse(tokens)
    refute_nil res[:script][0][:args][:overlay]
  end

  def test_multiline_stmt
    code = <<END
rsi(close, 14)
cci(ohlc4, 21)

sma(close, 9)
END
    tokens = @l.lex(code)
    res = @p.parse(tokens)
    assert_equal 3, res[:script].size
  end

  def test_simple_binary_operation
    tokens = @l.lex('2 + 2')
    res = @p.parse(tokens)
    assert res[:script][0][:type] == :binary
  end

  def test_complex_binary_operation
    tokens = @l.lex('2 * 4 + 4')
    res = @p.parse(tokens)
    assert res[:script][0][:op] == :plus
    assert res[:script][0][:left][:left][:value] == 2
  end

  def test_complex_binary_operation2
    tokens = @l.lex('(6 + 8) * 4')
    res = @p.parse(tokens)
    assert res[:script][0][:op] == :mul
    assert res[:script][0][:left][:right][:value] == 8
  end

  def test_very_complex_binary
    tokens = @l.lex('5 * ((4-7) / 3 ) + 4')
    res = @p.parse(tokens)
    assert res[:script][0][:op] == :plus
    assert res[:script][0][:left][:right][:left][:right][:value] == 7
    assert res[:script][0][:left][:left][:value] == 5
  end

  def test_unary_minus
    tokens = @l.lex('-10')
    res = @p.parse(tokens)
    assert_equal :unary, res[:script][0][:type]
  end

  def test_unary_minus_in_exp
    tokens = @l.lex('5 + -10')
    res = @p.parse(tokens)
    assert_equal :unary, res[:script][0][:right][:type]
    assert_equal :minus, res[:script][0][:right][:op]
  end

  def test_not_keyword
    tokens = @l.lex('not true')
    res = @p.parse(tokens)
    assert_equal :unary, res[:script][0][:type]
    assert_equal :not, res[:script][0][:op]
  end

  def test_question_mark
    tokens = @l.lex('5 > 2 ? close : open')
    res = @p.parse(tokens)
    assert_equal :question, res[:script][0][:op]
  end

  def test_var_def
    tokens = @l.lex('var1 = 5 + 4')
    res = @p.parse(tokens)
    assert_equal :define, res[:script][0][:type]
    assert_equal 'var1', res[:script][0][:left][:name]
  end

  def test_if
    code = <<~END
      if open > close
          var1 = true
END
    tokens = @l.lex(code)
    res = @p.parse(tokens)
    assert_equal :if, res[:script][0][:type]
  end

  def test_if_else
    code = <<END
if open > close
    var1 = true
else
\t var1 = false
END
    tokens = @l.lex(code)
    res = @p.parse(tokens)
    assert_equal :if, res[:script][0][:type]
    refute_nil res[:script][0][:else]
  end

  def test_for_loop
    code = <<END
for i = 1 to 10
    i = i + 1
END
    tokens = @l.lex(code)
    res = @p.parse(tokens)
    assert_equal :for, res[:script][0][:type]
    assert_equal 1, res[:script][0][:block].size
  end

  def test_fun_def
    code = <<END
my_fun(arg1) =>
    close
END
    tokens = @l.lex(code)
    res = @p.parse(tokens)
    refute_nil res[:user_functions][:my_fun]
    assert_equal 1, res[:user_functions][:my_fun][:block].size
  end

  def test_offset
    tokens = @l.lex('close[1]')
    res = @p.parse(tokens)
    assert_equal 1, res[:script][0][:offset][:value]
  end

  def test_script
    code = <<END
//@version=3
study("RSI Strategy", overlay=true)
length = input( 14 )
overSold = input( 30 )
overBought = input( 70 )
price = close

vrsi = rsi(price, length)

// if (not na(vrsi))
//     if (crossover(vrsi, overSold))
//         strategy.entry("RsiLE", strategy.long, comment="RsiLE")
//     if (crossunder(vrsi, overBought))
//         strategy.entry("RsiSE", strategy.short, comment="RsiSE")

lastDir = na
lastPrice = 0.0
lastDir := na(lastDir[1]) ? na : lastDir[1]
lastPrice := na(lastPrice[1]) ? na : lastPrice[1]

longCondition = not na(vrsi) and crossover(vrsi, overSold) and (na(lastDir) or lastDir == -1)
shortCondition = not na(vrsi) and crossunder(vrsi, overBought) and (na(lastDir) or lastDir == 1)
if(longCondition)
    lastDir := 1
    lastPrice := open
if(shortCondition)
    lastDir := -1
plotarrow(longCondition?1:na)
plotarrow(shortCondition[1] ? -1 : na)

alertcondition(longCondition, title='RSI buy', message='Buy alert')
alertcondition(shortCondition[1], title='RSI sell', message='Sell alert')
END
    tokens = @l.lex(code)
    res = @p.parse(tokens)
    assert_equal 'study', res[:script][0][:name]
  end
end