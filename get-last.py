import json
from urllib.request import urlopen

repo = "cheeseformice/dressroom-assets"
response = urlopen(f"https://api.github.com/repos/{repo}/releases/latest")
release = json.loads(response.read())

# v1.666 -> 666
version = release["tag_name"].split(".")[1]

print(f"::set-output name=version::{version}")