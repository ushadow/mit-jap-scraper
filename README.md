# mit-jap-scraper

Scraper of [MIT Japanese course website](http://web.mit.edu/21f.500/www/). 

## How to run

Download the html file of a course lesson listing under "Online Resources" of a
course. For example, [MIT Japanese
502](http://web.mit.edu/21f.502/www/review.html). In the main source folder, run

```
./exercise_writer.rb <path to the html file>
```

This will parse the html file and save an xml file with the course name in the
main folder and
creates an "asset" folder that stores all the xml files for the drills and the
audio and the image files.
