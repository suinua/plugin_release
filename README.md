# Plugin Release
![](https://user-images.githubusercontent.com/34801662/159945516-9bca768d-24c7-497f-8a47-2b5ae920eedc.png)  
plugin.ymlのversionの変更を検知して、リリースを作成します

# 導入
```yaml
name: 

on:
  push:
    branches: [ master ]
  pull_request:
    branches: [ master ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v2
      - uses: suinua/plugin_release@master
```