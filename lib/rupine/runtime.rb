module Rupine
  class Runtime

    def initialize

    end

    def execute_script(tvscript)
      # Reset all variables
      # Execute top-level block
      execute_block(tvscript)
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
      # Function call :fun_call
      # Variable define :define
      # Variable call :var
      # Constant :integer, :string, :float
      # Binary
      # Unary
    end

  end
end