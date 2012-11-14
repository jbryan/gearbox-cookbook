actions :deploy, :rollback, :delete
default_action :deploy
attribute :name, :kind_of => String, :name_attribute => true
attribute :version, :kind_of => String
attribute :bucket, :kind_of => String
