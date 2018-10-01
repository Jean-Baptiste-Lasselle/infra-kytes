#!/bin/bash

# Ce script permet d'initialiser ce repository Git, à partir d'un ensemble de fichiers, ajoutés au premier commit.

# - ENV.

# - OPS
git init
git add --all
git add **/*
git commit -m "Commit initial de la Recette Provision de l'innfrastructure Kytes"
git remote add origin git@github.com:Jean-Baptiste-Lasselle/infra-kytes.git
git push -u origin master
