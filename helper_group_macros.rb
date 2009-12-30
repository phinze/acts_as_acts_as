module HelperGroupMacros
  def spec_acts_as_plugin(acts_as_method, &block)
    # making a specialized object we pass into the block so the DSL is nice and
    # pretty, it basically just builds a hash of requirements
    acts_as_requirements_collector = Class.new
    acts_as_requirements_collector.class_eval do
      attr_accessor :requirements, :options_collectors, :options

      def initialize(options={})
        @requirements = {}
        @options_collectors = []
        @options = options

        # run into nil problems with temp_model if require_columns is nil
        @requirements[:require_columns] = []
      end

      # Should just add the results of calling a matcher (i.e. the returned
      # hash) to the list of requirements
      def should(matcher)
        raise "Bad Matcher" unless matcher.is_a?(Array) and matcher.length == 2
        key, args = matcher
        @requirements[key] = (@requirements.key?(key)) ? @requirements[key] + args : args
      end

      # spin off a duplicate collector with the extra options specified
      def with(options)
        raise "Options must be hash" unless options.is_a?(Hash)
        @options_collectors << self.class.new(options)
        @options_collectors.last.requirements = self.requirements.dup # dup important so my reqs don't change
        return @options_collectors.last
      end

      # convenience method for recursing and getting the whole tree of
      # collectors that may have been spawned off
      def all
        return [self] + @options_collectors.inject([]) { |a, c| a + c.all }
      end

      def all_requirements
        all.inject({}) { |h, c| h.merge(c.requirements) }
      end
    end

    # matchers, just spit out their name with arguments as an array to be added
    # to the the requirements list
    [:require_methods, :require_columns, :define_methods, :define_class_methods].each do |x|
      self.class.send(:define_method, x) { |*args| [x, args] }
    end

    # Now use our new object to let the block build up requirements
    collector = acts_as_requirements_collector.new
    yield collector


    describe "Acts As Plugin #{acts_as_method}" do
      verifier = Class.new(self)
      verifier.class_eval do 

        def self.verify_requirements(acts_as_method, collector)
          collector.all.each do |c|
            describe "with options: #{c.options.inspect}" do
              c.requirements.each_pair do |method, args|
                send(method, acts_as_method, c.options, c.requirements, *args)
              end
            end 
          end
        end

        def self.require_methods(acts_as_method, options, reqs, *methods)
          describe 'required methods' do
            methods.each do |meth|
              it "#{meth} must be defined in caller" do
                mod = tableless_model(
                  :columns => reqs[:require_methods],
                  :methods => reqs[:require_methods].reject { |rm| rm == meth }
                )
                lambda { mod.send(acts_as_method, options) }.should raise_error(/#{meth}/)
              end
            end
          end
        end

        def self.require_columns(acts_as_method, options, reqs, *columns)
          describe 'required columns' do
            columns.each do |c|
              it "#{c[0]} must be defined as column in caller" do
                m = tableless_model(
                  :columns => reqs[:require_columns].reject { |rc| rc == c },
                  :methods => reqs[:require_methods]
                )
                lambda { m.send(acts_as_method, options) }.should raise_error(/#{c[0]}/)
              end

              it "#{c[0]} must be of type #{c[1]}" do
                goodm = tableless_model(
                  :columns => reqs[:require_columns],
                  :methods => reqs[:require_methods]
                )
                badm = tableless_model(
                  :columns => reqs[:require_columns].map { |rc| (rc != c) ? rc : [rc[0], :badcoltype]},
                  :methods => reqs[:require_methods]
                )
                lambda { goodm.send(acts_as_method, options) }.should_not raise_error
                lambda { badm.send(acts_as_method,  options) }.should raise_error(/#{c[0]}/)
              end
            end
          end
        end

        def self.define_methods(acts_as_method, options, reqs, *methods)
          describe 'defined methods' do
            methods.each do |meth|
              it "#{meth} method is defined automatically" do
                mod = tableless_model(
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

      verifier.verify_requirements(acts_as_method, collector)
    end

    before(:all) do

      ActsAsBillable::BillableObjects.classes_using_billing = []

      @valid_model = tableless_model(
        :columns => collector.all_requirements[:require_columns],
        :methods => collector.all_requirements[:require_methods]
      )

      @valid_model.send(acts_as_method)

      @model_opts = {
        :columns => collector.all_requirements[:require_columns],
        :methods => collector.all_requirements[:require_methods]
      }

      @valid_model_with_table = temp_model(@model_opts)
      @valid_model_with_table.send(acts_as_method)

    end

    after(:all) do
      drop_temp_model(@valid_model_with_table)
    end

  end
end
