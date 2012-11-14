#
# Cookbook Name:: gearbox
# Recipe:: default
#
# Copyright 1999-2012 University of Chicago
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# 

user "gearbox" do
  system true
end

chef_gem "aws-s3" do
  action :install
end

chef_gem "mustache" do
  action :install
end

require "aws/s3"
require "mustache"

aws_creds = Chef::EncryptedDataBagItem.load("aws_credentials", node["gearbox"]["aws_user"])
access_key_id = aws_creds["aws_access_key_id"]
secret_access_key = aws_creds["aws_secret_access_key"]

AWS::S3::Base.establish_connection!(
  :access_key_id     => access_key_id,
  :secret_access_key => secret_access_key
)

directory node['gearbox']['app_dir'] do
  owner 'gearbox'
  group 'gearbox'
  mode "0775"
end

