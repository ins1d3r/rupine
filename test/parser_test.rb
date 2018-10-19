require 'test_helper'

class ParserTest < Minitest::Test
  def initialize(_)
    super
    @p = Rupine::Parser.new
  end

  def test_it_returns_something
    tokens = [{:name=>:id, :value=>"study"}, {:name=>:lpar}, {:name=>:rpar}]
    res = @p.parse(tokens)
    refute_empty res
  end

  def test_multipar_fun_call
    tokens = [{:name=>:id, :value=>"study"}, {:name=>:lpar}, {:name=>:id, :value=>"var1"}, {:name=>:comma}, {:name=>:id, :value=>"var2"}, {:name=>:rpar}]
    res = @p.parse(tokens)
    assert res[0][:args].length == 2
  end

  def test_nested_fun_call
    tokens = [{:name=>:id, :value=>"study"}, {:name=>:lpar}, {:name=>:id, :value=>"rsi"}, {:name=>:lpar}, {:name=>:integer, :value=>8}, {:name=>:comma}, {:name=>:id, :value=>"close"}, {:name=>:rpar}, {:name=>:rpar}]
    res = @p.parse(tokens)
    assert res[0][:args][0][:type] == :fun_call
  end
end