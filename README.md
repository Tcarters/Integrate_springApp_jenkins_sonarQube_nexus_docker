# Jenkins pipeline build using SpringApp + jenkins + SOnarQube + Nexus + Docker

### Prerequisites :
- Nexus Server Installed ( Mine is available at  **192.168.1.19:5000** )
- Sonarqube Server Installed ( Accessible at :  **192.168.1.17:9000** )
- Maven Installed on the Jenkins Machine  
- Jenkins server Installed ( Mine is available at **192.168.1.68:8082** )
- A sample SpringBoot Application ( https://github.com/Tcarters/SpringBootApp_and_DevOps ) with two branch 
   - **nexus-integration** for release package config at Nexus repo 
   - **nexus-snapshot** for snapshot package repository in Nexus repo

- - -

## Step 1: Basic configuration on the SonarQube server:

### 1.1. Launch the SonarQube server 

  ![image](https://user-images.githubusercontent.com/71230412/221385026-84d7d92e-38f3-419b-b9b5-a27be00239b1.png)

### 1.2. Create a new Token which will be used later for jenkins integration 

  ![image](https://user-images.githubusercontent.com/71230412/221386008-651e16e3-59a4-4901-ae4f-8283052eea86.png)

### 1.3 Create a webhook by which Sonarqube will send notification to Jenkins anfter the Analysis ...
  
  - Going to ``sonarQube Dashboard > Adminisration > Webhooks`` and provide url of jenkins server like http://jenkins-ip-server/sonarqube-webhook/
  
  - ❗ Be sure to add the path `/sonarqube-webhook` otherwise, it won't work ...
  
![image](https://user-images.githubusercontent.com/71230412/221387920-d505cf81-c322-47fe-b480-1ca81f93a95d.png)
 