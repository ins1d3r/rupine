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
    res = compile(source)
    @r.execute_script(res)
  end

  def test_defines_variable
    compile_and_execute("study()\na = 3")
    assert @r.contexts[0].defined?('a')
    assert_equal({type: :integer, value: 3}, @r.contexts[0].get('a'))
  end

  def test_define_with_offset
    compile_and_execute("study()\na = 3 + 3\nb=a[1]")
    refute_nil @r.contexts[0].get('b')[:offset]
  end

  def test_plot
    compile_and_execute("study()\na = 3 + 3\nplot(a)")
    assert_equal 6, @r.events.first[:value]
  end

  def test_sma
    source = "study()\nplot(sma(close, 4))"
    values = [1, 2, 3, 4, 5, 6, 7]
    res = compile(source)
    6.times do
      @r.execute_script(res, {close: {type: :integer, value: values.shift}})
    end
    assert_equal 4.5, @r.events.first[:value]
  end

  def test_sma_with_offset
    source = "study()\nplot(sma(close, 4)[1])"
    values = [1, 2, 3, 4, 5, 6, 7]
    res = compile(source)
    6.times do
      @r.execute_script(res, {close: {type: :integer, value: values.shift}})
    end
    assert_equal 3.5, @r.events.first[:value]
  end

  def test_sma_with_param_offset
    source = "study()\nplot(sma(close[1], 4))"
    values = [1, 2, 3, 4, 5, 6, 7]
    res = compile(source)
    6.times do
      @r.execute_script(res, {close: {type: :integer, value: values.shift}})
    end
    assert_equal 3.5, @r.events.first[:value]
  end

  def test_variable_double_offset
    source = "study()\na = close[1]\nplot(a[1])"
    values = [1, 2, 3, 4, 5, 6, 7]
    res = compile(source)
    6.times do
      @r.execute_script(res, {close: {type: :integer, value: values.shift}})
    end
    assert_equal 4, @r.events.first[:value]
  end

  def test_if
    source = <<SRC
study()
if(true)
    a = 3
else
    a = 6
SRC
    compile_and_execute(source)
    assert @r.contexts[0].defined?('a')
    assert_equal({type: :integer, value: 3}, @r.contexts[0].get('a'))
  end
end