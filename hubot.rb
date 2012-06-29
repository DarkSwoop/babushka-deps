# requires ENV variable: APP_INSTALLER_HUBOT_PROTONET_USER
# requires ENV variable: APP_INSTALLER_HUBOT_PROTONET_PASSWORD
# requires ENV variable: APP_INSTALLER_HUBOT_PROTONET_HOST
# requires ENV variable: APP_INSTALLER_HUBOT_PROTONET_PORT
# requires ENV variable: APP_INSTALLER_HUBOT_PROTONET_VERSION

dep 'coffee-script installation' do
  met? {
    shell "coffee -v | grep CoffeeScript"
  }
  meet {
    log_shell "install coffee-script", "sudo npm install -g coffee-script"
  }
end

dep 'hubot install preparation' do
  met? {
    File.exists? "/home/protonet/apps/hubot"
  }
  meet {
    log_shell 'mkdir /home/protonet/apps', "mkdir -p /home/protonet/apps;"
    cd("/home/protonet/apps") do
      log_shell 'downloading', "wget http://digitalbehr.de/hubot.tar.gz"
      log_shell 'unpacking', "tar xzvf hubot.tar.gz;rm hubot.tar.gz"
    end
  }
end

dep 'hubot installation' do
  requires 'coffee-script installation', 'hubot install preparation'
  met? {
    File.exists? "/home/protonet/apps/hubot/node_modules"
  }
  meet {
    cd("/home/protonet/apps/hubot") do
      log_shell 'installing hubot...', "npm install"
    end
  }
end

dep 'hubot configuration' do
  met? {
    File.exists?("/home/protonet/.hubot_environment_variables")
  }
  meet {
    hubot_environment_variables = <<-EOS
export HUBOT_PROTONET_USER="#{ENV['APP_INSTALLER_HUBOT_PROTONET_USER']}"
export HUBOT_PROTONET_PASSWORD="#{ENV['APP_INSTALLER_HUBOT_PROTONET_PASSWORD']}"
export HUBOT_PROTONET_NODE_HOST="#{ENV['APP_INSTALLER_HUBOT_PROTONET_HOST']}"
export HUBOT_PROTONET_NODE_PORT="#{ENV['APP_INSTALLER_HUBOT_PROTONET_PORT']}"
export HUBOT_PROTONET_NODE_VERSION="#{ENV['APP_INSTALLER_HUBOT_PROTONET_VERSION']}"
    EOS
    shell("cat > /home/protonet/.hubot_environment_variables", :input => hubot_environment_variables)
  }
end

dep 'monit configuration for hubot' do
  met? {
    File.exists? "/home/protonet/dashboard/shared/config/monit.d/hubot" 
  }
  meet {
    monit_config = <<-EOS
check hubot with pidfile /home/protonet/apps/hubot/hubot.pid
  start program = "/home/protonet/apps/hubot/hubot_start_script start"
  stop program = "/home/protonet/apps/hubot/hubot_start_script stop"
    EOS
    shell("cat > /home/protonet/dashboard/shared/config/monit.d/hubot", :input => monit_config)
  }
end

dep 'monit monitoring for hubot' do
  requires 'monit configuration for hubot'
  met? {
    shell "sudo monit status | grep hubot"
  }
  meet {
    log_shell "reloading monit config", "sudo monit reload"
  }
end

dep 'hubot full installation' do
  requires 'hubot installation', 'hubot configuration', 'monit monitoring for hubot'
end

dep 'uninstall hubot app directory' do
  met? {
    !File.exists? "/home/protonet/apps/hubot"
  }
  meet {
    log_shell "removing hubot app folder", "rm -rf /home/protonet/apps/hubot"
  }
end

dep 'unregister hubot from monit' do
  met? {
    !shell("sudo monit status | grep hubot") && !File.exists?("/home/protonet/dashboard/shared/config/monit.d/hubot")
  }

  meet {
    log_shell "removing hubot monit script", "rm /home/protonet/dashboard/shared/config/monit.d/hubot"
    log_shell "unmonitoring hubot", "sudo monit reload"
  }  
end

dep 'remove .hubot_environment_variables' do
  met? {
    !File.exists("/home/protonet/.hubot_environment_variables")
  }
  meet {
    log_shell "removing hubot_environment_variables", "rm /home/protonet/.hubot_environment_variables"
  }
end

dep 'hubot full uninstall' do
  requires 'unregister hubot from monit', 'remove .hubot_environment_variables', "uninstall hubot app directory"
end
