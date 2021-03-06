# needs
# ENV['APP_INSTALLER_TRANSMISSION_PASSWORD']
# ENV['APP_INSTALLER_TRANSMISSION_USERNAME']
# ENV['APP_INSTALLER_TRANSMISSION_PORT']

dep "transmission-daemon.managed"

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

dep 'transmission config directory' do
  met? {
    Dir.exists?("/home/protonet/.config/transmission-daemon")
  }
  meet {
    log_shell "preparing config dir", "mkdir -p /home/protonet/.config/transmission-daemon"
  }
end

dep "configure transmission" do
  requires 'stop transmission service', 'transmission config directory'
  met? {
    File.exists?("/home/protonet/.config/transmission-daemon/settings.json")
  }
  meet {
    transmission_configuration = <<-TRANSMISSION_CONFIG
    {
      "rpc-enabled": true,
      "rpc-whitelist": "127.0.0.1,*.*.*.*",
      "rpc-password": "#{ENV['APP_INSTALLER_TRANSMISSION_PASSWORD']}",
      "rpc-username": "#{ENV['APP_INSTALLER_TRANSMISSION_USERNAME']}",
      "rpc-port": #{ENV['APP_INSTALLER_TRANSMISSION_PORT'].to_i},
      "rpc-authentication-required": true,
      "umask": 7
    }
    TRANSMISSION_CONFIG
    log_shell("writing configuration to settings.json", "cat > /home/protonet/.config/transmission-daemon/settings.json", :input => transmission_configuration)
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
  requires 'transmission-daemon.managed', 'disable transmission autostart', 'stop transmission service', 'configure transmission', 'start transmission'
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



