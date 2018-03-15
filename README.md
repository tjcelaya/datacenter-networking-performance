On every node:

 - JDK 1.8u65 should be installed at `/usr/lib/jvm`
 - /etc/environment should contain `JAVA_HOME` (`/usr/lib/jvm`) and include `JAVA_HOME/bin` in `PATH`

On the controller:

 - Tomcat should be installed at `/usr/share/tomcat/`
 - `/usr/share/tomcat/webapps/` should contain only `ROOT.war` which determines what actually runs at port `8080`
 - `/usr/share/tomcat/webapps/ROOT.war` should be the nGrinder controller WAR

 - started with: `/usr/share/tomcat/bin/startup.sh`
 - stopped with: `/usr/share/tomcat/bin/shutdown.sh`

 - logs: `tail -f /usr/share/tomcat/logs/*`

On the media server:

 - Tomcat should be installed at `/usr/share/tomcat/`
 - `/usr/share/tomcat/webapps/` should contain only `ROOT.war` which determines what actually runs at port `8080`
 - `/usr/share/tomcat/webapps/ROOT.war` should be the media server WAR

 - `/usr/share/tomcat/libs` should include the files from `vendor/media-props`

 - started with: `/usr/share/tomcat/bin/startup.sh`
 - stopped with: `/usr/share/tomcat/bin/shutdown.sh`

 - logs: `tail -f /usr/share/tomcat/logs/*`

On the agent:

 - `ngrinder-agent.tar` should be downloaded from a controller (`controller_ip:8080/download/agent`)

 - started with: `/tmp/ngrinder-agent/run_agent_bg.sh`
 - stopped with: `/tmp/ngrinder-agent/stop_agent.sh`

 - logs: `tail -f /home/ubuntu/.ngrinder-agent/log/agent.log`

On Cassandra:

 - Cassandra should be installed at `/usr/share/cassandra`

 - configuration:
   - the `vendor/cassandra-conf` folder should replace the contents of `/usr/share/cassandra/conf`
   - `/usr/share/cassandra/conf/cassandra.yaml` contains a line starting with `listen_address:` and should be set to the node's private IP:
     ```
     ifconfig | grep 'inet addr' | cut -d ':' -f 2 | awk '{ print $1 }' | grep -E '^(192\.168|10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.)' | head -1
     ```

   - `/usr/share/cassandra/conf/cassandra.yaml` contains a line with `seeds:` and should be set to a comma-delimited list of seed IPs

 - special setup before starting Cassandra:
    - `mkdir -p /usr/share/cassandra/storage`
    - `sudo umount /mnt`
    - sed -i 's~/mnt~/usr/share/cassandra/storage~' `/etc/fstab`
    - `sudo mount -a`
    - verify with `df -h | grep cassandra`
  
 - started with: `/usr/share/cassandra/bin/cassandra`
 - stopped with: `/usr/share/cassandra/bin/nodetool stopdaemon`
 - **nodes will fail to start if they aren't in the seeds list and can't contact the addresses in the seeds list**


 - logs: `tail -f /usr/share/cassandra/storage/logs/system.log`
