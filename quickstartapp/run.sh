#!/bin/sh

while ! nc -vz localhost 7070;do sleep 1; done

set PIO_HOME=/PredictionIO

cd /quickstartapp
python import.py
/PredictionIO/bin/pio instance io.prediction.engines.itemrank
cd io.prediction.engines.itemrank
/PredictionIO/bin/pio register
/PredictionIO/bin/pio train
/PredictionIO/bin/pio deploy

