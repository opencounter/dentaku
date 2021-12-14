require 'spec_helper'
require 'dentaku/ast/functions/default'

describe Dentaku::AST::Default do
  let(:tracer) { Dentaku::HashTracer.new }
  let(:calculator) { Dentaku::Calculator.new.tap { |c| c.tracer = tracer } }
  let(:expression) do
    'default(a, 100)'
  end
  let(:ast) { calculator.ast(expression) }
  let(:evaluation) { calculator.evaluate!(ast, data) }

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

    it "surfaces identifiers" do
      evaluation
      expect(tracer.unsatisfied).to include("a")
    end
  end
end
