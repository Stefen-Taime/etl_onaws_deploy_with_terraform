import boto3
import os
import time

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    glue = boto3.client('glue')

    # Specify your bucket name
    bucket_name = os.environ['BUCKET_NAME']

    # Folders to check
    folders = ['AAPL', 'IBM', 'MSFT']

    # Iterate over the folders and check for JSON files
    for folder in folders:
        # List all objects in the folder
        objects = s3.list_objects_v2(
            Bucket=bucket_name,
            Prefix=folder + '/'
        )
        # Check if any JSON files exist in the folder
        if not any(obj['Key'].endswith('.json') for obj in objects.get('Contents', [])):
            raise Exception(f"No JSON files found in {folder} folder")

    # Start the crawler
    glue.start_crawler(Name=os.environ['GLUE_CRAWLER_NAME'])

    # Wait for the crawler to start running
    while True:
        crawler = glue.get_crawler(Name=os.environ['GLUE_CRAWLER_NAME'])
        if crawler['Crawler']['State'] == 'RUNNING':
            break
        time.sleep(10)  # wait for 10 seconds before checking the crawler status again

    # Wait for the crawler to complete
    while True:
        crawler = glue.get_crawler(Name=os.environ['GLUE_CRAWLER_NAME'])
        if crawler['Crawler']['LastCrawl']['Status'] == 'SUCCEEDED':
            break
        time.sleep(60)  # wait for 60 seconds before checking the crawler status again

    # Start the job
    glue.start_job_run(JobName=os.environ['GLUE_JOB_NAME'])
