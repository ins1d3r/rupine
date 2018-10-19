module Rupine
  class Parser
    # Operator precendence
    OP_PREC = {
        or: 20,
        and: 30,
        eq: 40, neq: 40,
        lt: 50, gt: 50, lte: 50, gte: 50,
        plus: 60, minus: 60,
        mul: 70, div: 70, mod: 70
    }
    def initialize
        @current_tokens = []
    end

    def parse(tokens)
      raise 'Not an array of tokens' unless tokens.is_a? Array
      @current_tokens = tokens
      # Script is a set of statements
      tvscript= []
      until eof
        tvscript << parse_expression
      end
      @current_tokens = []
      puts tvscript
      tvscript
    end

    # Expression is function call or binary operation
    def parse_expression
      tkn = next_token
      nxt = peek_token[:name]
      current_node = nil
      if tkn[:name] == :id
        # Its function call or assignment
        if nxt == :lpar # (
          # Its function call
          next_token # To drop parenthesis
          current_node = {
            type: :fun_call,
            name: tkn[:value],
            args: parse_arguments
          }
        elsif nxt == :define
          # Its variable assignment
          next_token # To drop define operator
          parse_expression
        else
          # Seems that we have a variable call
          current_node = {type: :var, name: tkn[:value]}
        end
      elsif tkn[:name] == :integer
        # Just return the integer
        current_node = {type: :integer, value: tkn[:value]}
      end
      nxt = peek_token
      if OP_PREC.include? nxt
        # We are in a big trouble

      end
      current_node
    end

    # Arguments are comma separated statements or assignments
    def parse_arguments
      args = []
      loop do
        nxt = peek_token[:name]
        nxt = next_token[:name] if nxt == :comma # TODO: Throw exception if there was no comma after argument
        break if nxt == :rpar # There was no arguments
        arg = parse_expression
        # TODO: add keyword support and index of argument
        args << arg
        break if nxt == :rpar # We've done parsing arguments
        break if eof # Looks like we've forgot closing parenthesis TODO: Throw exception
      end
      next_token # To drop right parenthesis
      args
    end

    def peek_token
      @current_tokens[0]
    end

    def next_token
      @current_tokens.shift
    end

    def eof
      @current_tokens.size == 0
    end
  end
end