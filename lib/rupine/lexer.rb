module Rupine
  class Lexer

    TOKENS = [
        {id: :id, rx: /[a-zA-Z][a-zA-Z0-9]*/, value: ->(value){value}},
        {id: :lpar, rx: /\(/},
        {id: :rpar, rx: /\)/},
        {id: :comma, rx: /,/},
        {id: :plus, rx: /\+/},
        {id: :string, rx:/"[a-zA-Z0-9]*"/, value: ->(value){value[1..-2]}},
        {id: :number, rx:/[0-9]+/, value: ->(value){value.to_i}},
        {id: :whitespace, rx:/\s+/}
    ]
    def lex(code)
      src = code.dup
      tokens = []
      # Prepare code for lexing

      # Separate code to tokens
      current_token = ''
      while src.length > 0
        TOKENS.each do |token_def|
          if (token_def[:rx] =~ src) == 0
            token = {name: token_def[:id]}
            match = token_def[:rx].match(src)[0]
            token[:value] = token_def[:value].call(match) if token_def[:value]
            src = src[match.size..-1]
            tokens << token
            next
          end
        end
        # raise 'Unknown token at: ' + src
      end

      tokens
    end
  end
end