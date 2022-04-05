require 'spec_helper'
require 'dentaku/ast/combinators'

describe Dentaku::AST::Or do
  let(:tracer) { Dentaku::HashTracer.new }
  let(:calculator) { Dentaku::Calculator.new.tap { |c| c.tracer = tracer } }

  describe 'branch favoring' do
    let(:expression) do
      'a OR b OR c or D'
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
        let(:data) { { key => true } }

        it 'should evaluate existing branches first' do
          expect(evaluation).to be true
          expect(tracer.unsatisfied).to be_empty
          expect(tracer.satisfied).to include(key)
        end
      end
    end

    context "with multiple dependencies" do
      let(:data) { { "a" => false, "b" => true } }

      it "should keep a as a dependency even though it isn't touched" do
        expect(evaluation).to be true
        expect(tracer.unsatisfied).to be_empty
        expect(tracer.satisfied).to include("b")
        expect(tracer.satisfied).to include("a")
      end
    end

    context "when there is no short-circuit available" do
      let(:expression) { 'if(a, b, c) OR if(d, e, f)' }

      context "still surfaces satisfied idents" do
        let(:data) { { 'a' => true, 'b' => false, 'd' => true, 'e' => false } }
        it "records all used variables" do
          expect(evaluation).to be false
          expect(tracer.unsatisfied).to be_empty
          expect(tracer.satisfied).to eql Set[*%w[a b d e]]
        end
      end
    end

    context "it works with not(...)" do
      let(:expression) { 'not(a) or not(b) or not(c) or not(d)' }
      let(:data) { { 'c' => false } }

      it 'should still hide the unsatisfied dependencies' do
        expect(evaluation).to be true
        expect(tracer.unsatisfied).to be_empty
        expect(tracer.satisfied).to eql Set['c']
      end
    end

    describe 'partial_evaluation', :perf do
      context 'with default' do
        let(:expression) do
          (0...PERF_SIZE).to_a.map { |i| "default(f#{i}, false)" }.join(" OR ")
        end

        it 'hits all idents but doesnt overflow' do
          expect(evaluation).to be false
          expect(tracer.satisfied).to be_empty
          expect(tracer.unsatisfied.size).to eql(PERF_SIZE)
        end
      end

      context 'without default', :perf do
        let(:expression) do
          (0...PERF_SIZE).to_a.map { |i| "f#{i}" }.join(" OR ")
        end

        it 'finishes after the first unknown ident' do
          expect { evaluation }.to raise_error(Dentaku::UnboundVariableError)
          expect(tracer.satisfied).to be_empty
          expect(tracer.unsatisfied).to eql Set.new(['f0'])
        end
      end
    end
  end
end
