#!/usr/bin/env perl

# mov-exif -- filename から exif データを修正する
# movファイルのファイル名をベースにexifデータを編集

use strict;
use warnings;
use utf8;
use feature qw/say/;
use Getopt::Std;
use File::Path qw(make_path);

use Image::ExifTool qw(:Public);
my $exif = Image::ExifTool->new();
my $EXIF_OPTIONS = {
                    LargeFileSupport => 1,
                   };

my $FILENAME_REGEXP : Constant(qr/^.*(\d{4}).*?(\d{2}).*?(\d{2}).*?(\d{2}).*?(\d{2}).*?(\d{2}).*\.mov$/);

sub usage {
  my $mes = shift;

  say '';
  say "## $mes";
  say '';
  say ' Convert from *.mov in srcdir or srcfiles to dstdir.';
  say '';
  say "Usage: $0 [options] (srcdir|srcfile) ... dstdir";
  say "options:";
  say "  -f\tforce overwrite if exists destination files";
  say "  -e\teach destinations saves to each other destination directories";
  say "    \t(default:save to same directory)";
  say '';
  say "filename format:";
  say "  $FILENAME_REGEXP";
  say '   year / month / day / hour / minute / second';
}

my %opts;
getopts('fe', \%opts);

my @src = @ARGV;
my $dstdir = pop @src;

unless (@src and $dstdir) {
  usage("Need both src and dstdir");
  die;
}

# print Dumper(\%opts);

foreach my $src (@src) {
  if (-d $src) {
    walkthrough($src, $dstdir);
  } elsif (-f $src) {
    convert($src, $dstdir);
  } else {
    say "## Cannot found src [$src]\n";
  }
}

sub walkthrough {
  my $srcdir = shift;
  my $dstdir = shift;

  if (opendir my $df, $srcdir) {
    foreach my $ss (readdir $df) {
      next if ($ss =~ /^\./);
      my $src = "$srcdir/$ss";
      if (-d $src) {
        walkthrough($src, "$dstdir/$ss");
      } elsif (-f $src) {
        convert($src, $dstdir);
      }
    }
  } else {
    say "## Cannot open dir [$srcdir]\n";
  }
}

sub convert {
  my $srcfile = shift;
  my $dstdir = shift;

  my $force = '';
  (my $filename = $srcfile) =~ s[^(.*/)][];
  if (-f "$dstdir/$filename") {
    if ($opts{f}) {
      $force = 'FORCE ';
      unlink "$dstdir/$filename";
    } else {
      say ":: skip(exists): $srcfile\n";
      return;
    }
  }
  if ($srcfile =~ $FILENAME_REGEXP) {
    my @date = ($1,$2,$3,$4,$5,$6);
    my $date = sprintf "%04d:%02d:%02d %02d:%02d:%02d+0900", @date;
    say "${force}convert: [$date] $srcfile";

    if ($exif->ExtractInfo($srcfile, $EXIF_OPTIONS)) {
      my @dateTags = grep !/^file/i, grep /date$/i, $exif->GetTagList();
      foreach my $tag (@dateTags) {
        $exif->SetNewValue($tag, $date);
      }
      if (make_path($dstdir) > 0) {
        say "directory: [$dstdir] created.";
      }
      $exif->WriteInfo($srcfile, "$dstdir/$filename");
      say "  saved --> $dstdir/$filename";
    } else {
      say "## Cannot get exif info [$srcfile]";
    }
  } else {
    say ":: skip(not target): $srcfile";
  }
}
