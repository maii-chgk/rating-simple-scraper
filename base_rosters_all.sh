#!/bin/bash
source "/usr/share/rvm/bin/rvm"
cd /home/deploy/rating-simple-scraper/
rvm use 3.0.2
bundle exec ruby base_rosters_all.rb
