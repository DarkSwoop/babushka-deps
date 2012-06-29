# needs
# ENV['APP_INSTALLER_TRANSMISSION_PASSWORD']
# ENV['APP_INSTALLER_TRANSMISSION_USERNAME']
# ENV['APP_INSTALLER_TRANSMISSION_PORT']

dep "transmission install" do
  met? {
    shell 'dpkg -S transmission-daemon | grep "transmission-daemon: /usr/bin/transmission-daemon"'
  }
  meet {
    log_shell "installing transmission", "sudo apt-get install transmission-daemon"
  }
end

dep "disable transmission autostart" do
  met? {
    !shell "ls -al /etc/rc1.d | grep transmission-daemon"
  }
  meet {
    log_shell "disabling transmission automatic startup", "sudo update-rc.d -f transmission-daemon remove"
  }
end

dep "stop transmission service" do
  met? {
    !shell("ps ax | grep transmission-daemon | grep -v grep")
  }
  meet {
    log_shell "stopping transmission daemon", "sudo service transmission-daemon stop"
  }
end

dep "configure transmission" do
  requires 'stop transmission service'
  met? {
    File.exists?("/home/protonet/.config/transmission-daemon/setting.json")
  }
  meet {
    shell "mkdir -p /home/protonet/.config/transmission-daemon"
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
    !shell 'dpkg -S transmission-daemon | grep "transmission-daemon: /usr/bin/transmission-daemon"'
  }
  meet {
    log_shell "removing transmission", "sudo apt-get remove transmission-daemon"
  }
end

dep "transmission full uninstall" do
  requires 'stop transmission service', 'remove transmission configuration', 'transmission uninstall'
end



