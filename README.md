
## Automating Data Pipeline Deployment on AWS with Terraform: Utilizing Lambda, Glue, Crawler, Redshift, and S3

![Automating Data Pipeline Deployment on AWS with Terraform](https://cdn-images-1.medium.com/max/3840/1*X8GQswkaH8T278wAinFm0g.png)

## Table of Contents

 1. Objective

 2. Pre-requisites

 3. Components

 4. Source Systems

 5. Schedule & Orchestrate

 6. Extract

 7. Load

 8. Transform

 9. Data Visualization

 10. Choosing Tools & Frameworks

 11. Future Work & Improvements

 12. Further Reading

 13. Setup

 14. Important Note on Costs

## Objective

The objective of this guide is to demonstrate how to automate the deployment of a data pipeline on AWS using Terraform. The pipeline will utilize AWS services such as Lambda, Glue, Crawler, Redshift, and S3. The data for this pipeline will be extracted from a Stock Market API, processed, and transformed to create various views for data analysis.

## Pre-requisites

Before we begin, make sure you have the following:

* Basic understanding of AWS services

* Familiarity with Terraform

* AWS account with IAM :

![](https://cdn-images-1.medium.com/max/2852/1*pKU5x1DsGE71zwBCwW9jTg.png)

* Terraform installed on your local machine

## Components

The main components of our data pipeline are:

* AWS Lambda: Used for running serverless functions.

* AWS Glue: Used for ETL (Extract, Transform, Load) operations.

* AWS Crawler: Used for cataloging data.

* Amazon Redshift: Used for data warehousing and analysis.

* AWS S3: Used for data storage.

## Source Systems

In this pipeline, the source system is an API from which Lambda1 extracts data.

## Schedule & Orchestrate

Lambda2 is scheduled to execute the Crawler and the Glue Job, orchestrating the flow of data through the pipeline.

    import boto3
    import os
    import time
    
    def lambda_handler(event, context):
        s3 = boto3.client('s3')
        glue = boto3.client('glue')
    
        
        bucket_name = os.environ['BUCKET_NAME']
        
        folders = ['AAPL', 'IBM', 'MSFT']
    
        for folder in folders:
            objects = s3.list_objects_v2(
                Bucket=bucket_name,
                Prefix=folder + '/'
            )
            
            if not any(obj['Key'].endswith('.json') for obj in objects.get('Contents', [])):
                raise Exception(f"No JSON files found in {folder} folder")
    
        glue.start_crawler(Name=os.environ['GLUE_CRAWLER_NAME'])
    
        while True:
            crawler = glue.get_crawler(Name=os.environ['GLUE_CRAWLER_NAME'])
            if crawler['Crawler']['State'] == 'RUNNING':
                break
            time.sleep(10)  
    
        
        while True:
            crawler = glue.get_crawler(Name=os.environ['GLUE_CRAWLER_NAME'])
            if crawler['Crawler']['LastCrawl']['Status'] == 'SUCCEEDED':
                break
            time.sleep(60)  
    
        glue.start_job_run(JobName=os.environ['GLUE_JOB_NAME'])

## Extract

Data is extracted from the API by Lambda1 and stored in an S3 bucket.

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
    
        bucket_name = os.environ['BUCKET_NAME']
    
        for symbol in symbols:
            url = f'https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol={symbol}&outputsize=full&apikey={apikey}'
            r = requests.get(url)
            data = r.json()
    
            data = flatten_data(data)
    
            
            date_str = datetime.now().strftime('%Y-%m-%d')
    
            
            key = f'{symbol}/{date_str}-{symbol}.json'
            
            
            lines = ""
            for record in data[:100]:  # Only take the first 100 records
                line = json.dumps(record) + "\n"
                lines += line
    
            
            s3.Bucket(bucket_name).put_object(Key=key, Body=lines)

## Load

The Crawler loads the data from the S3 bucket into a database with three tables.

## Transform

The Glue Job transforms the data by reading it from the catalog, applying transformations, and writing the output back into the S3 bucket.

    import sys
    from awsglue.transforms import *
    from awsglue.utils import getResolvedOptions
    from pyspark.context import SparkContext
    from awsglue.context import GlueContext
    from awsglue.job import Job
    from pyspark.sql import functions as F
    from awsglue.dynamicframe import DynamicFrame
    
    args = getResolvedOptions(sys.argv, ["JOB_NAME"])
    sc = SparkContext()
    glueContext = GlueContext(sc)
    spark = glueContext.spark_session
    job = Job(glueContext)
    job.init(args["JOB_NAME"], args)
    
    table_names = ["aapl", "ibm", "msft"]
    
    for table_name in table_names:
        S3bucket_node1 = glueContext.create_dynamic_frame.from_catalog(
            database="av_financial_analysis",
            table_name=table_name,
            transformation_ctx="S3bucket_node1",
        )
    
        ApplyMapping_node2 = ApplyMapping.apply(
            frame=S3bucket_node1,
            mappings=[
                ("`1. information`", "string", "`1. information`", "string"),
                ("`2. symbol`", "string", "`2. symbol`", "string"),
                ("`3. last refreshed`", "string", "`3. last refreshed`", "date"), 
                ("`4. output size`", "string", "`4. output size`", "string"),
                ("`5. time zone`", "string", "`5. time zone`", "string"),
                ("`1. open`", "string", "`1. open`", "double"),
                ("`2. high`", "string", "`2. high`", "double"),
                ("`3. low`", "string", "`3. low`", "double"),
                ("`4. close`", "string", "`4. close`", "double"),
                ("`5. volume`", "string", "`5. volume`", "bigint"),
                ("date", "string", "date", "date"), 
                ("partition_0", "string", "partition_0", "string"),
            ],
            transformation_ctx="ApplyMapping_node2",
        )
    
        
        df = ApplyMapping_node2.toDF()
    
        # Group by the 'symbol' column and calculate the mean, min, max of the specified columns
        grouped_df = df.groupBy("`2. symbol`").agg(
            F.mean("`1. open`").alias("average_open"),
            F.min("`1. open`").alias("min_open"),
            F.max("`1. open`").alias("max_open"),
    
            F.mean("`4. close`").alias("average_close"),
            F.min("`4. close`").alias("min_close"),
            F.max("`4. close`").alias("max_close"),
    
            F.mean("`2. high`").alias("average_high"),
            F.min("`2. high`").alias("min_high"),
            F.max("`2. high`").alias("max_high"),
    
            F.mean("`3. low`").alias("average_low"),
            F.min("`3. low`").alias("min_low"),
            F.max("`3. low`").alias("max_low"),
        )
    
        # Convert back to DynamicFrame
        grouped_dyf = DynamicFrame.fromDF(grouped_df, glueContext, "grouped_dyf")
    
        glueContext.write_dynamic_frame.from_options(
            frame = grouped_dyf,
            connection_type = "s3",
            connection_options = {"path": f"s3://av-financial-analysis-bucket/output/{table_name}"},
            format = "csv",
        )
    
    job.commit()

## Data Visualization

Redshift reads the data from the catalog and creates views for visualization. Here are some examples of the views that can be created:

* Stock performance comparison view: This view compares the daily performance of three stocks (AAPL, IBM, and MSFT). It includes columns for date, stock symbol, opening price, closing price, highest price, lowest price, and stock volume.

* Daily stock statistics view: This view calculates daily statistics for each stock, such as the percentage change between the opening and closing price, the difference between the highest and lowest price, and the total volume of shares traded.

* Stock trends view: This view plots stock trends over a period of time. For example, it can calculate the moving average of closing prices over 7 days, 30 days, and 90 days for each stock.

* Most-traded shares view: This view ranks stocks according to the total volume of shares traded each day. This can help identify the most popular or active stocks on the market.

* Stock correlation view: This view examines the correlation between the price movements of different stocks. For example, if the price of the AAPL share rises, does the price of the IBM share also rise?

* Choosing Tools & Frameworks

The tools and frameworks were chosen based on their integration with AWS and their ability to handle the tasks required for this pipeline. Terraform was chosen for its infrastructure as code capabilities, allowing for easy deployment and management of the pipeline.

## Future Work & Improvements

* Regularly monitor and optimize your pipeline to ensure it remains efficient as your data grows.

* Implement proper error handling and alerting mechanisms to quickly identify and resolve any issues.

## Setup

To get started with this project, follow the steps below:

 1. Ensure you have configured your AWS environment using aws configure.

 2. Clone the project repository to your local machine using the following command: git clone [https://github.com/Stefen-Taime/etl_onaws_deploy_with_terraform.git](https://github.com/Stefen-Taime/etl_onaws_deploy_with_terraform.git)

 3. Navigate to the project directory: cd etl_onaws_deploy_with_terraform

 4. Familiarize yourself with the project structure using the tree command. The project structure should look like this:

    .
    ├── glue
    │   ├── crawler
    │   │   └── main.tf
    │   └── job
    │       ├── glue_job.py
    │       └── main.tf
    ├── lambda_functions
    │   ├── lambda1
    │   │   ├── deploy.sh
    │   │   ├── lambda_function.py
    │   │   ├── main.tf
    │   │   └── requirements.txt
    │   └── lambda2
    │       ├── deploy.sh
    │       ├── lambda_function.py
    │       └── main.tf
    ├── main.tf
    ├── outputs.tf
    ├── redshift
    │   ├── network.tf
    │   ├── outputs.tf
    │   ├── provider.tf
    │   ├── redshift-cluster.tf
    │   ├── redshift-iam.tf
    │   ├── security-group.tf
    │   ├── terraform.tfstate
    │   ├── terraform.tfvars
    │   └── variables.tf
    ├── s3
    │   └── main.tf
    └── variables.tf

 1. Package the Lambda1 function. Navigate to the Lambda1 directory (cd lambda_functions/lambda1), grant execute permissions to the deployment script (chmod a+x deploy.sh), and run the script (./deploy.sh). You should see a deployment_package.zip file generated.

 2. Return to the root directory of the project. At this point, we will deploy the first two essential modules for data ingestion: the Lambda1 function and the S3 bucket. In the main.tf file located at the root of the project, you can keep only the S3 and Lambda1 modules and comment out or temporarily remove the rest.

 3. Once ready, run terraform init to initialize your Terraform workspace, followed by terraform plan. At this stage, you will need to enter the ARN of the Lambda function. You can enter an example ARN, such as MyArnLambda.

 4. After that, run terraform apply -var="account_id=". You can find your account ID in the AWS console at the top right. If everything goes well, you should see an output similar to this image:

![](https://cdn-images-1.medium.com/max/2000/1*MQCNMiBRCjXrPQNsR_2_tQ.png)

5. Go to the AWS console and execute the Lambda function. Check the S3 bucket, and you should see three folders: aapl, ibm, msft.

![](https://cdn-images-1.medium.com/max/2572/1*gBqMgz2F394h0Xp3V6PV8A.png)

![](https://cdn-images-1.medium.com/max/3584/1*yfoHRj_E_EFMSta1Srcbzg.png)

6. Once deployed, return to the main.tf file at the root of the project and uncomment the Module2 section, which includes the Glue Crawler and Glue Job. Run terraform init, terraform plan, and terraform apply again.

7. The output should look like this:

![](https://cdn-images-1.medium.com/max/2000/1*TlQjxn_zExGIWD6I7qF98Q.png)

![](https://cdn-images-1.medium.com/max/3122/1*SqN7rOTzxjyNZvUT8fJ64Q.png)

8. Deploy Module3, which includes the Lambda2 function. Do the same as you did with Lambda1: navigate to the Lambda2 directory (cd lambda_functions/lambda2), grant execute permissions to the deployment script (chmod a+x deploy.sh), and run the script (./deploy.sh).

9. Return to the root of the project and run terraform init, terraform plan, and terraform apply.

![](https://cdn-images-1.medium.com/max/2004/1*j3wTYloA20vH8YDImNrptw.png)

10. Once deployed, go to the AWS Lambda console and execute the second function. It should trigger the Crawler and the Glue Job. You can verify this by checking the image:

![](https://cdn-images-1.medium.com/max/3010/1*dkwrb7BAiu17k7Hd3rZyng.png)

![](https://cdn-images-1.medium.com/max/3532/1*pIiyJB0Bvk0m6i709N7N9w.png)

![](https://cdn-images-1.medium.com/max/2000/1*JNs3aKKIbvpeK5zN7yvOJQ.png)

![](https://cdn-images-1.medium.com/max/3044/1*cbtjpE65vhL2DnWy6lNncQ.png)

Note: The Glue Job execution may fail. This is because the Glue Job executes at the same time as the Crawler, and the Glue Job uses the catalog created by the Crawler. The error occurs because the catalog is not found as it is being created at the same time. The solution is to manually re-execute the Glue Job by clicking on ‘Run’ at the top right.

![](https://cdn-images-1.medium.com/max/3640/1*pYQwosNmAnxi5Ei1U49Akg.png)

11. Once all these are executed, you should have an output folder in the bucket and a database containing three tables in the catalog.

![](https://cdn-images-1.medium.com/max/3094/1*vHtC4Aeu6j44oiBR9orOKA.png)

12. The final step of the project will be to deploy the Redshift cluster. To do this, navigate to the redshift directory and fill in your AWS key and ID in the terraform.tfvars file.

13. Still in the redshift directory, run terraform init, terraform plan, and terraform apply.

![](https://cdn-images-1.medium.com/max/2132/1*WCzKqUiowWPRVBz1XqLk1Q.png)

14. Once deployed, connect to the data catalog in Redshift, which contains three tables. You can create scripts for various views such as comparison of stock performance, daily stock statistics, stock trends, most traded stocks, and correlation between stocks.

    SELECT 
      "date",
      symbol, 
      "1. open" as "open", 
      "4. close" as "close", 
      "2. high" as "high", 
      "3. low" as "low", 
      "5. volume" as "volume"
    FROM 
      (
        SELECT 
          "date", 
          'AAPL' as symbol, 
          "1. open", 
          "4. close", 
          "2. high", 
          "3. low", 
          "5. volume"
        FROM 
          test.aapl
        UNION ALL
        SELECT 
          "date", 
          'IBM' as symbol, 
          "1. open", 
          "4. close", 
          "2. high", 
          "3. low", 
          "5. volume"
        FROM 
          test.ibm
        UNION ALL
        SELECT 
          "date", 
          'MSFT' as symbol, 
          "1. open", 
          "4. close", 
          "2. high", 
          "3. low", 
          "5. volume"
        FROM 
          test.msft
      ) 
    ORDER BY 
      "date", 
      symbol;

![](https://cdn-images-1.medium.com/max/3772/1*JcGy7hLdVJex2YrlFlPEIQ.png)

15. Once finished, return to the redshift directory and destroy the infrastructure redshift with terraform destroy. This is crucial to avoid additional costs.

![](https://cdn-images-1.medium.com/max/2000/1*CMJg0kirNHlYN1mJ9CMT-w.png)

16. Also, in the root of the project, run terraform destroy to destroy the Lambda functions, S3 bucket, Crawler, and Glue. You may encounter an error saying that the bucket is not empty. Just empty the bucket manually and try again.

Congratulations! You are now capable of managing a deployment on AWS with Terraform.

## Important Note on Costs

Remember, AWS services are not free, and costs can accumulate over time. It’s crucial to destroy your environment when you’re done using it to avoid unnecessary charges. You can do this by running terraform destroy in your terminal. Please note that I am not responsible for any costs associated with running this pipeline in your AWS environment.
