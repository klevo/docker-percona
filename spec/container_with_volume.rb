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
    @container.exec(['bash', '-c', 'mysqladmin --silent --wait=30 ping'])
    stdout, stderr = @container.exec(['bash', '-c', 'mysql -e "show databases;"'])
    expect(stdout.first).to match(/survive/)
  end
  
  it "can be run as replication slave" do
    @master = @container # just for clarity and intent
    
    # 1. Spin up a new container, that is going to be our replication slave
    @slave = Docker::Container.create(
      'Image' => IMAGE_TAG, 
      'Detach' => true, 
      'Env' => [ 
        'MYSQL_ROOT_PASSWORD=foo',
        'REPLICATION_SLAVE_MASTER_HOST=master',
        'REPLICATION_SLAVE_REMOTE_PORT=3306',
        'REPLICATION_SLAVE_USER=db1_slave',
        'REPLICATION_SLAVE_PASSWORD=slaveUserPass'
      ]
    )
    master_container_name = @master.json['Name'].gsub(/^\//, '')
    @slave.start('Links' => ["#{master_container_name}:master"])
    # Wait for slave to start
    @slave.exec(['bash', '-c', 'mysqladmin --silent --wait=30 ping'])
    
    # TODO: tunnels user needs to be created and keys added for the replication to be able to connect
    
    # 2. Use the replication_master_sql script to prepare master for replication
    stdout, stderr = @slave.exec(['bash', '-c', 'replication_master_sql'])
    
    sql = stdout.first.chomp.strip
    # puts "Executing on master: \"#{sql}\""
    stdout, stderr = @master.exec(['bash', '-c', %{mysql -e "#{sql}"}])
    puts [stdout, stderr]
    
    # Get the binlog position for the slave
    stdout, stderr = @master.exec(['bash', '-c', 'mysql -N -B -e "show master status;"'])
    puts [stdout, stderr]
    binlog, position = stdout.first.split("\t")
    
    # 3. Start the replication on the slave
    stdout, stderr = @slave.exec(['bash', '-c', "replication_start #{binlog} #{position}"])
    puts [stdout, stderr]
    
    # binding.pry
    
    # 4. Do some changes on the master
    stdout, stderr = @master.exec(['bash', '-c', %{mysql -e "create database go_slave;"}])
    puts [stdout, stderr]
    
    # 5. Check whether the query has propagated to the slave
    sleep 3
    stdout, stderr = @slave.exec(['bash', '-c', 'mysql -e "show databases;"'])
    puts [stdout, stderr]
    expect(stdout.first).to match(/go_slave/)
    
    # Cleanup
    @slave.delete(force: true)
  end
  
  after :all do
    @container.delete(force: true)
    `boot2docker ssh "sudo rm -rf /tmp/empty-data-dir"`
  end
end