require 'docker'
require 'pry'

DOCKERFILE_ROOT = File.expand_path File.join(File.dirname(__FILE__), '..')
IMAGE_TAG = 'klevo/percona'
IMAGE = Docker::Image.build_from_dir DOCKERFILE_ROOT, t: IMAGE_TAG