require "test_helper"

class RupineTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Rupine::VERSION
  end

  def test_it_does_something_useful
    assert true
  end

  def test_lexer_starts
    ::Rupine::Lexer.new
  end

  def test_lexer_returns_array
    l = ::Rupine::Lexer.new
    assert_instance_of Array, l.lex('2 + 2')
  end

  def test_lexer_fun_call
    l = ::Rupine::Lexer.new
    tkns = l.lex('amazing("stuff")')
    assert_equal [
      {name: :id, value: 'amazing'},
      {name: :lpar},
      {name: :string, value: 'stuff'},
      {name: :rpar}
     ], tkns
  end

  def test_lexer_fun_mul_param
    l = ::Rupine::Lexer.new
    tkns = l.lex('amazing("stuff",420)')
    assert_equal [
       {name: :id, value: 'amazing'},
       {name: :lpar},
       {name: :string, value: 'stuff'},
       {name: :comma},
       {name: :number, value: 420},
       {name: :rpar}
     ], tkns
  end
end
