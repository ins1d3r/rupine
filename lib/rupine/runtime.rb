require 'rupine/runtime/context'

module Rupine
  class Runtime

    attr_reader :contexts, :events

    def initialize
      @events = []
      @contexts = []
    end

    def execute_script(tvscript)
      # Reset all variables
      @events = []
      @contexts.unshift Rupine::Context.new
      # Execute top-level block
      # Raise if first statement is not +study+ or +strategy+
      execute_block(tvscript[:script])
    end

    def execute_block(block)
      # Execute each statement
      block.each do |stmt|
        execute_statement(stmt)
      end
    end

    def execute_statement(tree)
      # Check if we have flow control statement
      if tree[:type] == :if

      elsif tree[:type] == :for

      elsif tree[:type] == :fun_def

      else
        execute_expression(tree)
        # Otherwise execute expression
      end
    end

    def execute_expression(stmt)
      # Function call
      if stmt[:type] == :fun_call

      # Variable define
      elsif stmt[:type] == :define
        # We cannot define with define by the rules of the Pine
        raise if stmt[:right][:type] == :define

        # This variable is already defined
        raise if @contexts[0].defined?(stmt[:left][:name])

        @contexts[0].set(stmt[:left][:name], execute_statement(stmt[:right]))

      # Variable call
      elsif stmt[:type] == :var
        # :offset can be nil - that means we ask for the latest context
        offset = stmt[:offset].nil? ? 0 : execute_statement(stmt[:offset])
        raise unless @contexts[offset].defined?(stmt[:name])

        return @contexts[offset].get(stmt[:name])

      # Constant :integer, :string, :float
      elsif %i[integer string float].include? stmt[:type]
        return stmt[:value]

      # Binary
      elsif stmt[:type] == :binary

      # Unary
      elsif stmt[:type] == :unary

      end
      # Return nil if nothing else was returned for sure
      nil
    end
  end
end