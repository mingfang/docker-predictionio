#!/bin/sh

echo "Making sure EventServer is running..."
while ! nc -vz localhost 7070;do sleep 3; done

echo "Creating MyRecommendation..."
cp -r $PIO_HOME/templates/scala-parallel-recommendation MyRecommendation
cd MyRecommendation
pio app new MyApp1 > log.txt
KEY=$(grep "Access Key:" log.txt | awk '{print $8}')
echo "KEY=$KEY"

echo "Importing sample data..."
curl https://raw.githubusercontent.com/apache/spark/master/data/mllib/sample_movielens_data.txt --create-dirs -o data/sample_movielens_data.txt
python data/import_eventserver.py --access_key $KEY

echo "Building...  It may take some time to download all the librariesi."
pio build

echo "Taining..."
pio train

echo "You may now deploy engine by running cd /quickstartapp/MyRecommendation && pio deploy --ip 0.0.0.0"
