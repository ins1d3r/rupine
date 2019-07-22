require_relative 'stdlib'

module StdLib
  def sma(args, offset)
    length = real_execute(args[1], offset)
    series = (0..length-1).collect do |i|
      real_execute(args[0], i+offset)
    end
    return nil if series.include? nil
    series.reduce(:+) / length.to_f
  end

  def wma()

  end
end