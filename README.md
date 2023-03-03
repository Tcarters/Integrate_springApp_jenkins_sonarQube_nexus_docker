# Jenkins pipeline build using SpringApp + jenkins + SOnarQube + Nexus + Docker

### Prerequisites :
- Nexus Server Installed ( Mine is available at  **192.168.1.19:5000** )
- Sonarqube Server Installed ( Accessible at :  **192.168.1.17:9000** )
- Maven Installed on the Jenkins Machine  
- Jenkins server Installed ( Mine is available at **192.168.1.68:8082** )
- A sample SpringBoot Application ( https://github.com/Tcarters/SpringBootApp_and_DevOps ) with two branch: 
   - **nexus-integration** for release package config at Nexus repo 
   - **nexus-snapshot** for snapshot package repository in Nexus repo

- - -

## Step 1: Basic configuration on the SonarQube server:

### 1.1. Launch the SonarQube server 

  ![image](https://user-images.githubusercontent.com/71230412/221385026-84d7d92e-38f3-419b-b9b5-a27be00239b1.png)

### 1.2. Create a new Token which will be used later for jenkins integration 

  ![image](https://user-images.githubusercontent.com/71230412/221386008-651e16e3-59a4-4901-ae4f-8283052eea86.png)

### 1.3 Create a webhook by which Sonarqube will send notification to Jenkins after the Analysis ...
  
  - Going to ``sonarQube Dashboard > Adminisration > Webhooks`` and provide url of jenkins server like http://jenkins-ip-server/sonarqube-webhook/
  
  - ❗ Be sure to add the path `/sonarqube-webhook` otherwise, it won't work ...
  
![image](https://user-images.githubusercontent.com/71230412/221387920-d505cf81-c322-47fe-b480-1ca81f93a95d.png)
 

## Step 2: Configuration and plugins installation on Jenkins Server:

### 2.1  Start the jenkins server 

<!-- ![image] -->
<img width="70%" src="https://user-images.githubusercontent.com/71230412/221383274-46d951d6-30db-4dba-86d3-40c3af1cc961.png"  height="50%"/>

### 2.2 Install Sonarqube plugins required in the Jenkins Server

- A demo of this installation is available in this mini project: https://github.com/Tcarters/Sonarqube_projects/tree/master/jenkins_pipeline_sonarQube. Where we showed how to integrate SonarQube with Jenkins, so feel free to go there and fork this project 😃..

- Looking at the **jenkins Manager Plugin** and search for :
    - `Sonarqube` scanner plugin
    - and `Quality Gate` plugin 
 
    ![image](https://user-images.githubusercontent.com/71230412/221385481-17651394-2850-49d3-b613-7573ccb462b3.png)
    -----
    ![image](https://user-images.githubusercontent.com/71230412/221385558-2f62db4f-58d1-4a2a-a817-5be6a0b826ff.png)

### 2.3 Configure the SonarQube plugin in the Jenkins server:

- First, we go to ``Jenkins Dashboard > Manage Jenkins > Configure System ``
    * After, Jump to the Section **SonarQube servers** and provide:
      - A Name ( Here we give the same name as the one parameter available at ``Global Tool Configuration > Sonarqube ``
      - Your SonarQube server URL like **http://ip_server:port-no**  
      ❗❗ **Don't add slash (/) at the end of URL** ❗❗.
      - And finally the Token of User managing your SonarQube Server , which can be found at :
        
        ![image](https://user-images.githubusercontent.com/71230412/221386008-651e16e3-59a4-4901-ae4f-8283052eea86.png)
  
    * Final configuration review :
  
![image](https://user-images.githubusercontent.com/71230412/221386109-3cebe45b-c410-4172-a62f-f2612d129a6c.png)

🔥 🔥 If you failed to install & configure the plugins look at the following repo where we explained in detail how to do it : https://github.com/Tcarters/Sonarqube_projects

### 2.3 Install the plugin ``pipeline-utility-steps`` :

- This plugin will help us to write a dynamic configuration of a release package to be integrated in the Jenkins pipeline. To install it, same place like others by looking at ``Plugin Managers`` : 
 
  ![image](https://user-images.githubusercontent.com/71230412/221400861-ea4b548a-340d-43d7-9f2e-d4140d71f2ed.png)


## Step 3: Launch a new Jenkins pipeline

### 3.1 Create a new pipeline Job named `javaapp-pipeline`:

<img src="https://github.com/Tcarters/Integrate_springApp_jenkins_sonarQube_nexus_docker/blob/master/Screenshots/s1-jobnew.png" width="50%" height="45%"/>

- Next, jump to the section ``Pipeline`` and define the pipeline script to be executed by Jenkins. 

- At this step, we used the branch **nexus-integration** or you can use `master`  and GitHub repo: https://github.com/Tcarters/SpringBootApp_and_DevOps

- In our Jenkinsfile , we define four stages which go like this
    - Stage 1 ==>  Clone the GitHub repo
    - Stage 2 ==>  Code compiling
    - Stage 3 ==>  MAVEN Cleaning
    - Stage 4 ==>  UNIT TESTING OF MAVEN BUILD
    - Stage 5 ==>  VERIFICATION OF UNIT TEST

- The jenkinsfile code used is defined as :
  
  ```bash
        pipeline{
    
            agent any 
            
            stages {
                
                stage('Cloning Git Repo'){
                    
                    steps{
                        
                        script{
                            
                            git branch: 'nexus-integration', url: 'https://github.com/Tcarters/SpringBootApp_and_DevOps.git'
                        }
                    }
                } //stage1
                stage('Compiling'){
                    steps{
                        script{
                            sh 'mvn compile'
                        }
                    }
                } // stage2
                stage ('MAVEN Cleaning') {
                    steps{
                        script {
                            sh 'mvn clean install'
                        }
                    }
                }//stage3
                stage('MAVEN UNIT Testing'){
                    
                    steps{
                        
                        script{
                            
                            sh 'mvn test'
                        }
                    }
                }//stage4
                stage('Integration Testing'){
                    
                    steps{
                        
                        script{
                            
                            sh 'mvn verify -DskipUnitTests'
                        }
                    }
                }//stage5
            } //end stages
        } 

  ```
### 3.2 Build the 4 stages in our pipeline and get Results:

- Dashboard View of current build 

![image](https://user-images.githubusercontent.com/71230412/222628182-99f5ed86-640b-4225-9fe4-6eca2276f98a.png)


## Step 4: SonarQube Integration in Jenkins pipeline

- Step 1.1 till 1.3 should be done before continuing here... 

### 4.1 Update the Jenkinsfile with new stage:

- The stage 6 for a **Static Code Analysis** by SonarQube Tool:

    ```bash

        stage('SonarQub Static code analysis'){  
                steps{
                    
                    script{
                        
                        withSonarQubeEnv(credentialsId: 'SONARQUBE_TOKEN') {  // Here we refer tname of token configured in our Jenkins sonarQube Server plugin
                            
                            sh 'mvn clean package sonar:sonar'
                        }
                    } // end script
                } // end steps
            } //stage6

    ```

- Run the updated Jenkinsfile, we can see SonarQube Analysis performed successfully

![image](https://user-images.githubusercontent.com/71230412/222630247-fb04dc69-8dcc-4583-b274-fe5154fe2fab.png)

- On Jenkins dashboard View :

![image](https://user-images.githubusercontent.com/71230412/222630680-6873a655-7e43-4195-bc7e-266d26809f98.png)


### 4.2 Adding Quality Gate Analysis in the pipeline Integration:

- To do that , we have to add a new stage7 in which SonarQube will perform a Quality Gate Condition checking of our code and if passsed, It will inform Jenkins to proceed to next build otherwise the pipeline will false and will enter in a rebuild process until the dev Team make a correction to the code.

- The stage 7 code in jenkinsfile will be:
 
```bash
            stage('Quality Gate Status'){
                steps{
                    script {
                        echo '<---------------Quality Gates Analysis Started-------------->'
                        timeout (time: 5) {
                                // Just in case something goes wrong, pipeline will be killed after a timeout
                                // Parameter indicates whether to set pipeline to UNSTABLE if Quality Gate fails
                                // true = set pipeline to UNSTABLE, false = don't
                        def myqualitygate = waitForQualityGate abortPipeline: true , credentialsId: 'SONARQUBE_TOKEN'  // Reuse taskId previously collected by withSonarQubeEnv
                        if ( myqualitygate.status != 'OK' ) {
                            echo "Pipeline aborted due to Quality Gate failure 🎃: ${myqualitygate.status}"
                        }
                        else {
                            echo "Pipeline  succeeded with Quality Gate 🤗 : ${myqualitygate.status}"
                        }
                        } // end timeout
                    } // end script
                } // end steps    
            } //stage7

```
