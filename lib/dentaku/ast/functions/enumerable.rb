# import functions for checking and accessing arrays
require_relative "../function"

# include?
Dentaku::AST::Function.register('include([%a], %a) = %a', ->(haystack, needle) {
  haystack.include?(needle)
})

# at
Dentaku::AST::Function.register('at([%a], :numeric) = %a', ->(array, position) {
  array.at(position)
})

# any?
Dentaku::AST::Function.register('any([%a]) = %a', ->(array) {
  array.any?
})

# empty?
Dentaku::AST::Function.register('empty([%a]) = %a', ->(array) {
  array.empty?
})

# in (intersection between two arrays)
Dentaku::AST::Function.register(
  'in([%a], [%a]) = :bool', ->(list, values) {
    (list & values).any?
  }
)

# join
Dentaku::AST::Function.register(
  'join([:string], :string) = :string', ->(strings, separator) {
    strings.join(separator)
  }
)

# split
Dentaku::AST::Function.register(
  'split(:string, :string) = [:string]', ->(string, separator) {
    string.split(separator)
  }
)
