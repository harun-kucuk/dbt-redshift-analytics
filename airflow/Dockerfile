FROM apache/airflow:2.10.4-python3.11

USER airflow

# Install cosmos + Amazon provider into Airflow's Python env
COPY requirements.txt /requirements.txt
RUN pip install --no-cache-dir -r /requirements.txt

# Create the dbt venv using virtualenv (NOT python -m venv).
# cosmos uses the virtualenv package internally to manage this venv;
# if it was created with python -m venv the metadata files it expects
# don't exist and it fails. Using python -m virtualenv creates them correctly.
RUN python -m virtualenv /opt/airflow/dbt-venv && \
    /opt/airflow/dbt-venv/bin/pip install --upgrade pip wheel setuptools && \
    /opt/airflow/dbt-venv/bin/pip install --no-cache-dir dbt-redshift==1.10.1
