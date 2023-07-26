import json
import boto3
import requests
import os
from datetime import datetime

def flatten_data(data):
    metadata = data['Meta Data']
    time_series = data['Time Series (Daily)']
    new_data = []
    for date, values in time_series.items():
        flattened_record = metadata.copy()
        flattened_record.update(values)
        flattened_record['date'] = date
        new_data.append(flattened_record)
    return new_data

def lambda_handler(event, context):
    s3 = boto3.resource('s3')
    apikey = ''
    symbols = ['MSFT', 'AAPL', 'IBM']

    # Lire le nom du bucket à partir des variables d'environnement
    bucket_name = os.environ['BUCKET_NAME']

    for symbol in symbols:
        url = f'https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol={symbol}&outputsize=full&apikey={apikey}'
        r = requests.get(url)
        data = r.json()

        # Aplatir les données
        data = flatten_data(data)

        # Get the current date as a string
        date_str = datetime.now().strftime('%Y-%m-%d')

        # Use the date string and the symbol in the key
        key = f'{symbol}/{date_str}-{symbol}.json'
        
        # Prepare the multi-line string
        lines = ""
        for record in data[:100]:  # Only take the first 100 records
            line = json.dumps(record) + "\n"
            lines += line

        # Write the multi-line string to the S3 object
        s3.Bucket(bucket_name).put_object(Key=key, Body=lines)
