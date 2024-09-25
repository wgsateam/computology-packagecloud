# frozen_string_literal: true
#
# Author: Joe Damato
# Module Name: packagecloud
#
# Copyright 2014-2015, Computology, LLC
#
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
#

require 'uri'
require 'net/http'
require 'net/https'

module Packagecloud
  class API
    attr_reader :name

    def initialize(name, master_token, server_address, os, dist, hostname)
      @name         = name
      @master_token = master_token
      @os           = os
      @dist         = dist
      @hostname     = hostname
      @base_url     = server_address ? URI.join(server_address, '/install/repositories/').to_s : 'https://packagecloud.io/install/repositories/'

      @endpoint_params = {
        os: os,
        dist: dist,
        name: hostname
      }
    end

    def repo_name
      @name.tr('/', '_')  # Using `tr` instead of `gsub` for better performance
    end

    def rpm_base_url
      @rpm_base_url ||= master_rpm_base_url.dup.tap { |uri| uri.user = read_token }
    end

    def master_rpm_base_url
      @master_rpm_base_url ||= URI(get(uri_for('rpm_base_url'), @endpoint_params).body.chomp)
    end

    def read_token
      @read_token ||= post(uri_for('tokens.text'), @endpoint_params).body.chomp
    end

    def uri_for(resource)
      URI.join(@base_url, "#{@name}/#{resource}").tap do |uri|
        uri.user = @master_token
      end
    end

    def get(uri, params)
      uri.query = URI.respond_to?(:encode_www_form) ? URI.encode_www_form(params) : params.to_param
      request   = Net::HTTP::Get.new(uri)

      request.basic_auth(uri.user.to_s, uri.password.to_s) if uri.user
      http_request(uri, request)
    end

    def post(uri, params)
      request = Net::HTTP::Post.new(uri)
      request.set_form_data(params)

      request.basic_auth(uri.user.to_s, uri.password.to_s) if uri.user
      http_request(uri, request)
    end

    private

    def http_request(uri, request)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', verify_mode: OpenSSL::SSL::VERIFY_PEER) do |http|
        http.request(request).tap do |res|
          raise res.error! unless res.is_a?(Net::HTTPSuccess) || res.is_a?(Net::HTTPRedirection)
        end
      end
    end
  end
end

module Puppet::Parser::Functions
  newfunction(:get_read_token, type: :rvalue) do |args|
    repo, master_token, server_address = args
    os        = lookupvar('::operatingsystem').downcase
    dist      = lookupvar('::operatingsystemrelease')
    hostname  = lookupvar('::fqdn')

    Packagecloud::API.new(repo, master_token, server_address, os, dist, hostname).read_token
  end
end
