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
-  Viewing the Console Output in Jenkins platform :

![image](https://user-images.githubusercontent.com/71230412/222632385-5f275535-a4a7-484d-af62-e854cc5e0a02.png)

- On the Dashboard after refresh , we can see a Notification below showing the Quality Gate Checking passed

![image](https://user-images.githubusercontent.com/71230412/222632631-734479e6-0ef9-46e8-8851-6d796d97caea.png)


## Step 5:  Nexus Server Integration to Jenkins server :
At this step we have to configure a Nexus Repo for Jenkins integration.

### 5.1 Create a Nexus repo
- First, Launch your Nexus Server Machine: 

  ![image](https://user-images.githubusercontent.com/71230412/221390012-3ffc0c6d-97c2-4b20-a708-daee244f7a74.png)
 
- Create a new Nexus repository 
  - We have to go : ``Settings > Repository `` , and click *Create repository*
  - After select the type of repository as **Maven 2 hosted**
  - Ok, now Put a name `javaapp-release`
      ![image](https://user-images.githubusercontent.com/71230412/221390255-99c12501-d454-4444-b86f-b1ad82a081ed.png)
  
  - As we are creating a Nexus release repository so , we keep the ``Version policy`` as : **Release**
  - And finally, click ``Create repository`` to create it :

  ![image](https://user-images.githubusercontent.com/71230412/221390373-bad08de0-ce6c-4b12-9986-e82b8b8b6089.png)

### 5.2 Configure a connection between Nexus server and Jenkins Server
  
- For that we have to install a Jenkins plugin called  **Nexus Artifact Uploader**
  
    ![image](https://user-images.githubusercontent.com/71230412/221391986-14a87b00-185e-4d8d-be25-7ce270babb63.png)
  
- Get the nexus integration script
    * To do it just go to the current job **Pipeline Syntax** at ``Dashboard >javaapp>Pipeline Syntax`` 

  ![image](https://user-images.githubusercontent.com/71230412/221393421-0e528a4e-a532-4880-897e-329cee32095a.png)

    * Set up the credentials to be used by jenkins for connection to nexus server
  
  ![image](https://user-images.githubusercontent.com/71230412/221393325-74da5461-68df-4866-9f23-1cbfb0e41608.png)

    * Provide a `username` and `Password`, it should be the one configured on the nexus server ...
  
  ![image](https://user-images.githubusercontent.com/71230412/221393370-3ab9eda7-9cf1-4089-a8ff-bd11b22b360b.png)
  
    * And save it.
  
    * Now add a `GroupId`, which can be retrieve by looking at the **pom.xml** of the Application code.
      
        - In our example, It's **com.springIndocker**. Just by looking at the line ***11*** of the pom file of:  https://github.com/Tcarters/SpringBootApp_and_DevOps/blob/nexus-integration/pom.xml  on branch **nexus-integration**

<br />

  ![image](https://user-images.githubusercontent.com/71230412/221393511-5da8bf44-31bf-4f6b-953a-b8aa0cafcc41.png)  

- Same process for the **Version**, here It's  ``1.0.0`` for **master** barnch
- :exclamation: And ``1.0.1`` for the branch **nexus-integration**

- For the Nexus ``Repository``configuration, looking at the nexus server repo created earlier  

![image](https://user-images.githubusercontent.com/71230412/221393734-cbc3dd89-2b92-4698-ab38-7840e046f2ba.png)


### 5.3 Create a new stage for Artifact release creation and uploading to Nexus Server

- Now back to the Jenkins Pipeline Syntax page, provide **Artifacts** configuration by clicking on `Add` button like:
 
![image](https://user-images.githubusercontent.com/71230412/221399239-37ae6ec4-bc74-446d-96e5-6d8a59e4fe92.png)

- Provide an **ArtifactId** which can be get by looking again in the pom.xml file https://github.com/Tcarters/SpringBootApp_and_DevOps/blob/master/pom.xml 

![image](https://user-images.githubusercontent.com/71230412/221399239-37ae6ec4-bc74-446d-96e5-6d8a59e4fe92.png)

- For the `Type` , we choose a **Jar** file type

- And finally the `File` name as `target/javaspringapp-v01.jar`, which should normally be available in the pom.xml file build code section line ...

- Final Artifact review :
  
![image](https://user-images.githubusercontent.com/71230412/221394137-7e072b00-fcea-4ecc-873b-e35060e89042.png)


- Still on current Job, Click Pipeline script to generate it 
  - The Artifact script generated: 

```bash
    nexusArtifactUploader artifacts: [[artifactId: 'springbootV3-docker', classifier: '', file: 'target/javaspringapp-v01.jar', type:                           'jar']], credentialsId: '', groupId: 'com.springIndocker', nexusUrl: '192.168.1.19:5000', nexusVersion: 'nexus3', protocol: 'http',                          repository: 'javaapp-release ', version: '1.0.0'
```
![image](https://user-images.githubusercontent.com/71230412/221398679-5ea10c6b-fc0e-48ae-9af6-5fd009309bdb.png)

### 5.4 Update the Jenkinsfile script with a new stage for nexus Integration :

- First us tested with Master branch using the version ``1.0.0``  

  ```bash
        stage('Upload our Jar file to Nexus server '){
            steps{
                script {
                    nexusArtifactUploader artifacts: [
                        [
                            artifactId: 'springbootV3-docker', 
                            classifier: '', 
                            file: 'target/javaspringapp-v01.jar', 
                            type: 'jar'
                        ]
                    ],
                    credentialsId: 'nexus-auth', 
                    groupId: 'com.springIndocker', 
                    nexusUrl: '192.168.1.19:5000', 
                    nexusVersion: 'nexus3', 
                    protocol: 'http', 
                    repository: 'javaapp-release ', 
                    version: '1.0.0'
                }
            } //end steps
        } //stage8
 
  ```
- Result of The build process with the Master branch on version ``1.0.0 ``
  
  - Consultation of package uploaded on the ``Nexus server ``
  
![image](https://user-images.githubusercontent.com/71230412/221400231-a1b7a0ce-8760-41fb-972d-5dd37fd24091.png)
 
### 5.5 Test again with version 1.0.1 of ``pom.xml`` on branch nexus-integration :
- The pom.xml file of the package looks like :
  
  ![image](https://user-images.githubusercontent.com/71230412/222545675-484b7f27-8f3e-4711-a9c4-643cbb5ca907.png)

- Build again the pipeline , we see a second package 1.0.1 in our nexus Repository  

  ![image](https://user-images.githubusercontent.com/71230412/222545889-61c3ba03-0c92-489c-9edb-6319b0c767ee.png)


- - -

### Possible Errors to get while building the pipeline for Nexus Integration
  
#### Case of using ``pipeline utility steps`` 
- In case , we got error for script Approval , click on the `blue` link link on below to get access to the script
  
![image](https://user-images.githubusercontent.com/71230412/222538172-11c82013-e7e3-4fce-8dd2-563eaf5030ac.png)

- Click *Approve* to give it access 

![image](https://user-images.githubusercontent.com/71230412/222538503-cd8b465f-7096-4ab5-8627-30f21c541cdf.png)

- At the end of access given , we got : 
![image](https://user-images.githubusercontent.com/71230412/222538784-b5e6b4a8-9251-40f5-9c67-787523f59594.png)

- - -


- :exclamation: Step 5.4 & 5.5 for 5.6 are the same but we prefer the 5.6 because of the Dynamic support in the script :exclamation:

### 5.6 Updating our Pipeline script with SNAPSHOT creation and Dynamic support :

- For this step, we used the branch **nexus-snapshotrepo**

- The stage 8 will be written like  this :

```bash
          stage('Upload our Jar file to Nexus server '){
            steps{
                script {
                    def readPomVersion = readMavenPom file: 'pom.xml'
                    
                    def nexusRepo = readPomVersion.version.endsWith("SNAPSHOT") ? "javaapp-snapshot" : "javaapp-release"

                    nexusArtifactUploader artifacts: [
                        [
                            artifactId: 'springbootV3-docker', 
                            classifier: '', 
                            file: 'target/javaspringapp-v01.jar', 
                            type: 'jar'
                        ]
                    ],
                    credentialsId: 'nexus-auth', 
                    groupId: 'com.springIndocker', 
                    nexusUrl: '192.168.1.19:5000', 
                    nexusVersion: 'nexus3', 
                    protocol: 'http', 
                    repository:  nexusRepo, //'javaapp-release', 
                    version: "${readPomVersion.version}" //using dynamic reading version     '1.0.0'
                } // end script
            } //end steps
        }//stage8
```
- And Finally, run the pipeline with the new branch **nexus-snapshotrepo** for snapshot creation of the repository https://github.com/Tcarters/SpringBootApp_and_DevOps 


### 5.7 Build Result 

- On the Nexus platform, we can see our Artifact snaphost uploaded successfully by jenkins.

  ![image](https://user-images.githubusercontent.com/71230412/222575776-82c0d959-5f07-4275-bd67-9192c6e69afd.png)

- Console Output in Jenkins platform :

![image](https://user-images.githubusercontent.com/71230412/222642562-dcd9a784-7458-49de-8491-eba3aaf62503.png)

- Jenkins Dashboard View Result :

![image](https://user-images.githubusercontent.com/71230412/222642668-e5579279-9d21-4ace-a933-02e0ed51660c.png)

## Step 6: Build the Docker Image of our Application after Nexus stage
  
### 6.1 Define a Dockerfile 

- For this step, we'll work with the branch  **nexus-snapshotrepo** of our current Repository: https://github.com/Tcarters/SpringBootApp_and_DevOps
- And the Dockerfile is already defined in the gitHub repo for the above mentioned branch.

- For that , we have to create a ``Dockerfile``
    - Content of ``Dockerfile`` :
  
```bash
      FROM maven as build
      LABEL maintainer=" Tcarters a.k.a @Tdmund_"
      WORKDIR /app 
      COPY . .
      RUN mvn install 

      FROM openjdk:11.0
      WORKDIR /app
      COPY --from=build /app/target/javaspringapp-v01.jar /app/

      EXPOSE 8080
      CMD [ "java", "-jar", "javaspringapp-v01.jar" ]
  
```

### 6.2 Update the Jenkinsfile with a new stage:

- ❗Before continue, if docker isn't installed on local machine running jenkins; go and install it.

- For Docker configuration and Integration to Jenkins , check this Repo: https://github.com/Tcarters/mini-DevOps-Project_jenkins-springBoot-Docker

- New stage script :

  ```bash
        stage('Build Docker Image of App'){
            steps{
                script {
                    echo 'Starting Docker Image building'
                    echo 'Build Image from current Jenkins job-name & build-id'
                    sh 'docker image build -t $JOB_NAME:v1.$BUILD_ID .' // Don't forget at cmd end ``point``
                    echo 'Tag the Image with our DockerHub name'
                    sh 'docker image tag $JOB_NAME:v1.$BUILD_ID tcdocker2021/springbt-in-docker:from_Nexus_Snapshot '
                    echo 'Listing current Images '
                    sh 'docker image ls'
                }
            }
        } //end stage9
        
  ```
#### 6.2.1 Result of the pipeline build 

- Console Output view :

![image](https://user-images.githubusercontent.com/71230412/222646353-5da33e6a-f6db-4489-8033-bd22ec2e6226.png)

- Dashboard View :

![image](https://user-images.githubusercontent.com/71230412/222646436-c5aef630-12d6-4535-9981-4143e2cfc662.png)


## Step 7: Push the App Image to DockerHub
### 7.1 Get script from Pipeline Syntax
- Looking at ``Dashboard > current Job > Pipeline Syntax`` and select ``withCredentials`` by which we can bind our DockerHub credentials to Jenkins variable

  ![image](https://user-images.githubusercontent.com/71230412/222600807-3cd0b163-b0e5-406c-ae49-48d23f8ae7c9.png)

- Under **Bindings**, choose **Secret text**
- After Provide your ``DockerHub Account password`` and then click ``Generate Pipeline Script``
  
![image](https://user-images.githubusercontent.com/71230412/222602160-f1475daa-2cf0-4f01-bb7e-9723728a6cd0.png)

- Copy above script to update our new stage in jenkinsfile

### 7.2 Update the Jenkinsfile with a new stage for Image push  
- Our new stage to be added will be:
  
  ```bash
         stage('Push Image to DockerHub'){
            steps{
                script{
                    echo 'Logging to Docker registry.....'
                    withCredentials([string(credentialsId: 'mytcdocker-hub', variable: 'dockerhub-pwd')]) {
                        sh 'docker login -u tcdocker2021 -p ${dockerhub-pwd}'  //logging to my DockerHub account
                    }
                    echo 'Starting the push of Docker Image ....'
                    sh ' docker push tcdocker2021/springbt-in-docker:fromNexus_Snapshot'
                }
            }
        } // end stage10 
  ```
### 7.3 Visualizing Results of Image deployed on DockerHub
- On the DockerHub Dashboard, we can see our App Image successfully deployed with tag **fromNexus_Snapshot**
  
  ![image](https://user-images.githubusercontent.com/71230412/222610829-27a7864f-f755-4a42-8d96-6ac90c2e865a.png)
 
- Console Output View on Jenkins platform 

- Dashboard view 