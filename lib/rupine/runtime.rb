require 'rupine/runtime/context'

require_relative 'runtime/stdlib/stdlib'
module Rupine
  class Runtime

    include StdLib
    attr_reader :contexts, :events

    OUTPUT_FUNCTIONS = %w[plot plotshape]

    def initialize
      @events = []
      @contexts = []
    end

    def execute_script(tvscript, context={})
      # Reset all variables
      @events = []
      @contexts.unshift(Rupine::Context.new(context))
      # Execute top-level block
      # Raise if first statement is not +study+ or +strategy+
      raise unless %w[study strategy].include? tvscript[:script][0][:name]
      execute_block(tvscript[:script])
    end

    def execute_block(block)
      return unless block.is_a? Enumerable
      # Execute each statement
      block.each do |stmt|
        execute_statement(stmt)
      end
    end

    def execute_statement(tree)
      # Check if we have flow control statement
      if tree[:type] == :if
        real_execute(tree[:cond]) ? execute_block(tree[:then]) : execute_block(tree[:else])
      elsif tree[:type] == :for

      elsif tree[:type] == :fun_def

      else
        execute_expression(tree)
        # Otherwise execute expression
      end
    end

    def execute_expression(stmt)
      if stmt[:type] == :fun_call && OUTPUT_FUNCTIONS.include?(stmt[:name])
        real_execute(stmt)
      elsif stmt[:type] == :define
        # We cannot define with define by the rules of the Pine
        raise if stmt[:right][:type] == :define

        # This variable is already defined
        raise if @contexts[0].defined?(stmt[:left][:name])

        @contexts[0].set(stmt[:left][:name], stmt[:right])
        nil
      else
        stmt
      end
    end

    def real_execute(stmt, offset=0)
      offset = stmt[:offset].nil? ? offset : real_execute(stmt[:offset], offset) + offset
      # Function call
      if stmt[:type] == :fun_call
        if stmt[:name] == 'plot'
          event = { plot_id: stmt[:id], value: real_execute(stmt[:args][0])}
          @contexts[0].set_plot(event)
          @events << event
        elsif stmt[:name] == 'sma' || stmt[:name] == 'wma'
          return send(stmt[:name], stmt[:args], offset)
        end

      # Variable call
      elsif stmt[:type] == :var
        return nil if @contexts[offset].nil?
        raise unless @contexts[offset].defined?(stmt[:name])

        return real_execute(@contexts[offset].get(stmt[:name]), offset)

      # Constant :integer, :string, :float
      elsif %i[integer string float].include? stmt[:type]
        return stmt[:value]
      elsif stmt[:type] == :true
        return true
      elsif stmt[:type] == :false
        return false
      # Binary
      elsif stmt[:type] == :binary
        left = real_execute(stmt[:left], offset)
        right = real_execute(stmt[:right], offset)
        return nil if left.nil? || right.nil?
        case stmt[:op]
        when :plus
          return left + right
        when :minus
          return left - right
        when :div
          return left / right
        when :mul
          return left * right
        # TODO: add other binary operations
        else
          # Unknown binary operator
          raise
        end
      # Unary
      elsif stmt[:type] == :unary

      end
      # Return nil if nothing else was returned for sure
      nil
    end
  end
end