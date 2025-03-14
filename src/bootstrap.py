"""The entrypoint of a pipeline."""
from typing import Dict

from src.constants import EntryType
from src import cmd_reader
from src import secret_manager
from src import entry_builder
from src import gcs_uploader
from src import top_entry_builder
from src.postgresql_connector import PostgreSQLConnector


FILENAME = "output.jsonl"


def write_jsonl(output_file, json_strings):
    """Writes a list of string to the file in JSONL format."""
    for string in json_strings:
        output_file.write(string + "\n")


def process_dataset(
    connector: PostgreSQLConnector,
    config: Dict[str, str],
    schema_name: str,
    entry_type: EntryType,
):
    """Builds dataset and converts it to jsonl."""
    df_raw = connector.get_dataset(schema_name, entry_type)
    df = entry_builder.build_dataset(config, df_raw, schema_name, entry_type)
    return df.toJSON().collect()


def run():
    """Runs a pipeline."""
    config = cmd_reader.read_args()
    config["password"] = secret_manager.get_password(config["target_project_id"], config["password_secret"])
    connector = PostgreSQLConnector(config)

    with open(FILENAME, "w", encoding="utf-8") as file:
        # Write top entries
        top_entries = [
            top_entry_builder.create(config, EntryType.INSTANCE),
            top_entry_builder.create(config, EntryType.DATABASE)
        ]
        file.write("\n".join(top_entries) + "\n")

        # Get schemas
        df_raw_schemas = connector.get_db_schemas()
        schemas = [row.schema_name for row in df_raw_schemas.collect()]  # Changed USERNAME to schema_name
        schemas_json = entry_builder.build_schemas(config, df_raw_schemas).toJSON().collect()
        write_jsonl(file, schemas_json)

        # Process tables and views
        for schema in schemas:
            print(f"Processing tables for {schema}")
            tables_json = process_dataset(connector, config, schema, EntryType.TABLE)
            write_jsonl(file, tables_json)

            print(f"Processing views for {schema}")
            views_json = process_dataset(connector, config, schema, EntryType.VIEW)
            write_jsonl(file, views_json)

    gcs_uploader.upload(config, FILENAME)