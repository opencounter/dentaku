# import all functions from Ruby's Math module
require_relative "../function"

Math.methods(false).each do |method|
  arity = Math.method(method).arity
  next if arity < 0

  arg_type = ([':numeric'] * arity).join(', ')
  Dentaku::AST::Function.register("#{method}(#{arg_type}) = :numeric", ->(*args) {
    Math.send(method, *args)
  })
end

Dentaku::AST::Function.register('log(:numeric, :numeric) = :numeric', ->(x, base) {
  Math.log(x, base)
})

Dentaku::AST::Function.register('ln(:numeric) = :numeric', ->(x) {
  Math.log(x)
})
