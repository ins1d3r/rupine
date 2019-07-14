module Rupine
  class Context
    def initialize
      @vars = {}
    end

    def get(name)
      @vars[name]
    end

    def set(name, value)
      @vars[name] = value
    end

    def defined?(name)
      @vars.has_key?(name)
    end
  end
end