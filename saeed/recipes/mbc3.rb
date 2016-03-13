#By saeed

#include_recipe 'deploy'

service "httpd" do
  action [ :stop ]
end

execute 'tomcat_shutdown' do
  command '/usr/local/apache-tomcat/latest/bin/shutdown.sh'
  cwd "/usr/local/apache-tomcat/latest/bin"
  user "tomcat"
  group "tomcat"
end

bash "tomcat_force_stop" do
  user "tomcat"
  code <<-EOH 
    for (( ; ; ));do java=''; java=`ps -ef | grep java | grep -vi grep | awk '{print $2}'`; if [ "$java" != "" ]; then pkill -15 java; else break; fi; done
  EOH
end

node[:deploy].each do |application, deploy|
  opsworks_deploy_dir do
    user deploy[:user]
    group deploy[:group]
    path deploy[:deploy_to]
  end

  opsworks_deploy do
    deploy_data deploy
    app application
  end

execute 'deployment_finalization' do
  command 'cp -r /usr/local/apache-tomcat/latest/opsworks-deployment/current/* /usr/local/apache-tomcat/latest/webapps/'
  cwd "/usr/local/apache-tomcat/latest/webapps"
  user "tomcat"
  group "tomcat"
end



execute 'deployment_cleanup' do
  command 'rm -rf config log tmp public'
  cwd "/usr/local/apache-tomcat/latest/webapps"
end

execute 'tomcat_startup' do
  command '/usr/local/apache-tomcat/latest/bin/startup.sh'
  cwd "/usr/local/apache-tomcat/latest/bin"
  user "tomcat"
  group "tomcat"
end


