# Methods available _within_ examples
module ActsAsActsAs::Macros

  # ActsAsActsAs::Macros#tableless_model a factory method for an ActiveRecord
  # model using the 'active_record_tableless' plugin.
  # 
  # ==== Parameters
  #  * <tt>:class_name</tt> - if you want the class to be assigned a constant,
  #                           specify it as a string here, note that if you want
  #                           the constant to be namespaced you should do the
  #                           nested const_sets yourself and leave this option
  #                           blank
  #  * <tt>:superclass</tt> - superclass for the new model, defaults to
  #                           ActiveRecord::Base, as you might expect
  #  * <tt>:columns</tt>    - collection of tuples as expected by the
  #                           <tt>active_record_tableless</tt> plugin to be
  #                           added as columns to the  created model
  #  * <tt>:methods</tt>    - collection of symbols to define by attr_accessor
  #                           in the created model
  def tableless_model(options)
    options    = options.dup
    class_name = options.delete(:class_name) || nil
    superclass = options.delete(:superclass) || ActiveRecord::Base
    columns    = options.delete(:columns)    || []
    methods    = options.delete(:methods)    || []

    newclass = Class.new(superclass)

    newclass.class_eval do
      tableless :columns => columns
      methods.each do |m|
        attr_accessor m
      end
    end

    Object.const_set(class_name, newclass) if class_name
    return newclass
  end

  # A model with a table that exists only for the duration of the block, or if
  # no block is passed, until <tt>drop_temp_model</tt> is called
  def temp_model(model_opts, &block)
    t = Time.now
    uid = t.to_i.to_s + t.usec.to_s
    table_name = "temp_table_#{uid}"
    ActiveRecord::Base.connection.create_table(table_name) do |t|
      model_opts[:columns].each do |name, type|
        t.send(type, name)
      end
    end

    newclass = Class.new(ActiveRecord::Base)
    Object.const_set(table_name.camelize, newclass)
    newclass.set_table_name table_name
    newclass.reset_column_information

    newclass.class_eval do
      model_opts[:methods].each do |m|
        attr_accessor m
      end
    end

    return newclass unless block_given?

    yield newclass

    drop_temp_model(newclass)
  end

  def temp_versioned_model(model_opts, &block)
    model = temp_model(model_opts)
    silence_stream(STDERR) { model.acts_as_ris_versioned(model_opts[:aav_options] || {}) }
    model.update_versioned_table

    return model unless block_given?
    yield model
    drop_temp_model(model)
  end


  def drop_temp_model(tmodel)
    ActiveRecord::Base.connection.drop_table(tmodel.table_name)
    ActiveRecord::Base.connection.drop_table(tmodel.versioned_table_name) if tmodel.respond_to?(:versioned_table_name)
  end

end
