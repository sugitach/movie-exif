# movie-exif
Quicktime movie's ''create date'' (and other date field) in exif data sets from filename.

## Usage
movexif.pl [options] (srcdir|srcfile) ... dstdir

## options:
-f : force overwrite if exists destination files

-e : each destinations saves to each other destination directories (default:save to same directory)

## filename format

```
(?^:^.*(\d{4}).*?(\d{2}).*?(\d{2}).*?(\d{2}).*?(\d{2}).*?(\d{2}).*\.mov$)
```

year / month / day / hour / minute / second
