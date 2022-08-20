#!/usr/bin/env python3
import traceback
import sys
import yaml
import fileinput
from pathlib import Path
from os.path import exists

#import pprint
#pp = pprint.PrettyPrinter(indent=4)

def cloud_config(path):
  with open(path, "r") as cloud_config_stream:
    try:
      return yaml.safe_load(cloud_config_stream)
    except Exception:
      print(traceback.format_exc())
      exit(1)

config = cloud_config("kubebox_cloud_init.yaml")
config["users"][1]["ssh_authorized_keys"] = []

auth_keys_path = str(Path("~/.ssh/authorized_keys").expanduser())
if exists(auth_keys_path):
  for key in (line for line in fileinput.input(files=(auth_keys_path), encoding="utf-8") if len(line) > 1):
    sanitized_key = key.replace("\n", "").strip().replace("\t", " ")
    config["users"][1]["ssh_authorized_keys"].append(sanitized_key)

print(yaml.dump(config))
