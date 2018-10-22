# Stage 1: build sbt and its dependencies
FROM local/scala-base AS dependencies

WORKDIR /databricks
COPY project/build.properties ./project/build.properties
COPY project/plugins.sbt ./project/plugins.sbt
COPY build.sbt .
RUN sbt update

# Stage 2: build the application jar file
FROM local/scala-base AS builder

COPY --from=dependencies /root/.ivy2 /root/.ivy2
COPY --from=dependencies /root/.sbt /root/.sbt

RUN apt-get update \
    && apt-get install -y \
        dos2unix \
        shellcheck

WORKDIR /databricks
COPY project/build.properties ./project/build.properties
COPY project/plugins.sbt ./project/plugins.sbt
COPY build.sbt .
COPY src/main/scala ./src/main/scala
RUN sbt assembly

COPY src/test/scala ./src/test/scala
COPY scalastyle-config.xml .

COPY src/main/notebooks /databricks/src/main/notebooks
COPY src/main/scripts /databricks/src/main/scripts
RUN dos2unix /databricks/build.sbt $(find /databricks/src/main/scripts -type f)

ENTRYPOINT ["bash", "-c"]

# Stage 3: deploy the spark job to databricks
FROM python:2.7-slim AS deploy

RUN apt-get update \
    && apt-get install -y \
        jq

RUN pip install --no-cache-dir databricks-cli

COPY --from=builder /databricks /databricks

WORKDIR /databricks/src/main/scripts

ENTRYPOINT ["./deploy.sh", "staging"]
