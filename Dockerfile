from python:3.12-slim
workdir /app
copy requirements.txt .
run pip install -r requirements.txt
copy app ./app
expose 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]