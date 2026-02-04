import uvicorn
import os

if __name__ == "__main__":
    target = "server.inference_server:app"
    if os.path.basename(os.getcwd()).lower() == "server":
        target = "inference_server:app"
    uvicorn.run(target, host="127.0.0.1", port=8000, reload=False)
