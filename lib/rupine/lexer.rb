module Rupine
  class Lexer

    TOKENS = [
        {id: :comment, rx: /\/\/.*$/},
        {id: :arrow, rx: /=>/},
        {id: :ge, rx: />=/},
        {id: :gt, rx: />/},
        {id: :le, rx: /<=/},
        {id: :lt, rx: /</},
        {id: :eq, rx: /==/},
        {id: :neq, rx: /!=/},
        {id: :define, rx: /=/},
        {id: :assign, rx: /:=/},
        {id: :lpar, rx: /\(/},
        {id: :id, rx: /[a-zA-Z_][a-zA-Z0-9_.]*/, value: ->(value){value}},
        {id: :lpar, rx: /\(/},
        {id: :rpar, rx: /\)/},
        {id: :lsqbr, rx: /\[/},
        {id: :rsqbr, rx: /]/},
        {id: :comma, rx: /,/},
        {id: :plus, rx: /\+/},
        {id: :minus, rx: /-/},
        {id: :mul, rx: /\*/},
        {id: :div, rx: /\//},
        {id: :mod, rx: /%/},
        {id: :question, rx: /\?/},
        {id: :colon, rx: /:/},
        {id: :string, rx:/".*?"/, value: ->(value){value[1..-2]}},
        {id: :string, rx:/'.*?'/, value: ->(value){value[1..-2]}},
        {id: :float, rx:/[0-9]*\.[0-9]+/, value: ->(value){value.to_f}},
        {id: :integer, rx:/[0-9]+/, value: ->(value){value.to_i}},
        {id: :newline, rx: /\R/},
        {id: :indent, rx:/\t| {4}+/},
        {id: :whitespace, rx:/\s+/}
    ]

    KEYWORDS = %w[and or not if else for to continue break true false]

    def lex(code)
      src = code.dup
      tokens = []
      #### Prepare code for lexing
      # Remove comments
      src.gsub!(/\/\/.*$/, "\n")
      # Remove tailing whitespaces
      src.gsub!(/\s*\n/, "\n")

      # Separate code to tokens
      while src.length > 0
        TOKENS.each do |token_def|
          if (token_def[:rx] =~ src) == 0
            token = {name: token_def[:id]}
            match = token_def[:rx].match(src)[0]
            token[:value] = token_def[:value].call(match) if token_def[:value]
            src = src[match.size..-1]
            tokens << token unless %i[whitespace comment].include? token[:name]
            break
          end
        end
      end

      # Replace identifiers with keywords
      tokens.map! do |token|
        if token[:name] == :id and KEYWORDS.include? token[:value]
          {name: token[:value].to_sym}
        else
          token
        end
      end
      tokens
    end
  end
end