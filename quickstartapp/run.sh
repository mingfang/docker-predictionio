#!/bin/sh

while ! nc -vz localhost 7070;do sleep 1; done

set PIO_HOME=/PredictionIo

cd /quickstartapp
python import.py
${PIO_HOME}/bin/pio instance io.prediction.engines.itemrank
cd io.prediction.engines.itemrank
${PIO_HOME}/bin/pio register
${PIO_HOME}/bin/pio train
${PIO_HOME}/bin/pio deploy

