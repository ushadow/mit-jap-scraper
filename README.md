# mit-jap-scraper

Scraper of [MIT Japanese course website](http://web.mit.edu/21f.500/www/). 

## Dependencies
run `bundle` to get and update all the necessary Ruby gems.

## How to run

Download the html file of a course lesson listing under "Online Resources" of a
course. For example, [MIT Japanese
502](http://web.mit.edu/21f.502/www/review.html). In the main source folder, run

```
./exercise_writer.rb <path to the html file>
```

This will parse the html file and save an xml file with the course name in the
main folder and
creates an "assets" folder that stores all the xml files for the drills and the
audio and the image files.

There is already an example html file in the "input" folder, so you can test by
running
```
./exercise_writer.rb input/MIT_Japanese_502.html 
```
