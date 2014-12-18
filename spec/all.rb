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
      'Env' => [ 'MYSQL_ROOT_PASSWORD=something' ],
      # 'Volumes' => {
      #   ''
      # }
    )
    @container.start
    # Wait for mysql to start
    @container.exec(['bash', '-c', 'mysqladmin --silent --wait=30 ping'])
  end

  it "has root .my.cnf file that contains the password specified on container create" do
    root_my_cnf = @container.exec(['bash', '-c', 'cat /root/.my.cnf']).first.first
    expect(root_my_cnf).to match(/password=something/)
  end
  
  it "runs mysql daemon" do
    stdout, stderr = @container.exec(['bash', '-c', 'ps aux'])
    expect(stdout.first).to match(/\/usr\/sbin\/mysqld/)
  end
  
  it "can run mysql query through build in mysql client" do
    stdout, stderr = @container.exec(['bash', '-c', 'mysql -e "show databases;"'])
    expect(stderr.first).to_not match(/Access denied for user/)
    
    expect(stdout.first).to match(/mysql/)
    expect(stdout.first).to match(/information_schema/)
    expect(stdout.first).to_not match(/test/)
  end

  after(:all) do
    @container.delete(force: true)
  end
end