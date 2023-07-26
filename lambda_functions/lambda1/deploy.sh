#!/bin/bash

# Créer le répertoire du package de déploiement
mkdir package

# Installer les dépendances dans le répertoire du package de déploiement
pip install --target ./package -r requirements.txt

# Ajouter le code de la fonction Lambda au répertoire du package de déploiement
cp lambda_function.py ./package

# Compresser le répertoire du package de déploiement dans un fichier .zip
cd package
zip -r ../deployment_package.zip .




