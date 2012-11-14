require "rubygems"
require "pathname"
require "tempfile"

action :deploy do

    directory '/usr/share/gearbox' do
        owner 'gearbox'
        group 'gearbox'
        mode "0775"
    end

    version = new_resource.version
    name = new_resource.name

    user name do
        system true
    end

    group name do
        action :modify
        append true
        members %w{gearbox}.select { |user| node.key? user }
    end

    key = "#{name}/#{version}.tar.gz"
    artifact_dir = ::File::join(node["gearbox"]["app_dir"], name)
    versions_dir = ::File::join(artifact_dir, "versions")
    tar_dir = ::File::join(artifact_dir, "tars")
    var_dir = ::File::join(artifact_dir, "var")
    log_dir = ::File::join(var_dir, "log")
    data_dir = ::File::join(var_dir, "data")
    run_dir = ::File::join(var_dir, "run")
    [artifact_dir, versions_dir, tar_dir, var_dir, log_dir, data_dir, log_dir].each do |dir|
        directory dir do
            owner name
            group name
            mode "0775"
        end
    end

    tar_file = ::File::join(tar_dir, "#{version}.tar.gz")
    Chef::Log.info ("Getting Key #{key}")
    file tar_file do
        action :create_if_missing
        content AWS::S3::S3Object.value key, new_resource.bucket
        owner name
        group name
    end

    version_dir = ::File::join(versions_dir, version)

    script "untar-#{name}" do
        interpreter "bash"
        user name
        not_if { ::File.directory?(version_dir) }
        code <<-EOH
        mkdir -p "#{version_dir}"
        cd "#{version_dir}"
        tar -xzf "#{tar_file}"
        EOH
    end

    current_app_dir = ::File::join(artifact_dir, 'current')
    template_dir = Pathname.new(::File::join(version_dir, 'gbtemplate'))
    compiled_dir = Pathname.new(::File::join(version_dir, 'gbconfig'))
    directory ::File::join(version_dir, 'gbconfig') do
        owner name
        group name
        mode "0755"
    end
    %w{uwsgi nginx upstart}.each do |dir|
        directory ::File.join(version_dir, 'gbconfig', dir) do 
            owner name
            group name
            mode "0755"
        end

    end
    Mustache::template_path = ::File::join(version_dir, 'gbtemplate')
    databags ||= { } 
    node[:gearbox][:encrypted_data_bags].each do |k,v|
          databags[k] = v.map do |args|
                  Chef::EncryptedDataBagItem.load(*args).to_hash
                    end
    end
    node[:gearbox][:data_bags].each do |k,v|
          databags[k] = v.map do |args|
                  data_bag_item(*args).to_hash
                    end
    end


    Chef::Log.info("Generating Application Context")
    ::Dir::glob("#{template_dir}/**/*.mustache").each do |file|
        # skip partials (templates that begin with _)
        next if (::File.basename(file) =~ /^_/)

        template = Pathname.new(file.sub(/\.mustache$/,'')).relative_path_from(template_dir)
        target_file = ::File.join(compiled_dir, template)

        # render the template
        Chef::Log.info("Expanding mustache template #{file}")
        gearbox_template target_file do
            source file
            mode "0644"
            owner name
            group name
            variables({
                "gearbox" => {
                "app_home" => artifact_dir,
                "user" => name,
                "group" => name,
                "log_dir" => log_dir,
                "bin_dir" => ::File::join(current_app_dir, 'bin'),
                "data_dir" => data_dir,
                "run_dir" => run_dir,
                "loaded_data_bags" => databags
            }
            })
        end

        # Copy upstart files
        upstart_regex = %r{.*\/(.*)\.conf}
        Dir::glob("#{compiled_dir}/upstart/**/*.conf").each do |source_file|
            target_file = source_file.sub("#{compiled_dir}/upstart/", "/etc/init/")
            bash "cp #{source_file} #{target_file}" 
            service_name = upstart_regex.match(source_file)[1]
            Chef::Log.info("Starting service: #{service_name}")
            service service_name do
                provider Chef::Provider::Service::Upstart
                action [:enable, :restart]
            end
        end

        Dir::glob("#{compiled_dir}/uwsgi/**/*.y*ml").each do |source_file|
            target_file = source_file.sub("#{compiled_dir}/uwsgi", node["uwsgi"]["app_path"] )
            FileUtils.mkdir_p(::File.dirname(node["uwsgi"]["app_path"])) unless ::File.exists?(node["uwsgi"]["app_path"]) 
            Chef::Log.info("Linking source_file #{source_file} to target_file #{target_file}")
            link target_file do
                to source_file
            end
        end
    end
    link current_app_dir do
        action :delete
    end
    link current_app_dir do
        action :create
        to version_dir
    end
end

action :delete do

end
