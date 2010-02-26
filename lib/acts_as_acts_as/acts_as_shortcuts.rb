module ActsAsActsAs
  module ActsAsShortcuts
    def require_methods(*method_list)
      method_list.each do |required_method| 
        unless instance_methods.include?(required_method.to_s) 
          raise "Model #{self.to_s} must define #{required_method}"
        end
      end
    end

    def require_class_methods(*method_list)
      method_list.each do |required_method| 
        unless methods.include?(required_method.to_s) 
          raise "Model #{self.to_s} must define class method #{required_method}"
        end
      end
    end
  
    def require_columns(*column_and_type_pairs)
      column_problems = []
      column_and_type_pairs.each do |req_colname, req_type|
        c = columns.find { |c| c.name == req_colname.to_s } 
        if c.nil?
          column_problems << "Model #{self.to_s} must have column #{req_colname}"
          next
        elsif c.type != req_type
          column_problems << "Column #{req_colname} must have #{req_type} type, has #{c.type}"
        end
      end
      raise column_problems.join('; ') unless column_problems.empty?
    end
  end
end
