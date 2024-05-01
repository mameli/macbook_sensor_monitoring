# RabbitIot
RabbitIot is an Elixir project that uses the powermetrics command to generate sensor data and send it to RabbitMQ. The project is designed to run in a Docker environment, with RabbitMQ and a PostgreSQL database running as Docker services.

## Usage

You have to install docker and docker-compose to run the project.
Also Elixir is required.

```bash
brew install elixir
mix deps.get
```

mix deps.get will install the dependencies listed in mix.exs.

```bash
docker-compose up
```

The docker-compose will start the RabbitMQ and the postgres database.

To initialize the database you have to run the following command:

```bash
mix ecto.create
mix ecto.migrate
```

To start the server you have to run the following command:

You need to create a .env file with the following content:

```bash
password=YOUR_SUDO_PASSWORD
```
This is required to run the powermetrics command.

There are three components in the project:
- GenSensorData: This component is responsible for generating the sensor data from powermetrics and sending it to the RabbitMQ.
- ReadSensorData: This component is responsible for reading the sensor data from the RabbitMQ and storing it in the database.
- ThrottlingDetector: This component is responsible for detecting the throttling events and storing them in the database.

You can start the components by running the following commands in different terminals:

```bash
iex -S mix run --no-halt -e "GenSensorsData.start_link"
iex -S mix run --no-halt -e "ReadSensorsData.start_link(\"CPU Power\")"
# or/and
iex -S mix run --no-halt -e "ReadSensorsData.start_link(\"GPU Power\")"

iex -S mix run --no-halt -e "ThrottlingDetector.start_link"
```