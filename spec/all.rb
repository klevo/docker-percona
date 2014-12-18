require 'docker'
require 'pry'

build_path = File.expand_path File.join(File.dirname(__FILE__), '..')
image_tag = 'klevo/percona'

describe "image" do
  before(:all) do
    # Build the image
    @image = Docker::Image.build_from_dir build_path, t: image_tag
  end
  
  it "should expose the mysql tcp port" do
    expect(@image.json["Config"]["ExposedPorts"]).to include("3306/tcp")
  end

  after(:all) do
  end
end

describe "running container" do
  before(:all) do
    @image = Docker::Image.build_from_dir build_path, t: image_tag
  end

  it "will start and run mysql daemon" do
    @container = Docker::Container.create(
      'Image' => image_tag, 
      'Detach' => true, 
      'Env' => [ 'MYSQL_ROOT_PASSWORD=something' ]
    )
    @container.start
    root_my_cnf = @container.exec(['bash', '-c', 'cat /root/.my.cnf'])
    expect(root_my_cnf.first.first).to match(/password=something/)
    
    # binding.pry
  end

  after(:all) do
    @container.delete(force: true)
  end
end