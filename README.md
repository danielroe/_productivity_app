# Productivity App
This is an app that helps you acheieve your goals with LLMs and Python. It allows a user to input a goal and have an LLM generate a plan for how to achieve that goal.

The repository also provisions an Azure OpenAI account with an RBAC role permission for your user account to access,
so that you can use the OpenAI API SDKs with keyless (Entra) authentication. By default, the account will include a gpt-3.5 model, but you can modify `infra/main.bicep` to deploy other models instead.

## Prerequisites

1. Sign up for a [free Azure account](https://azure.microsoft.com/free/) and create an Azure Subscription.
2. Request access to Azure OpenAI Service by completing the form at [https://aka.ms/oai/access](https://aka.ms/oai/access) and awaiting approval.
3. Install the [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd).
   
## Provisioning and testing the app

1. Clone this repository to your local machine.
```shell
git clone https://github.com/marlenezw/productivity_app.git
cd productivity_app 
```

2. Login to Azure:

    ```shell
    azd auth login
    ```

3. Provision the OpenAI account:

    ```shell
    azd provision
    ```

    It will prompt you to provide an `azd` environment name (like "productivity-app"), select a subscription from your Azure account, and select a [location where the OpenAI model is available](https://learn.microsoft.com/azure/ai-services/openai/concepts/models#standard-deployment-model-availability). For this project we recommend "canadaeast". Then it will provision the resources in your account and deploy the latest code. If you get an error or timeout with deployment, changing the location can help, as there may be availability constraints for the OpenAI resource. To change the location run: 

    ```shell
    azd env set AZURE_LOCATION "yournewlocationname"
    ```

4. When `azd` has finished, you should have an OpenAI account you can use locally when logged into your Azure account. You can output the necessary environment variables into an `.env` file like so:

    ```shell
    azd env get-values > .env
    ```

5. Create a new virtual environment using the venv module. This will create a new directory named venv (or any name you choose) in your current directory.

```bash
python3 -m venv venv
```

6. Activate the virtual environment. This changes your shell's environment variables so that running Python will get you this environment's Python and pip.

```bash
source .venv/bin/activate
```

7. Install the necessary dependencies using pip. This will install the packages in the virtual environment, isolated from your global Python environment.

```bash
pip install -r requirements.txt
```

8. Run the app using the uvicorn server. This will start the server on port 8080, and you can access the app by navigating to http://localhost:8080 in your browser.

```bash
make run
```

## Deploy the application with the Azure Developer CLI

The local server provided by FastAPI is useful for testing but should not be used in production. Using the Azure Developer CLI, you can also deploy the app to Azure Container Instances. 

To do so you can run: 
```bash
azd up
```

⏳ Wait until the deployment has finished and navigate to the URL provided in the output to access the app.

## Example of using the app 

![](https://github.com/marlenezw/galaxy_productivity_app/blob/main/goal_example.png)



