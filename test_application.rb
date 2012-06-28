dep 'configuration' do
  met? {
    File.exists?("/home/protonet/test_application_env")
  }
  meet {
    test_application_env = <<-EOS
export TEST_APPLICATION_CONFIGURATION=#{ENV['APP_INSTALLER_TEST_APPLICATION_CONFIGURATION']}
    EOS
    shell("cat > /home/protonet/test_application_env", :input => test_application_env)
  }
end

dep 'test_application install' do
  requires 'configuration', 'create tempfile'
end
