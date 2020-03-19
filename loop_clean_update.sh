#!/bin/bash
COUNTER=20
until [  $COUNTER -lt 10 ]; do
    echo -------- ATTEMPTS LEFT: $COUNTER ------
    let COUNTER-=1
    b clean update
done
