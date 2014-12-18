require 'docker'
require 'pry'

build_path = File.expand_path File.join(File.dirname(__FILE__), '..')
image_tag = 'klevo/percona'
IMAGE = Docker::Image.build_from_dir build_path, t: image_tag

describe "image" do
  it "should expose the mysql tcp port" do
    expect(IMAGE.json["Config"]["ExposedPorts"]).to include("3306/tcp")
  end
end

describe "running container" do
  before(:all) do
    @container = Docker::Container.create(
      'Image' => image_tag, 
      'Detach' => true, 
      'Env' => [ 'MYSQL_ROOT_PASSWORD=something' ]
    )
    @container.start
  end

  it "has root .my.cnf file that contains the password specified on container create" do
    root_my_cnf = @container.exec(['bash', '-c', 'cat /root/.my.cnf'])
    expect(root_my_cnf.first.first).to match(/password=something/)
  end

  after(:all) do
    @container.delete(force: true)
  end
end