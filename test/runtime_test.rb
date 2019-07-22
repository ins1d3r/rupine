require 'test_helper'

class RuntimeTest < Minitest::Test
  def setup
    super
    @l = Rupine::Lexer.new
    @p = Rupine::Parser.new
    @r = Rupine::Runtime.new
  end

  def compile(source)
    tokens = @l.lex(source)
    @p.parse(tokens)
  end

  def compile_and_execute(source)
    tokens = @l.lex(source)
    res = @p.parse(tokens)
    @r.execute_script(res)
  end

  def test_defines_variable
    compile_and_execute('a = 3')
    assert @r.contexts[0].defined?('a')
    assert_equal 3, @r.contexts[0].get('a')
  end

  def test_defines_math_variable
    compile_and_execute('a = 3 + 3')
    assert_equal 6, @r.contexts[0].get('a')
  end

  def test_define_variable_with_offset
    compile_and_execute("a = 3 + 3\nb=a[1]")
    assert_nil @r.contexts[0].get('b')
  end

  def test_plot
    compile_and_execute("a = 3 + 3\nplot(a)")
    assert_equal 6, @r.events.first[:value]
  end

  def test_sma
    source = 'plot(sma(close, 4))'
    values = [1, 2, 3, 4, 5, 6, 7]
    tokens = @l.lex(source)
    res = @p.parse(tokens)
    6.times do
      @r.execute_script(res, {close: {type: :integer, value: values.shift}})
    end
    assert_equal 4.5, @r.events.first[:value]
  end

  def test_sma_with_offset
    source = 'plot(sma(close, 4)[1])'
    values = [1, 2, 3, 4, 5, 6, 7]
    tokens = @l.lex(source)
    res = @p.parse(tokens)
    6.times do
      @r.execute_script(res, {close: {type: :integer, value: values.shift}})
    end
    assert_equal 3.5, @r.events.first[:value]
  end

  def test_sma_with_param_offset
    source = 'plot(sma(close[1], 4))'
    values = [1, 2, 3, 4, 5, 6, 7]
    tokens = @l.lex(source)
    res = @p.parse(tokens)
    6.times do
      @r.execute_script(res, {close: {type: :integer, value: values.shift}})
    end
    assert_equal 3.5, @r.events.first[:value]
  end

  def test_variable_double_offset
    source = "a = close[1]\nplot(a[1])"
    values = [1, 2, 3, 4, 5, 6, 7]
    tokens = @l.lex(source)
    res = @p.parse(tokens)
    6.times do
      @r.execute_script(res, {close: {type: :integer, value: values.shift}})
    end
    assert_equal 4, @r.events.first[:value]
  end
end