require 'spec_helper'
require 'dentaku/ast/functions/default'

describe Dentaku::AST::Default do
  let(:calculator) { Dentaku::Calculator.new.tap { |c| c.cache = {} } }
  let(:expression) do
    'default(a, 100)'
  end
  let(:evaluation) { calculator.evaluate!(expression, data) }

  context "with value" do
    let(:data) { { "a" => 10 } }

    it "uses identifiers value" do
      expect(evaluation).to be 10
    end
  end

  context "without value" do
    let(:data) { {} }

    it "uses default value" do
      expect(evaluation).to be 100
    end
  end
end
