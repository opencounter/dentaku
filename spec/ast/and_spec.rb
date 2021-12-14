require 'spec_helper'
require 'dentaku/ast/combinators'

describe Dentaku::AST::And do
  describe 'branch favoring' do
    let(:tracer) { Dentaku::HashTracer.new }
    let(:calculator) { Dentaku::Calculator.new.tap { |c| c.tracer = tracer } }
    let(:expression) do
      'a AND b AND c AND D'
    end

    let(:data) { {} }

    let(:evaluation) { calculator.evaluate!(expression, data) }

    context 'with no dependents' do
      it 'should evaluate in order' do
        expect { evaluation }.to raise_error(Dentaku::UnboundVariableError)
        expect(tracer.unsatisfied).to include("a")
        expect(tracer.unsatisfied).not_to include("b")
      end
    end

    %w[a b c d].each_with_index do |key, i|
      context "with dependent #{i}/4" do
        let(:data) { { key => false } }

        it 'should evaluate existing branches first' do
          expect(evaluation).to be false
          expect(tracer.unsatisfied).to be_empty
          expect(tracer.satisfied).to include(key)
        end
      end
    end

    context "with multiple dependencies" do
      let(:data) { { "a" => true, "b" => false } }

      it "should keep a as a dependency even though it isn't touched" do
        expect(evaluation).to be false
        expect(tracer.unsatisfied).to be_empty
        expect(tracer.satisfied).to include("b")
        expect(tracer.satisfied).to include("a")
      end
    end

    context "using not(...)" do
      let(:expression) { 'not(a) and not(b) and not(c) and not(d)' }
      let(:data) { { 'b' => true } }

      it 'should still hide the unsatisfied dependencies' do
        expect(evaluation).to be false
        expect(tracer.unsatisfied).to be_empty
        expect(tracer.satisfied).to eql Set['b']
      end
    end
  end
end
