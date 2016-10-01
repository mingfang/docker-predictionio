#!/bin/bash
set -e

if [ ! -f /.dockerenv ]; then
  echo "*** NOTICE: Make sure you're running this from inside the Docker container! ***"
  exit 1
fi


echo "Step 1: Making sure everything is running"
sv start /etc/service/*

echo "EventServer may take a minute to start. Checking every 5s..."
while ! nc -vz localhost 7070;do sleep 5; done

pio status
echo "Step 1: Passed"


echo "Step 2. Create a new Engine from an Engine Template"

echo "n" | pio template get apache/incubator-predictionio-template-recommender MyRecommendation --name "none" --package "none" --email "none"
cd MyRecommendation

echo "Step 2: Passed"


echo "Step 3. Generate an App ID and Access Key"

#echo "YES" | pio app delete MyApp1
pio app new MyApp1 > log.txt
KEY=$(grep "Access Key:" log.txt | awk '{print $5}')
echo "KEY=$KEY"

pio app list
echo "Step 3: Passed"

echo "Step 4 Import Sample Data"

curl https://raw.githubusercontent.com/apache/spark/master/data/mllib/sample_movielens_data.txt --create-dirs -o data/sample_movielens_data.txt
python data/import_eventserver.py --access_key $KEY


echo "Step 5. Deploy the Engine as a Service"
sed -i "s|INVALID_APP_NAME|MyApp1|" /quickstartapp/MyRecommendation/engine.json

echo "Building...  It may take some time to download all the libraries."
pio build --verbose

echo "Taining..."
pio train -- --driver-memory 4G

echo "You may now deploy engine by running cd /quickstartapp/MyRecommendation && pio deploy --ip 0.0.0.0"
