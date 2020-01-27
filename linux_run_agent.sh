#!/bin/bash

# run the agent in its own shell so we do not block this extension
echo running build agent
bash /agent/run.sh

echo done
