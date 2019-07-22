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

  def wma(args, offset)
    norm = 0.0
    sum = 0.0
    length = real_execute(args[1], offset)
    (0..length-1).each do |i|
      value = real_execute(args[0], i+offset)
      return nil if value.nil?
      weight = (length - i) * length
      norm = norm + weight
      sum = sum + value * weight
    end
    sum / norm
  end
end