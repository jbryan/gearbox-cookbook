actions :create
default_action :create
attribute :path, :kind_of => String, :name_attribute => true
attribute :source, :kind_of => String
attribute :additional_context
attribute :mode, :kind_of => String
attribute :owner, :kind_of => String
attribute :group, :kind_of => String

def variables(context)
  @additional_context = context
  print "variables"
end

