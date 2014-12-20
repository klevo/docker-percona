require 'spec_helper'

describe "running a container without attached volumes" do
  before :all do
    @container = Docker::Container.create(
      'Image' => IMAGE_TAG,
      'Detach' => true,
      'Env' => [ 'MYSQL_ROOT_PASSWORD=something' ]
    )
    @container.start
    # Wait for mysql to start
    @container.exec(['bash', '-c', 'mysqladmin --silent --wait=30 ping'])
    sleep 2
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

  after :all do
    @container.delete(force: true, v: true)
  end
end