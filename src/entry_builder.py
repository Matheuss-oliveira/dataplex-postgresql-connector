"""Creates entries with PySpark for PostgreSQL."""
import pyspark.sql.functions as F
from pyspark.sql.types import StringType

from src.constants import EntryType, SOURCE_TYPE
from src import name_builder as nb


@F.udf(returnType=StringType())
def choose_metadata_type_udf(data_type: str):
    """Map PostgreSQL types to Dataplex metadata types."""
    data_type = data_type.upper()
    if data_type in {"INTEGER", "BIGINT", "SMALLINT", "NUMERIC", "DECIMAL", "REAL", "DOUBLE PRECISION"}:
        return "NUMBER"
    if data_type in {"TEXT", "VARCHAR", "CHAR", "BPCHAR"}:
        return "STRING"
    if data_type in {"TIMESTAMP", "TIMESTAMPTZ", "DATE", "TIME", "TIMETZ"}:
        return "DATETIME"
    if data_type == "BOOLEAN":
        return "BOOLEAN"
    return "OTHER"



def create_entry_source(column):
    """Create Entry Source segment."""
    return F.named_struct(F.lit("display_name"),
                          column,
                          F.lit("system"),
                          F.lit(SOURCE_TYPE))


def create_entry_aspect(entry_aspect_name):
    """Create aspect with general information (usually it is empty)."""
    return F.create_map(
        F.lit(entry_aspect_name),
        F.named_struct(
            F.lit("aspect_type"),
            F.lit(entry_aspect_name),
            F.lit("data"),
            F.create_map()
            )
        )


def convert_to_import_items(df, aspect_keys):
    """Convert entries to import items."""
    entry_columns = ["name", "fully_qualified_name", "parent_entry",
                     "entry_source", "aspects", "entry_type"]

    # Puts entry to "entry" key, a list of keys from aspects in "aspects_keys"
    # and "aspects" string in "update_mask"
    return df.withColumn("entry", F.struct(entry_columns)) \
      .withColumn("aspect_keys", F.array([F.lit(key) for key in aspect_keys])) \
      .withColumn("update_mask", F.array(F.lit("aspects"))) \
      .drop(*entry_columns)


def build_schemas(config, df_raw_schemas):
    """Create dataframe with PostgreSQL schemas."""
    entry_type = EntryType.DB_SCHEMA
    entry_aspect_name = nb.create_entry_aspect_name(config, entry_type)

    # Parent is the database entry
    parent_name = nb.create_parent_name(config, EntryType.DATABASE)

    # UDFs for name generation
    create_name_udf = F.udf(lambda x: nb.create_name(config, entry_type, x), StringType())
    create_fqn_udf = F.udf(lambda x: nb.create_fqn(config, entry_type, x), StringType())

    full_entry_type = entry_type.value.format(
        project=config["target_project_id"],
        location=config["target_location_id"]
    )

    # Use schema_name column instead of USERNAME
    column = F.col("schema_name")
    df = df_raw_schemas.withColumn("name", create_name_udf(column)) \
        .withColumn("fully_qualified_name", create_fqn_udf(column)) \
        .withColumn("parent_entry", F.lit(parent_name)) \
        .withColumn("entry_type", F.lit(full_entry_type)) \
        .withColumn("entry_source", create_entry_source(column)) \
        .withColumn("aspects", create_entry_aspect(entry_aspect_name)) \
        .drop(column)

    return convert_to_import_items(df, [entry_aspect_name])


def build_dataset(config, df_raw, db_schema, entry_type):
    """Build table/view entries for PostgreSQL."""
    schema_key = "dataplex-types.global.schema"

    # Handle PostgreSQL nullability (YES/NO)
    df = df_raw \
        .withColumn("mode", F.when(F.col("is_nullable") == 'YES', "NULLABLE").otherwise("REQUIRED")) \
        .drop("is_nullable") \
        .withColumnRenamed("data_type", "dataType") \
        .withColumn("metadataType", choose_metadata_type_udf("dataType")) \
        .withColumnRenamed("column_name", "name")

    # Aggregate columns per table
    aspect_columns = ["name", "mode", "dataType", "metadataType"]
    df = df.withColumn("columns", F.struct(aspect_columns)) \
        .groupby('table_name') \
        .agg(F.collect_list("columns").alias("fields"))

    # Build schema aspects
    entry_aspect_name = nb.create_entry_aspect_name(config, entry_type)
    df = df.withColumn("schema", F.create_map(
        F.lit(schema_key),
        F.struct(
            F.lit(schema_key).alias("aspect_type"),
            F.create_map(F.lit("fields"), F.col("fields")).alias("data")
        )
    )) \
    .withColumn("entry_aspect", create_entry_aspect(entry_aspect_name)) \
    .drop("fields")

    # Merge aspects
    df = df.select(
        F.col("table_name"),
        F.map_concat("schema", "entry_aspect").alias("aspects")
    )

    # Generate entry metadata
    create_name_udf = F.udf(
        lambda x: nb.create_name(config, entry_type, db_schema, x),
        StringType()
    )
    create_fqn_udf = F.udf(
        lambda x: nb.create_fqn(config, entry_type, db_schema, x),
        StringType()
    )

    parent_name = nb.create_parent_name(config, entry_type, db_schema)
    full_entry_type = entry_type.value.format(
        project=config["target_project_id"],
        location=config["target_location_id"]
    )

    column = F.col("table_name")
    df = df.withColumn("name", create_name_udf(column)) \
        .withColumn("fully_qualified_name", create_fqn_udf(column)) \
        .withColumn("entry_type", F.lit(full_entry_type)) \
        .withColumn("parent_entry", F.lit(parent_name)) \
        .withColumn("entry_source", create_entry_source(column)) \
        .drop(column)

    return convert_to_import_items(df, [schema_key, entry_aspect_name])