# Methods available _within_ examples
module ActsAsActsAs::Macros

  # ActsAsActsAs::Macros#tableless_model a factory method for an ActiveRecord
  # model using the 'active_record_tableless' plugin.
  # 
  # ==== Parameters
  #  * <tt>:class_name</tt> - if you want the class to be assigned a constant,
  #    specify it as a string here, note that if you want the constant to be
  #    namespaced you should do the nested const_sets yourself and leave this
  #    option blank
  #  * <tt>:superclass</tt> - superclass for the new model, defaults to
  #    ActiveRecord::Base
  #  * <tt>:columns</tt> - array of tuples as expected by the
  #    <tt>active_record_tableless</tt> plugin
  #  * <tt>:methods</tt> - 
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

  # A model with a table that exists only for the duration of the block
  def temp_model(model_opts, &block)
    table_name = "temp_table_#{'%04d' % rand(1000)}"
    ActiveRecord::Base.connection.create_table(table_name) do |t|
      model_opts[:columns].each do |name, type|
        t.send(type, name)
      end
    end

    newclass = Class.new(ActiveRecord::Base)
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

  # yeah - this is lame, but I like having both
  def drop_temp_model(tmodel)
    ActiveRecord::Base.connection.drop_table(tmodel.table_name)
  end
end
