# A specialized object we pass into the block of `acts_as` so the DSL is nice
# and pretty.  It basically just builds a hash of requirements matchers.
class ActsAsActsAs::Requirements::Collector
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
    @options_collectors << self.class.new(options)
    @options_collectors.last.requirements = self.requirements.dup # dup important so my reqs don't change
    return @options_collectors.last
  end

  # Convenience method for getting the whole tree of
  # collectors that may have been spawned off via `with`
  def all
    return [self] + @options_collectors.inject([]) { |a, c| a + c.all }
  end

  def all_requirements
    all.inject({}) { |h, c| h.merge(c.requirements) }
  end

  module Context
    [:require_methods, :require_columns, :define_methods, :define_class_methods].each do |x|
      define_method(x) { |*args| [x, args] }
    end
  end

  def collect(&block)
  end
end
