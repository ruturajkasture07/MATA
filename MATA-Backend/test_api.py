import requests
import json
import base64

base_url = "http://127.0.0.1:8000"

# Register
requests.post(f"{base_url}/api/v1/register", json={
    "name": "Test",
    "username": "tester2",
    "age": 20,
    "is_blind": False,
    "email": "test2@test.com",
    "mobile_no": "12345",
    "password": "password"
})

# Login
res = requests.post(f"{base_url}/api/v1/login", json={
    "username": "tester2",
    "password": "password"
})
token = res.json().get("access_token")

# Create dummy image
with open("test.png", "wb") as f:
    f.write(b"123")

# Process
headers = {"Authorization": f"Bearer {token}"}
files = {"file": ("test.png", open("test.png", "rb"), "image/png")}
data = {"age_level": "teen"}

res = requests.post(f"{base_url}/api/v1/process", headers=headers, files=files, data=data)
print(res.status_code)
print(res.text)
