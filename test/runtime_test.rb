require 'test_helper'

class RuntimeTest < Minitest::Test
  def setup
    super
    @l = Rupine::Lexer.new
    @p = Rupine::Parser.new
    @r = Rupine::Runtime.new
  end

  def test_defines_variable
    tokens = @l.lex('a = 3')
    res = @p.parse(tokens)
    @r.execute_script(res)
    assert @r.contexts[0].defined?('a')
    assert_equal 3, @r.contexts[0].get('a')
  end
end