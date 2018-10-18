module Rupine
  class Parser
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
      until eof
        parse_expression
      end
      @current_tokens = []
    end

    # Expression is function call or binary operation
    def parse_expression
      tkn = next_token
      nxt = peek_token
      if tkn[:name] == :id
        # Its function call or assignment
        if nxt[:name] == :lpar # (
          # Its function call
          next_token # To drop parenthesis
          parse_arguments(tkn)
        elsif nxt[:name] == :define
          # Its variable assignment
          parse_expression
        end
      end
    end

    # Arguments are comma separated statements or assignments
    def parse_arguments(_fun_name)
      args = []
      nxt = peek_token[:name]
      loop do
        break if nxt == :rpar # There was no arguments
        arg = parse_expression
        # TODO: add keyword support and index of argument
        args << arg
        break if nxt == :rpar # We've done parsing arguments
        next_token if nxt == :comma # TODO: Throw exception if there was no comma after argument
        break if eof # Looks like we've forgot closing parenthesis TODO: Throw exception
      end
    end

    def peek_token
      @current_tokens[0]
    end

    def next_token
      @current_tokens.shift
    end

    def eof
      @current_tokens.size > 0
    end
  end
end