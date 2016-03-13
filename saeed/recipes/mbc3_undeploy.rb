#By saeed


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


execute "cleaning_webapps" do
  command 'rm -rf *'
  cwd "/usr/local/apache-tomcat/latest/webapps"
  user "tomcat"
  group "tomcat"
end

bash "rollback_release" do
  user "tomcat"
  code <<-EOH
    current_release=`readlink -f /usr/local/apache-tomcat/latest/opsworks-deployment/current/ | rev | cut -d\/ -f1 | rev`
     cd /usr/local/apache-tomcat/latest/opsworks-deployment/releases
     previous_release=`ls -ltr | awk '{print $9}' | sort -n | sed '/^$/d' | tail -2 | head -1`

    cp -rf $previous_release/* /usr/local/apache-tomcat/latest/webapps/
  EOH
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
