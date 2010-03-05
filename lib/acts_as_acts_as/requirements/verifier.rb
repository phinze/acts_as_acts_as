class ActsAsActsAs::Requirements::Verifier

  attr_accessor :acts_as_method
  include ActsAsActsAs::Macros

  def initialize(acts_as_method)
    @acts_as_method = acts_as_method
  end

  def verify_requirements(collector)
    verifier       = self
    acts_as_method = self.acts_as_method
    collector.all.each do |c|
      describe "with options: #{c.options.inspect}" do
        c.requirements.each_pair do |method, args|
          verifier.send(method, c.options, c.requirements, *args)
        end
      end 
    end
  end

  def require_methods(options, reqs, *methods)
    verifier       = self
    acts_as_method = @acts_as_method
    describe 'required methods' do
      methods.each do |meth|
        it "#{meth} must be defined in caller" do
          mod = verifier.tableless_model(
            :columns => reqs[:require_methods],
            :methods => reqs[:require_methods].reject { |rm| rm == meth }
          )
          lambda { mod.send(acts_as_method, options) }.should raise_error(/#{meth}/)
        end
      end
    end
  end

  def require_class_methods(options, reqs, *methods)
    verifier       = self
    acts_as_method = @acts_as_method
    describe 'required methods' do
      methods.each do |meth|
        it "#{meth} must be defined in class" do
          mod = verifier.tableless_model(
            :columns => reqs[:require_columns]
          )
          reqs[:require_class_methods].reject { |rm| rm == meth }.each do |method|
            mod.class_eval %{
              def self.#{method}
                true
              end
            }
          end
          lambda { mod.send(acts_as_method, options) }.should raise_error(/#{meth}/)
        end
      end
    end
  end

  def require_parameters(options, reqs, *parameters)
    verifier       = self
    acts_as_method = @acts_as_method
    describe 'required methods' do
      parameters.each do |parameter|
        it "#{parameter} must be passed in the #{acts_as_method} options hash " do
          mod = verifier.tableless_model(
            :columns => reqs[:require_columns]
          )

          passing_options = parameters.inject({}) {|h, param| h[param] = :foo ; h}
          passing_options.merge!(options)
          passing_options.delete(parameter)

          lambda { mod.send(acts_as_method, passing_options) }.should raise_error(/#{parameter}/)
        end
      end
    end
  end

  def require_columns(options, reqs, *columns)
    verifier       = self
    acts_as_method = @acts_as_method
    describe 'required columns' do
      columns.each do |c|
        it "#{c[0]} must be defined as column in caller" do
          m = verifier.tableless_model(
            :columns => reqs[:require_columns].reject { |rc| rc == c },
            :methods => reqs[:require_methods]
          )
          lambda { m.send(acts_as_method, options) }.should raise_error(/#{c[0]}/)
        end

        it "#{c[0]} must be of type #{c[1]}" do
          goodm = verifier.tableless_model(
            :columns => reqs[:require_columns],
            :methods => reqs[:require_methods]
          )
          badm = verifier.tableless_model(
            :columns => reqs[:require_columns].map { |rc| (rc != c) ? rc : [rc[0], :badcoltype]},
            :methods => reqs[:require_methods]
          )
          lambda { goodm.send(acts_as_method, options) }.should_not raise_error
          lambda { badm.send(acts_as_method,  options) }.should raise_error(/#{c[0]}/)
        end
      end
    end
  end

  def define_methods(options, reqs, *methods)
    verifier       = self
    acts_as_method = @acts_as_method
    describe 'defined methods' do
      methods.each do |meth|
        it "#{meth} method is defined automatically" do
          mod = verifier.tableless_model(
            :columns => reqs[:require_columns],
            :methods => reqs[:require_methods]
          )
          lambda { mod.send(acts_as_method, options) }.should_not raise_error
          mod.new.should respond_to(meth)
        end
      end
    end
  end
end

