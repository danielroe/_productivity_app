from fastapi import FastAPI, Request, Form
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse, RedirectResponse
from azure.identity import DefaultAzureCredential, ManagedIdentityCredential
from azure.identity import get_bearer_token_provider
from fastapi.templating import Jinja2Templates
from openai import AzureOpenAI

from fastapi import Form
from dotenv import load_dotenv

import uvicorn
import os

load_dotenv()


client_args ={}

# Authenticate using an API key (not recommended for production)
if os.getenv("AZURE_OPENAI_KEY"):
  client_args["api_key"] = os.getenv("AZURE_OPENAI_KEY")
else:
  if client_id := os.getenv("AZURE_OPENAI_CLIENT_ID"):
    # Authenticate using a user-assigned managed identity on Azure
    azure_credential = ManagedIdentityCredential(
      client_id=client_id)
  else:
    # Authenticate using the default Azure credential chain
    azure_credential = DefaultAzureCredential()
  client_args["azure_ad_token_provider"] = get_bearer_token_provider(
    azure_credential, "https://cognitiveservices.azure.com/.default")

# Initialize the AzureOpenAI client
client = AzureOpenAI(
    api_version=os.getenv('AZURE_OPENAI_API_VERSION') or "2024-02-15-preview",
    azure_endpoint=f"https://{os.getenv('AZURE_OPENAI_SERVICE')}.openai.azure.com",
    **client_args,
)

app = FastAPI()

# Mount static files
app.mount("/static", StaticFiles(directory="static"), name="static")
templates = Jinja2Templates(directory="static")

@app.get("/", response_class=HTMLResponse)
async def read_index(request: Request):
    return templates.TemplateResponse("index.html", context={"request":request})

@app.get("/health")
async def health_check():
    return {"status": "OK"}

@app.post("/", response_class=RedirectResponse)
async def create_plan(request: Request, goal_input: str = Form(...)):

    goal = goal_input

    response = client.chat.completions.create(
        
        model=os.getenv("AZURE_OPENAI_GPT_DEPLOYMENT"),
        messages=[
            {"role": "user", "content": f"I want to achieve the following goal: {goal}. Can you create a simple plan to achieve this? Return the results in HTML format, but do not include the html and body tags."}
        ],
        temperature=0,
    )

    plan = response.choices[0].message.content
    print(plan)
    return templates.TemplateResponse("index.html", context={"request":request, "plan": f"{response.choices[0].message.content}", "goal":goal})



if __name__ == "__main__":
    uvicorn.run(app, host="localhost", port=8080)
