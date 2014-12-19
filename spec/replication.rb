require 'spec_helper'

# Note: we're using a mounted volume located within the host vm, because if we would mount something from OS X, we would have write permission problems: https://github.com/boot2docker/boot2docker/issues/581
describe "running a container with mounted volume" do
  before :all do
    @master = Docker::Container.create(
      'Image' => 'klevo/test_mysql_master',
      'Detach' => true
    )
    @master.start
    
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
    
    # Wait for both containers to fully start
    @master.exec(['bash', '-c', 'mysqladmin --silent --wait=30 ping'])
    @slave.exec(['bash', '-c', 'mysqladmin --silent --wait=30 ping'])
  end

  it "can be run as replication slave" do
    # 1. Use the replication_master_sql script to prepare master for replication
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
  end
  
  after :all do
    @master.delete(force: true)
    @slave.delete(force: true)
  end
end