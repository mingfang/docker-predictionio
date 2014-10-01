#!/bin/sh

while ! nc -vz localhost 7070;do sleep 1; done

set PIO_HOME=/PredictionIo

cd /quickstartapp
python import.py
/PredictionIo/bin/pio instance io.prediction.engines.itemrank
cd io.prediction.engines.itemrank
/PredictionIo/bin/pio register
/PredictionIo/bin/pio train
/PredictionIo/bin/pio deploy

