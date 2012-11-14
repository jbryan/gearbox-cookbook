
action :create do
    templates = node['gearbox'][@new_resource.name]['templates'] rescue {}
    variables = @new_resource.variables
    owner = @new_resource.owner
    group = @new_resource.group
    mode = @new_resource.mode
    templates.each do |key, value|
        Chef::Log.info("Rendering template #{value} to #{key}")
        gearbox_template key do
            action :nothing
            group group
            owner owner
            mode mode
            source value
            variables(variables)
        end.run_action(:create)
    end
end
