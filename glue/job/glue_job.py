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

# Liste des noms de table
table_names = ["aapl", "ibm", "msft"]

for table_name in table_names:
    # Script generated for node S3 bucket
    S3bucket_node1 = glueContext.create_dynamic_frame.from_catalog(
        database="av_financial_analysis",
        table_name=table_name,
        transformation_ctx="S3bucket_node1",
    )

    # Script generated for node ApplyMapping
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

    # Convert DynamicFrame to DataFrame for more transformations
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

    # Write the transformed data back to S3
    glueContext.write_dynamic_frame.from_options(
        frame = grouped_dyf,
        connection_type = "s3",
        connection_options = {"path": f"s3://av-financial-analysis-bucket/output/{table_name}"},
        format = "csv",
    )

job.commit()
