module StdLib
  def exp(args, offset)
    Math.exp(real_execute(args[0], offset))
  end

  def pow(args, offset)
    real_execute(args[0], offset) ** real_execute(args[1], offset)
  end
end