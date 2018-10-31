require "test_helper"

class LexerTest < Minitest::Test
  def test_lexer_starts
    ::Rupine::Lexer.new
  end

  def test_it_returns_array
    l = ::Rupine::Lexer.new
    assert_instance_of Array, l.lex('2 + 2')
  end

  def test_fun_call
    l = ::Rupine::Lexer.new
    tkns = l.lex('amazing("stuff")')
    assert_equal [
                     {name: :id, value: 'amazing'},
                     {name: :lpar},
                     {name: :string, value: 'stuff'},
                     {name: :rpar}
                 ], tkns
  end

  def test_fun_mul_param
    l = ::Rupine::Lexer.new
    tkns = l.lex('amazing("stuff", 420)')
    assert_equal [
                     {name: :id, value: 'amazing'},
                     {name: :lpar},
                     {name: :string, value: 'stuff'},
                     {name: :comma},
                     {name: :integer, value: 420},
                     {name: :rpar}
                 ], tkns
  end

  def test_int_float
    l = ::Rupine::Lexer.new
    tkns = l.lex('1337 13.37')
    assert_equal [
                     {name: :integer, value: 1337},
                     {name: :float, value: 13.37}
                 ], tkns
  end

  def test_orphan_float
    l = ::Rupine::Lexer.new
    tkns = l.lex('.37')
    assert_equal [
                     {name: :float, value: 0.37}
                 ], tkns
  end

  def test_define
    l = ::Rupine::Lexer.new
    tkns = l.lex('test = "Hello, world!"')
    assert_equal [
         {name: :id, value: 'test'},
         {name: :define},
         {name: :string, value: 'Hello, world!'}
     ], tkns
  end

  def test_binary_operators
    l = ::Rupine::Lexer.new
    tkns = l.lex('true and false or true')
    assert_equal [
                     {name: :true},
                     {name: :and},
                     {name: :false},
                     {name: :or},
                     {name: :true}
                 ], tkns
  end

  def test_comparison_operators
    l = ::Rupine::Lexer.new
    tkns = l.lex('2 < 3 and 5 > 4')
    assert_equal [
                     {name: :integer, value: 2},
                     {name: :lt},
                     {name: :integer, value: 3},
                     {name: :and},
                     {name: :integer, value: 5},
                     {name: :gt},
                     {name: :integer, value: 4}
                 ], tkns
  end

  def test_comparison_equal_operators
    l = ::Rupine::Lexer.new
    tkns = l.lex('2 <= 3 and 5 >= 4')
    assert_equal [
                     {name: :integer, value: 2},
                     {name: :le},
                     {name: :integer, value: 3},
                     {name: :and},
                     {name: :integer, value: 5},
                     {name: :ge},
                     {name: :integer, value: 4}
                 ], tkns
  end

  def test_equal_operator
    l = ::Rupine::Lexer.new
    tkns = l.lex('4 == 4')
    assert_equal [
                     {name: :integer, value: 4},
                     {name: :eq},
                     {name: :integer, value: 4},
                 ], tkns
  end

  def test_not_equal_operator
    l = ::Rupine::Lexer.new
    tkns = l.lex('4 != 4')
    assert_equal [
                     {name: :integer, value: 4},
                     {name: :neq},
                     {name: :integer, value: 4},
                 ], tkns
  end

  def test_newline
    l = ::Rupine::Lexer.new
    code = <<~END
fun_call1('Param1')
fun_call2('Param2')
END
    tkns = l.lex(code)
    assert tkns.include?({name: :newline})
  end
end