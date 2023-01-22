#!/bin/bash
elm make --optimize src/Vote.elm --output ../static/js/vote.elm.js
elm make --optimize src/Results.elm --output ../static/js/results.elm.js
