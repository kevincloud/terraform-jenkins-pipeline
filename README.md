# Using Terraform In Your Jenkins Pipeline

The material in this repo demonstrates how to use the Terraform Cloud API in your Jenkins CI/CD process. The Jenkinsfile is, of course, where all the magic happens, but we need to easily spin up a Jenkins environment before we can use it.

## What does it do?

Most pipelines have quite a number of steps and dependencies. Oftentimes, the steps include a build, static code analysis, units tests, infrastructure, integration tests, and so on.

## What you'll need

Before you get started, you'll need to make sure you have a few things ready.

* A Terraform Cloud account and organization (not open source)
* AWS Access Key and Secret Key
* An S3 Bucket

## Setting up your environment

For this demo, we'll use two workspaces in Terraform Cloud:

* Fork this repo (https://github.com/kevincloud/terraform-jenkins-pipeline)
* Create a workspace in TFC backed by the repo you just forked
* Fork the simple instance repo (https://github.com/kevincloud/terraform-simple-instance)
* Create another workspace in TFC backed by the simple instance repo you just forked

Now we need to create a policy set to apply to the simple instance workspace.

 * In TFC, go to **Settings -> Policy Sets**
 * In the upper right, click **Connect a new policy set**
 * Choose **GitHub** as your provider
 * Select the simple instance repo you recently forked
 * Under **Policy Set Source**, click **More options**
 * For **Policies Path**, enter `policies/`
 * Under **Scope of Policies**, select **Policies enforced on selected workspaces**
 * In the **Workspaces** section, select your simple instance workspace you recently created, and click **Add workspace**
 * Click **Connect policy set**

It's important to set this policy in order to see how we can override soft policy fails via the Terraform API.

### Cost Estimation

Cost estimation must be enabled for the demo to work properly since one of the sentinel policies limits the cost of the workspace.

 * In TFC, go to **Settings -> Policy Sets**
 * In the main screen, make sure **Enable Cost Estimation for all workspaces** is checked
 * Click **Update settings**

### API Token

Since Jenkins will be accessing Terraform via the API, we'll need to provide Jenkins with an API token. This will be exposed on the Jenkins server as an environment variable. The pipeline script will be able to gain access that way.

To create the token:

 * in Terraform Cloud, click on your user avatar in the upper, right-hand corner, and click **User Settings**
 * On the left hand menu, click **Tokens**
 * Enter a **Description**, and click **Generate token**
 * Store the token in a safe place, as this will be the only time you'll see it.

### Workspace variables

In addition, you'll need to create and set the following variables in your workspaces.

#### Jenkins workspace

 * `aws_access_key`: Your AWS IAM access key. This account should be able to provision any AWS resource
 * `aws_secret_key`: The secret id key paired with the access key
 * `aws_region`: Region to deploy the demo to. Defaults to `us-east-1`
 * `key_pair`: This is the EC2 key pair you created in order to SSH into your EC2 instance
 * `instance_type`: Size of the AWS instance to run the demo on. Defaults to `t3.medium`
 * `org_name`: The name of your Terraform Cloud Organization where these workspaces reside
 * `workspace_name`: The name of the simple instance workspace
 * `bucket`: The name of an S3 bucket where Jenkins can stash an artifact from the build pipeline--just the bucket name only. Make sure this bucket exists in the same region as specified above
 * `tfe_api_token`: This is the API token from Terraform Cloud which has access to the respective workspaces
 * `prefix`: Unique prefix for naming (ex: kevincloud)

#### Simple instance workspace

 * `aws_access_key`: Your AWS IAM access key. This account should be able to provision any AWS resource
 * `aws_secret_key`: The secret id key paired with the access key
 * `aws_region`: Region to deploy the demo to. Defaults to `us-east-1`
 * `key_pair`: This is the EC2 key pair you created in order to SSH into your EC2 instance
 * `instance_type`: Size of the AWS instance to run the demo on. Defaults to `t3.large`
 * `prefix`: Unique prefix for naming (ex: kevincloud)

 :warning: Make sure the cost of `instance_type` exceeds $10 per month in order for the pipeline to work correctly, as there this is a Sentinel policy with a monthly limit of $10 for `instance_type` to showcase a Sentinel soft-mandatory override within Jenkins.

## Spinning up Jenkins

Our Jenkins pipeline will kick off a run for the simple instance, so we'll leave that one alone for now. But we do need to manually kick off a run for our Jenkins server. A `t3.medium` should be sufficient to run Jenkins and a maven build.

 * In Terraform Cloud, go to **Workspaces**
 * Click on your Jenkins workspace
 * In the upper, right-hand corner, click **Queue plan**, then **Queue plan**
 * Once the plan is finished, **Confirm & Apply** and **Confirm Plan**

Jenkins doesn't provide a mechanism for automated installs, so the bootstrap process overlays a previously installed instance which is ready to use. Once the apply is finished, you'll be provided with the IP address of the instance, along with a URL to manage Jenkins.

The boostrap process requires about 2-4 minutes. To be safe, give it 5 minutes. Or, you can SSH into the instance and run `tail -f /var/log/cloud-init-output.log` and wait for the last three lines appear, similar to:

```
All done!
Cloud-init v. ... running ...
Cloud-init v. ... finished ...
```

### Setting up your pipeline

Now that our Jenkins server is ready to go, we can login. Navigate to the URL provided in the workspace's output. Login to the Jenkins server with the following credentials:

Username: `devops`
Password: `SuperSecret1`

#### Entering your AWS credentials

Just one more step before we create the pipeline: add our AWS credentials into Jenkins so our pipeline can securely interact with AWS.

 * From the left-hand menu, click **Credentials**, then **System** just below it
 * Click **Global credentials (unrestricted)** from the listing--it will be the only one listed
 * From the left-hand menu, click **Add Credentials**
 * In the **Kind** menu, select **AWS Credentials**
 * Enter the following values:
   * **ID**: pipeline-credentials
   * **Access Key ID**: _your AWS access key ID_
   * **Secret Access Key**: _your AWS secret key_
 * Click **OK**
 * Click **Jenkins** in the upper, left-hand corner

#### Creating the pipeline

Now we're ready to create our pipeline, and the code is all ready for you. Locate the `scripts/Jenkinsfile` file in the Jenkins repo you forked and have it ready and available to use. We're going to need the contents of that file in the steps below.

 * In the menu on the left, click **New Item**
 * Enter `custom-api` as the item name
 * Select **Pipeline** from the options
 * Click **OK** at the bottom of the option list
 * Click the **Pipeline** tab at the top, or just scroll all the way down on the page
 * Copy the contents of the `Jenkinsfile` file to the clipboard, and paste it into the **Script** text area
 * Click **Save**

## Ready to run!

With everything setup and ready to go, you can now click **Build Now** from the menu on the left.

#### Step 1 - Clone

Jenkins is going to clone a java project

#### Step 2 - Build

Maven will build the project and produce a `jar` file

#### Step 3 - Upload Binary

The `jar` file will be uploaded to your S3 bucket

#### Step 4 - Run Terraform

Terraform will create an instance in AWS. Once you get to this step, you can watch your plan from within Terraform Cloud and your pipeline, seeing how Jenkins is managing the process.

Once Terraform runs the policy check, your Jenkins pipeline will be paused, waiting for input.

 * Hover your mouse over the box below the **Run Terraform** step
 * Check the **Override** box, and click **Continue**

Continue watching the interaction from the Terraform run.

 * Once again, hover your mouse over the box below the **Run Terraform** step
 * Check the **Apply** box, and click **Contine**

As you continue to watch in Terraform Cloud, you'll see how it responds to the API requests it received from Jenkins.

Enjoy!
