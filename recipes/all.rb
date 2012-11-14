include_recipe "gearbox::default"

node["gearbox"]["apps"].each do |app|
    gearbox_app app do
        version node["gearbox"]["versions"][app]
        bucket node["gearbox"]["artifact_bucket"]
    end
end
