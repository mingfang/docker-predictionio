docker-predictionio
===================

Run [PredictionIO](http://prediction.io) inside Docker

1. Run ```build``` to build the image
2. Run ```shell``` to start the container
3. Once inside the container, run ```runsvdir-start&``` to start everything
4. The Dashboard is available on port 9000

Run [quickstart](http://docs.prediction.io/templates/recommendation/quickstart/)

1. Go to quickstartapp directory ```cd /quickstartapp```
2. Build and Train Engine ```./run.sh```
3. Deploy Engine ```cd MyRecommendation && pio deploy --ip 0.0.0.0&```
4. Your Engine will now listen on port 8000

Run [Multiple Engines]()

1. On deployment of the second Engine, run ```pio deploy --ip 0.0.0.0 --port 8001 &```
2. For additional engines, use 8001-8006
