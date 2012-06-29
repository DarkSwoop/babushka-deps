# needs
# ENV['APP_INSTALLER_TRANSMISSION_PASSWORD']
# ENV['APP_INSTALLER_TRANSMISSION_USERNAME']
# ENV['APP_INSTALLER_TRANSMISSION_PORT']

dep "transmission install" do
  met? {
    File.exists? "/usr/bin/transmission-daemon"
  }
  meet {
    log_shell "installing transmission", "apt-get install transmission-daemon", :sudo => true
  }
end

dep "disable transmission autostart" do
  met? {
    !shell "ls -al /etc/rc1.d | grep transmission-daemon"
  }
  meet {
    log_shell "disabling transmission automatic startup", "update-rc.d -f transmission-daemon remove", :sudo => true
  }
end

dep "stop transmission service" do
  met? {
    !shell("ps ax | grep transmission-daemon | grep -v grep")
  }
  meet {
    log_shell "stopping transmission daemon", "service transmission-daemon stop", :sudo => true
  }
end

dep "configure transmission" do
  requires 'stop transmission service'
  met? {
    File.exists?("/home/protonet/.config/transmission-daemon/setting.json")
  }
  meet {
    log_shell "mkdir -p /home/protonet/.config/transmission-daemon", "mkdir -p /home/protonet/.config/transmission-daemon"
    transmission_configuration = <<-TRANSMISSION_CONFIG
    {
      "rpc-enabled": true,
      "rpc-whitelist": "127.0.0.1,*.*.*.*",
      "rpc-password": "#{ENV['APP_INSTALLER_TRANSMISSION_PASSWORD']}",
      "rpc-username": "#{ENV['APP_INSTALLER_TRANSMISSION_USERNAME']}",
      "rpc-port": #{ENV['APP_INSTALLER_TRANSMISSION_PORT'].to_i},
      "rpc-authentication-required": true
    }
    TRANSMISSION_CONFIG
    File.open("/home/protonet/.config/transmission-daemon/settings.json", "w+") do |f|
      f.write(transmission_configuration)
    end
  }
end

dep "start transmission" do
  met? {
    shell "ps ax | grep transmission-daemon | grep -v grep"
  }
  meet {
    log_shell "starting transmission daemon", "transmission-daemon"
  }
end

dep "transmission full install" do
  requires 'transmission install', 'disable transmission autostart', 'stop transmission service', 'configure transmission', 'start transmission'
end

dep "remove transmission configuration" do
  met? {
    !File.exists?('/home/protonet/.config/transmission-daemon/settings.json')
  }
  meet {
    log_shell "removing transmisstion config folder", "rm -rf /home/protonet/.config/transmission-daemon"
  }
end

dep "transmission uninstall" do
  met? {
    !File.exists? "/usr/bin/transmission-daemon"
  }
  meet {
    log_shell "removing transmission", "apt-get -y remove --purge 'transmission-daemon'", :sudo => true
  }
end

dep "transmission full uninstall" do
  requires 'stop transmission service', 'remove transmission configuration', 'transmission uninstall'
end



