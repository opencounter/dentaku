# import functions for creating and accessing hashes
require_relative "../function"

require 'json'

# Hash.new, to JSON
Dentaku::AST::Function.register('hash([%a]) = :string', -> (args) {
  return {}.to_json if args.empty?
  args.flatten.each_slice(2).each_with_object({}) do |(key, value), memo|
    memo[key] = value
  end.to_json
})

# Get a value, always falling back to false
Dentaku::AST::Function.register('get(:string, :string) = %a', -> (json, key) {
  JSON.parse(json).fetch(key) { false }
})

# Hash.fetch: get a value, with a configurable fallback
Dentaku::AST::Function.register('fetch(:string, :string, %a) = %a', -> (json, key, fallback) {
  JSON.parse(json).fetch(key) { fallback }
})

# Hash.key? - check if key is present
Dentaku::AST::Function.register('key(:string, :string) = %a', -> (json, key) {
  JSON.parse(json).key?(key)
})

# Hash.value? - check if value is present
Dentaku::AST::Function.register('value(:string, :string) = %a', -> (json, value) {
  JSON.parse(json).value?(value)
})
