"""Reads PostgreSQL using PySpark."""
from typing import Dict
from pyspark.sql import SparkSession, DataFrame

from src.constants import EntryType


SPARK_JAR_PATH = "src/postgresql-42.0.1-20170503.191129-22.jar"  # Updated PostgreSQL JDBC driver

class PostgreSQLConnector:
    """Reads data from PostgreSQL and returns Spark Dataframes."""

    def __init__(self, config: Dict[str, str]):
        # PySpark entrypoint
        self._spark = SparkSession.builder.appName("PostgreSQLIngestor") \
            .config("spark.jars", SPARK_JAR_PATH) \
            .getOrCreate()

        self._config = config
        # Updated JDBC URL format for PostgreSQL
        self._url = f"jdbc:postgresql://{config['host']}:{config['host_port']}/{config['database']}"

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

