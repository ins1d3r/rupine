module Rupine
  class Context
    def initialize(predefined_vars = {})
      @vars = predefined_vars.delete_if{|k, _| !%i[time open close high low n].include? k}
      @plots = []
    end

    def get(name)
      @vars[name.to_sym]
    end

    def set(name, value)
      @vars[name.to_sym] = value
    end

    def set_plot(options)
      @plots << options
    end

    def defined?(name)
      @vars.has_key?(name.to_sym)
    end
  end
end