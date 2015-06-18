# Copyright 2014, Abiquo
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'

describe 'collectd-abiquo::plugin' do
    let(:chef_run) do
        ChefSpec::SoloRunner.new do |node|
            node.automatic['platform'] = 'ubuntu'
            node.set['collectd_abiquo']['endpoint'] = 'http://localhost'
            node.set['collectd_abiquo']['app_key'] = 'app-key'
            node.set['collectd_abiquo']['app_secret'] = 'app-secret'
            node.set['collectd_abiquo']['access_token'] = 'access-token'
            node.set['collectd_abiquo']['access_token_secret'] = 'access-token-secret'
        end
    end

    it 'installs the python dependencies' do
        chef_run.converge(described_recipe)
        expect(chef_run).to include_recipe('python::pip')
        expect(chef_run).to install_python_pip('requests').with(:version => '2.5.0')
        expect(chef_run).to install_python_pip('requests-oauthlib').with(:version => '0.4.2')
    end

    it 'uploads the Abiquo plugin script' do
        chef_run.converge(described_recipe)
        expect(chef_run).to create_remote_file('/usr/lib/collectd/abiquo-writer.py').with(
            :source => 'https://rawgit.com/abiquo/collectd-abiquo/master/abiquo-writer.py'
        )
    end

    it 'configures the Abiquo collectd plugin' do
        chef_run.converge(described_recipe)
        expect(chef_run).to create_collectd_conf('abiquo-writer').with({
            :plugin => { 'python' => { 'Globals' => true } },
            :conf => { 'ModulePath' => '/usr/lib/collectd',
                'LogTraces' => true,
                'Interactive' => false,
                'Import' => 'abiquo-writer',
                %w(Module abiquo-writer) => {
                    'Authentication' => 'oauth',
                    'URL' => 'http://localhost',
                    'ApplicationKey' => 'app-key',
                    'ApplicationSecret' => 'app-secret',
                    'AccessToken' => 'access-token',
                    'AccessTokenSecret' => 'access-token-secret'
                }
            }
        })
    end
end