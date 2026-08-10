"""Offline smoke tests that do not require Databricks Connect."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_databricks_bundle_config_exists():
    assert (ROOT / "databricks.yml").is_file()


def test_bakehouse_pipeline_resources_exist():
    assert (ROOT / "resources" / "bakehouse.pipeline.yml").is_file()
    assert (ROOT / "src" / "pipelines" / "bakehouse").is_dir()
