# movie-exif
Quicktime movie's ''create date'' (and other date field) in exif data sets from filename.

## INSTALL

These scripts are used Image::ExifTool module.
Install from cpan before using.

## USAGE

    $ movexif.pl \[options\] \(srcdir|srcfile\) ... dstdir
    $ mtsexif.pl \[options\] \(srcdir|srcfile\) ... dstdir

## OPTIONS:

    -f : force overwrite if exists destination files, otherwise skip convert.
    -e : each destinations saves to each other destination directories (default:save to same directory)

## DESCRIPTION

These scripts are intended to correct the exif data of the video data shooting date and time of.
For GooglePhoto did not recognize the correct shooting date and time of the video, we created these scripts.

'movexif.pl' is a script that adds 'CreateDate' in exif to the 'mov' format movie data as filename's date.

Typically for mov files created in OSX's imovie application.

'mtsexif.pl' is a script that converts from AVCHD Cam's movies that not have 'CreateDate' in exif movies.


### filename format for movexif.pl

```
(?^:^.*(\d{4}).*?(\d{2}).*?(\d{2}).*?(\d{2}).*?(\d{2}).*?(\d{2}).*\.mov$)
```

year / month / day / hour / minute / second

