require 'securerandom'

module Rupine
  class Parser
    class EOFError < StandardError
      def initialize(msg, expected=false)
        super(msg)
      end
    end

    # Operator precendence
    OP_PREC = {
        question: 10,
        colon: 11,
        or: 20,
        and: 30,
        eq: 40, neq: 40,
        lt: 50, gt: 50, le: 50, ge: 50,
        plus: 60, minus: 60,
        mul: 70, div: 70, mod: 70
    }
    def initialize
        @current_tokens = []
    end

    def parse(tokens)
      raise 'Not an array of tokens' unless tokens.is_a? Array
      @current_tokens = tokens
      @inputs = {}
      @plots = []
      @user_functions = {}
      # Script is a set of statements
      script = parse_statement(0)

      tvscript = {
          inputs: @inputs,
          plots: @plots,
          user_functions: @user_functions,
          script: script
      }

      # Reset all variables
      @current_tokens = []
      @inputs = {}
      @plots = []
      @user_functions = {}
      # TODO: extract fun_defs
      # TODO: Assign unique id to plots and inputs
      tvscript
    end

    protected

    # Statement is a set of expressions
    def parse_statement(depth)
      current_depth = 0
      expressions = []
      # One expression per line
      loop do
        
        # Count indentation of current line
        loop do
          break unless peek_token(current_depth) && peek_token(current_depth)[:name] == :indent
          current_depth += 1
        end

        if current_depth == depth
          # We are still in our block
          current_depth.times {next_token}
        else
          # We are out of the block
          @current_tokens.unshift({name: :newline})
          break
        end

        # Remove all empty lines
        loop { (!eof && peek_token[:name] == :newline) ? next_token : break }
        break if eof

        # Check if we have any flow-control statements
        case peek_token[:name]
        when :if
          next_token
          condition = try_math(parse_expression)
          next_token if peek_token[:name] == :newline
          then_block = parse_statement(depth+1)
          next_token if peek_token[:name] == :newline
          if !eof && peek_token[:name] == :else
            next_token
            next_token if peek_token[:name] == :newline
            else_block = parse_statement(depth+1)
          else
            @current_tokens.unshift({name: :newline})
            else_block = nil
          end
          stmt = {type: :if, cond: condition, then: then_block, else: else_block}
        when :for
          # Loop syntax: for i = 0 to 10
          # Skip `for` token
          next_token
          var_def = parse_expression
          raise unless var_def[:type] == :define
          raise unless peek_token[:name] == :to
          next_token
          to = try_math(parse_expression)
          next_token if peek_token[:name] == :newline
          block = parse_statement(depth+1)
          stmt = {type: :for, var: var_def, to: to, block: block}
        else
          stmt = try_math(parse_expression)
          if !eof && stmt[:type] == :fun_call && depth == 0 && peek_token[:name] == :arrow
            # Rewrite fun_call with fun_def
            next_token
            next_token if peek_token[:name] == :newline
            block = parse_statement(depth+1)
            @user_functions[stmt[:name].to_sym] = {args: stmt[:args], block: block}
            stmt = nil # To skip it from adding to array
          elsif !eof && peek_token[:name] == :arrow
            raise
          end
        end
        expressions << stmt if stmt
        # Now we should meet newline bc one expression per line
        if !eof && peek_token[:name] == :newline
          next_token
          current_depth = 0
        elsif !eof
          raise
        end
      end
      expressions
    end

    # Expression is function call or binary operation
    def parse_expression
      tkn = next_token
      nxt = (!eof && peek_token[:name]) || nil
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
          # Extract input to script header
          if current_node[:name] == 'input'
            input = {}
            input[:defval] = current_node[:args][0] || current_node[:args][:defval] || nil
            input[:title] = current_node[:args][1] || current_node[:args][:title] || ''
            id = SecureRandom.hex(4)
            current_node[:id] = id
            @inputs[id] = input

          # Extract plot id to script header
          elsif current_node[:name] == 'plot'
            id = SecureRandom.hex(4)
            @plots << id
            current_node[:id] = id
          end
        elsif nxt == :define || nxt == :assign
          # Its variable assignment
          next_token # To drop define operator
          # TODO: Clarify this statement
          current_node = {type: :define, left: {type: :var, name: tkn[:value]}, right: try_math(parse_expression)}
        else
          # Seems that we have a variable call
          current_node = {type: :var, name: tkn[:value]}
        end
        if %i[fun_call var].include?(current_node[:type]) && !eof && peek_token[:name] == :lsqbr
          # Skip the bracket
          next_token
          offset = try_math(parse_expression)
          current_node[:offset] = offset
          if peek_token[:name] == :rsqbr
            next_token
          else
            raise
          end
        end
      elsif tkn[:name] == :integer || tkn[:name] == :string || tkn[:name] == :float
        # Just return the constent
        current_node = {type: tkn[:name], value: tkn[:value]}
        if !eof && peek_token[:name] == :lsqbr
          # Skip the bracket
          next_token
          offset = try_math(parse_expression)
          current_node[:offset] = offset
          if peek_token[:name] == :rsqbr
            next_token
          else
            raise
          end
        end
        # We don't need to modify current node, because constants are the same across bars
      elsif tkn[:name] == :minus || tkn[:name] == :plus || tkn[:name] == :not
        # We are dealing with unary operation
        current_node = try_math({
            type: :unary,
            op: tkn[:name],
            value: try_math(parse_expression, 80)
        })
      elsif tkn[:name] == :true || tkn[:name] == :false
        current_node = {type: tkn[:name]}
      # elsif tkn[:name] == :question
      #   # Drop the question mark
      #   next_token
      #   left = try_math(parse_expression, 10)
      #   if !eof && peek_token[:name] == :colon
      #     next_token
      #   else
      #     # TODO: Forgotten colon
      #     raise
      #   end
      #   right = try_math(parse_expression)
      #   current_node = {type: :cond, cond: current_node, left: left, right: right}
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
          # TODO: Forgotten rpar
          raise
        end
        exp
      elsif token[:name] == :newline
        # Seems that we have splitted expression
        next_token
      # elsif token[:name] == :indent
      #   # Seems that we have ...
      #   next_token
      #   return
      else
        # TODO: Looks like unexpected token
        raise
      end
    end

    # Arguments are comma separated statements or assignments
    def parse_arguments
      args = {}
      loop do
        nxt = peek_token[:name]
        nxt = next_token[:name] if nxt == :comma # TODO: Throw exception if there was no comma after argument
        break if nxt == :rpar # There was no arguments
        arg = try_math(parse_expression)
        type = arg[:type]
        if %i[define true false integer float string var fun_call binary unary].include? type
          if type == :define
            args[arg[:left][:name].to_sym] = arg[:right]
          else
            args[args.size] = arg
          end
        else
          # You've passed some shit as an argument
          raise
        end

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
        # FIXME: nested ?: operators
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

    def peek_token(offset = 0)
      @current_tokens[offset]
    end

    def next_token
      @current_tokens.shift
    end

    def eof
      @current_tokens.size == 0
    end
  end
end