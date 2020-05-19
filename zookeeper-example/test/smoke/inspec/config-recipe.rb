describe package('zookeeperd') do
  it { should be_installed }
end

describe service('zookeeper') do
  it { should be_running }
  it { should be_enabled }
end

# give java time to spin up and start listening
lport = inspec.command('netstat -pln | grep -o :2181').stdout
describe port(2181) do
  before do
    5.times do
      if lport.include? ':2181'
        puts 'java is listening'
        break
      else
        sleep(1)
        puts 'java is not listening'
        lport = inspec.command('netstat -pln | grep -o :2181').stdout
      end
    end
  end
  it { should be_listening }
end

# give java time to spin up and start listening
lport = inspec.command('netstat -pln | grep -o :2020').stdout
describe port(2020) do
  before do
    5.times do
      if lport.include? ':2020'
        puts 'java is listening'
        break
      else
        sleep(1)
        puts 'java is not listening'
        lport = inspec.command('netstat -pln | grep -o :2020').stdout
      end
    end
  end
  it { should be_listening }
end

#check app level ok from zk
describe command('echo "ruok"| nc localhost 2181') do
  its('stdout') { should include 'imok' }
end

#check app level ok from zk
describe command('echo "ruok"| nc localhost 2020') do
  its('stdout') { should include 'imok' }
end
