~~~
Dockerfile

FROM python:3.11.7-slim

WORKDIR /app

COPY ./requirements.txt /code/requirements.txt

RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt

COPY ./main.py /app/

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]


main.py

from fastapi import FastAPI
import asyncio

app = FastAPI()

@app.on_event("shutdown")
async def shutdown_event():
    print("Shutdown event triggered....")
    for i in range(20, 0, -1):
        await asyncio.sleep(1)
        print(f"Shutdown after {i}s")
    print("Shutdown completed.")

@app.get("/")
async def home():
    return {"message": "hello"}


delay-shutdown:1.0

~~~
