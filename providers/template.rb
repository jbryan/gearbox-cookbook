require 'digest/sha1'
require 'chef/mixin/checksum'
require 'chef/file_access_control'

include Chef::Mixin::Checksum
include ChefMustache::MustacheTemplate

def load_current_resource
    @current_resource = Chef::Resource::File.new(@new_resource.name)
    @current_resource
end

action :create do
    Chef::Log.info("Rendering mustache template: #{new_resource.path}")
    template = Pathname.new(new_resource.source.sub(%r{\.mustache$}, ''))
    update = ::File.exist?(@new_resource.path)
    context = node.to_hash
    context = context.merge @new_resource.additional_context
    render_template(new_resource.source, context) do |rendered_template|
        mode = @new_resource.mode
        owner = @new_resource.owner
        group = @new_resource.group
        f = file @new_resource.path do
            content rendered_template
            mode mode
            owner owner
            group group
        end
    end
end
