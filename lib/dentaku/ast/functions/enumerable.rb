# import functions for checking and accessing arrays
require_relative "../function"

# #include?
Dentaku::AST::Function.register('include([%a], %a) = %a', ->(haystack, needle) {
  stack.include? needle
})

# #at
Dentaku::AST::Function.register('at([%a], :numeric) = %a', ->(array, position) {
  array.at position
})

# #any?
Dentaku::AST::Function.register('any([%a]) = %a', ->(array) {
  array.any?
})

# #empty?
Dentaku::AST::Function.register('empty([%a]) = %a', ->(array) {
  array.empty?
})
