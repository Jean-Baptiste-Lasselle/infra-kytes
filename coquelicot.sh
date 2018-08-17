#!/bin/bash

# - ENV.

# - OPS
git init
git add --all
git add **/*
git commit -m "Commit initial Coquelicot"
git remote add origin git@github.com:Jean-Baptiste-Lasselle/coquelicot.git
git push -u origin master

