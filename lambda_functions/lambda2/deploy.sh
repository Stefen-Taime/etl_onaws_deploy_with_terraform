#!/bin/bash

# Nom du bucket S3
s3_bucket_name=av-financial-analysis-bucket

# Création de l'archive zip pour la deuxième fonction lambda
zip lambda_function.zip lambda_function.py

# Téléchargement de l'archive zip dans le bucket S3, dans le sous-dossier lambda2
aws s3 cp lambda_function.zip s3://$s3_bucket_name/lambda2/lambda_function.zip
