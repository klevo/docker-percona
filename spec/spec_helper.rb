require 'docker'
require 'pry'
require 'awesome_print'

Excon.defaults[:ssl_verify_peer] = false

DOCKERFILE_ROOT = File.expand_path File.join(File.dirname(__FILE__), '..')
IMAGE_TAG = 'klevo/percona'
IMAGE = Docker::Image.build_from_dir DOCKERFILE_ROOT, t: IMAGE_TAG