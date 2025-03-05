"""Reads PostgreSQL using PySpark."""
import os
import logging
from typing import Dict
from pyspark.sql import SparkSession, DataFrame

from src.constants import EntryType

SPARK_JAR_PATH = '/postgresql.jar'
if not os.path.exists(SPARK_JAR_PATH): # for local execution it expects the drive on the project root
    cwd = os.getcwd()
    SPARK_JAR_PATH = cwd + '/postgresql.jar'

logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', level=logging.INFO)
logging.info(SPARK_JAR_PATH)

class PostgreSQLConnector:
    """Reads data from PostgreSQL and returns Spark Dataframes."""

    def __init__(self, config: Dict[str, str]):
        # PySpark entrypoint - java configs to avoid security manager exception for newer spark versions
        self._spark = SparkSession.builder.appName("PostgreSQLIngestor") \
            .config("spark.jars", SPARK_JAR_PATH) \
            .config("spark.hadoop.fs.permissions.enabled", "false") \
            .config("spark.executor.extraJavaOptions", "-Djava.security.manager=allow") \
            .config("spark.driver.extraJavaOptions", "-Djava.security.manager=allow") \
            .getOrCreate()

        self._config = config
        # Updated JDBC URL format for PostgreSQL
        self._url = f"jdbc:postgresql://{config['host']}:{config['port']}/{config['database']}"

    def _execute(self, query: str) -> DataFrame:
        """A generic method to execute any query."""
        return self._spark.read.format("jdbc") \
            .option("driver", "org.postgresql.Driver") \
            .option("url", self._url) \
            .option("query", query) \
            .option("user", self._config["user"]) \
            .option("password", self._config["password"]) \
            .load()

    def get_db_schemas(self) -> DataFrame:
        """Get all schemas in the PostgreSQL database."""
        query = "SELECT schema_name FROM information_schema.schemata"
        return self._execute(query)

    def _get_columns(self, schema_name: str, object_type: str) -> str:
        """Gets a list of columns in tables or views in a batch."""
        return (f"SELECT c.table_name, c.column_name, c.data_type, c.is_nullable "
                f"FROM information_schema.columns c "
                f"INNER JOIN information_schema.tables t "
                f"ON c.table_schema = t.table_schema AND c.table_name = t.table_name "
                f"WHERE c.table_schema = '{schema_name}' "
                f"AND t.table_type = '{object_type}'")

    def get_dataset(self, schema_name: str, entry_type: EntryType):
        """Gets data for a table or a view."""
        # Map EntryType to PostgreSQL table types
        type_mapping = {
            EntryType.TABLE: 'BASE TABLE',
            EntryType.VIEW: 'VIEW'
        }
        postgres_type = type_mapping[entry_type]
        query = self._get_columns(schema_name, postgres_type)
        return self._execute(query)

