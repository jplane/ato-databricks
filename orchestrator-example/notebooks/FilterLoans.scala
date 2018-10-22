// Databricks notebook source

val blobacct = dbutils.widgets.get("blob-account")
val blobkey = dbutils.widgets.get("blob-key")
val blobcontainer = dbutils.widgets.get("blob-container")
val file = dbutils.widgets.get("blob-file")

spark.conf.set("fs.azure.account.key." + blobacct + ".blob.core.windows.net", blobkey)

val inputpath = "wasbs://" + blobcontainer + "@" + blobacct + ".blob.core.windows.net/"

val outputpath = "wasbs://output@" + blobacct + ".blob.core.windows.net/"

val df = spark.read.format("csv").option("header", "true").option("inferSchema", "true").load(inputpath + file)

val loanDF = df.filter(df("Product").contains("loan"))

loanDF.write.option("header", "true").csv(outputpath + "loandata")


// COMMAND ----------


