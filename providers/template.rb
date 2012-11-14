require 'digest/sha1'
require 'chef/mixin/checksum'
require 'chef/file_access_control'
require 'pathname'
require 'tempfile'
require 'chef/provider/file'
require 'chef/checksum_cache'

include Chef::Mixin::Checksum
include ChefMustache::MustacheTemplate

def load_current_resource
    @current_resource = Chef::Resource::File.new(@new_resource.name)
    @current_resource
end

action :create do
    Chef::Log.info("Rendering mustache template: #{new_resource.path}")
    template = Pathname.new(@new_resource.source.sub(%r{\.mustache$}, ''))
    update = ::File.exist?(@new_resource.path)
    context = node.to_hash
    context = context.merge @new_resource.additional_context
    render_template(@new_resource.source, context) do |rendered_template|
        mode = @new_resource.mode
        owner = @new_resource.owner
        group = @new_resource.group
        target = @new_resource.path.dup
        file @new_resource.path.dup do
            action :nothing
            content rendered_template
            mode mode
            owner owner
            group group
        end.run_action(:create)

        # Copy upstart files
        if ( @new_resource.path =~ %r{.*/upstart/.*} )
            upstart_regex = %r{.*/(.*)\.conf}
            service_name = upstart_regex.match(@new_resource.path)[1]
            upstart_config = file "/etc/init/#{service_name}.conf" do
                content rendered_template
                action :nothing
            end
            upstart_config.run_action(:create)

            service = service service_name do
                provider Chef::Provider::Service::Upstart
                action :nothing
            end

            if upstart_config.updated?
                service.run_action(:enable)
                service.run_action(:restart)
            end
        end

        if ( @new_resource.path =~ %r{.*/uwsgi/(.*.yaml)} )
            Chef::Log.info("Matching template: #{@new_resource.path}")

            target_file = ::File.join(node["uwsgi"]["app_path"], $1)
            FileUtils.mkdir_p(::File.dirname(node["uwsgi"]["app_path"])) unless ::File.exists?(node["uwsgi"]["app_path"]) 
            Chef::Log.info("Linking source_file #{@new_resource.path} to target_file #{target_file}")
            source = @new_resource.path
            link target_file do
                action :nothing
                to source
            end.run_action(:create)

            file source do
                action :nothing
            end.run_action(:touch)
        end
    end
end
