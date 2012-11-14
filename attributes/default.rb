# Copyright 1999-2012 University of Chicago
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# 
#
default["gearbox"]["apps"] = []
default["gearbox"]["log_dir"] = '/var/log/gearbox'
default["gearbox"]["user"] = 'gearbox'
default["gearbox"]["artifact_bucket"] = 'gearbox_build_artifacts'
default["gearbox"]["app_dir"] = '/usr/share/gearbox'
default["gearbox"]["encrypted_data_bags"] = {}
default["gearbox"]["data_bags"] = {}
default["gearbox"]["versions"] = {}
default["gearbox"]["aws_user"] = "boto"
default["gearbox"]["enable_globus"] = false
