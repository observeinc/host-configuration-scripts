#!/bin/bash

branch_replace"jlb/refactor"
url="https://raw.githubusercontent.com/observeinc/linux-host-configuration-scripts/${branch_replace}/manifest/app/linux-host.manfiest"

curl $url