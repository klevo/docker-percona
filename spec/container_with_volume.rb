require 'spec_helper'

# Note: we're using a mounted volume located within the host vm, because if we would mount something from OS X, we would have write permission problems: https://github.com/boot2docker/boot2docker/issues/581
describe "running a container with mounted volume" do
  before :all do
    `boot2docker ssh "if [ -d /tmp/empty-data-dir ]; then sudo rm -rf /tmp/empty-data-dir; fi; mkdir /tmp/empty-data-dir"`
    
    @container = Docker::Container.create(
      'Image' => IMAGE_TAG,
      'Detach' => true, 
      'Env' => [ 'MYSQL_ROOT_PASSWORD=foo' ]
    )
    @container.start('Binds' => '/tmp/empty-data-dir:/var/lib/mysql')
    
    sleep 5
    # Wait for mysql to start
    @container.exec(['bash', '-c', 'mysqladmin --silent --wait=30 ping'])
  end
  
  it "can run mysql query through build in mysql client" do
    stdout, stderr = @container.exec(['bash', '-c', 'mysql -e "show databases;"'])
    expect(stderr.first).to_not match(/Access denied for user/)
    
    expect(stdout.first).to match(/mysql/)
    expect(stdout.first).to match(/information_schema/)
    expect(stdout.first).to_not match(/test/)
    expect(stdout.first).to_not match(/survive/)
  end
  
  # the following also tests the case where we mount an already existing data dir
  it "can be stopped, started again and data survives" do
    @container.exec(['bash', '-c', 'mysql -e "create database survive;"'])
    @container.restart
    # Wait for mysql to start
    sleep 5
    @container.exec(['bash', '-c', 'mysqladmin --silent --wait=30 ping'])
    stdout, stderr = @container.exec(['bash', '-c', 'mysql -e "show databases;"'])
    expect(stdout.first).to match(/survive/)
  end
  
  after :all do
    @container.delete(force: true, v: true)
    `boot2docker ssh "sudo rm -rf /tmp/empty-data-dir"`
  end
end