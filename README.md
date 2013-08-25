# mit-jap-scraper

Scraper of [MIT Japanese course website](http://web.mit.edu/21f.500/www/). 

## Dependencies
run `bundle` to get and update all the necessary Ruby gems.

## How to run

```
./scrape.rb -u <url>
```

The `url` should point to a course lesson listing under "Online Resources" of a
course. For example, [MIT Japanese
502](http://web.mit.edu/21f.502/www/review.html).

This will parse the html file specified by the url and save an xml file with the course name in the
main folder and
creates an "assets" folder that stores all the xml files for the drills and the
audio and the image files.
