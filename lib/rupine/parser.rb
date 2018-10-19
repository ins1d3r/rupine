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
        tvscript << try_math(parse_expression)
      end
      @current_tokens = []
      puts tvscript
      tvscript
    end

    # Expression is function call or binary operation
    def parse_expression
      tkn = next_token
      nxt = peek_token[:name] unless eof
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
          # try_math(parse_expression)
          # TODO:
        else
          # Seems that we have a variable call
          current_node = {type: :var, name: tkn[:value]}
        end
      elsif tkn[:name] == :integer
        # Just return the integer
        current_node = {type: :integer, value: tkn[:value]}
      else
        current_node = parse_punctuation(tkn)
      end

      current_node
    end

    def parse_punctuation(token)
      if token[:name] == :lpar
        exp = try_math(parse_expression)
        if peek_token[:name] == :rpar
          next_token
        else
          raise
        end
        exp
      else
        raise
      end
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

    def try_math(left, precendence = 0)
      return left if eof
      nxt = peek_token[:name]
      if OP_PREC.keys.include? nxt and OP_PREC[nxt] > precendence
        next_token
        return try_math({
            type: :binary,
            op: nxt,
            left: left,
            right: try_math(parse_expression, OP_PREC[nxt])
        }, precendence)
      end
      left
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