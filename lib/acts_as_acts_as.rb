module ActsAsActsAs; end

require 'acts_as_acts_as/macros'
require 'acts_as_acts_as/group_macros'

# To be included from spec_helper.rb of another plugin...
# Example:
#  require 'rubygems'
#  require 'acts_as_acts_as'
if defined? Spec::Runner && Spec::Runner.respond_to?(:configure)
  Spec::Runner.configure do |config|
    config.include ActsAsActsAs::Macros,      :type => :helper
    config.extend  ActsAsActsAs::GroupMacros, :type => :helper
  end
end
