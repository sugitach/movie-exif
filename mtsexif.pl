#!/usr/bin/env perl

# mts-exif --- MTS ファイルを MOV に変換し、exifデータに正しい撮影日付を記録

use strict;
use warnings;
use utf8;
use feature qw/say/;
use Getopt::Std;
use File::Path qw(make_path);
use File::Temp qw(tempfile);

use Image::ExifTool qw(:Public);

my $exif = Image::ExifTool->new();
my $EXIF_OPTIONS = {
                    LargeFileSupport => 1,
                   };
my $FILENAME_REGEXP = qr/\.mts$/i;
my $DST_EXT = '.mp4';
my @ffmpeg = qw/ffmpeg -y -v 0 -i {SRC} -vcodec copy -acodec copy {DST}/;

sub usage {
  my $mes = shift;

  say '';
  say "## $mes";
  say '';
  say 'Convert from *.mts in srcdir or srcfiles to dstdir.';
  say '';
  say "Usage: $0 [options] (srcdir|srcfile) ... dstdir";
  say "options:";
  say "  -f\tforce overwrite if exists destination files";
  say "  -e\teach destinations saves to each other destination directories";
  say "    \t(default:save to same directory)";
}

my %opts;
getopts('fe', \%opts);

my @src = @ARGV;
my $dstdir = pop @src;

unless (@src and $dstdir) {
  usage("Need both src and dstdir");
  die;
}

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
  if ($srcfile =~ /$FILENAME_REGEXP/) {

    # $srcfile から exif情報を取得
    $exif->ExtractInfo($srcfile, $EXIF_OPTIONS) ;
    my $date;
    my %exifdata;
    foreach my $tag (grep !/file/i, $exif->GetTagList()) {
      if ($tag =~ /date$/i or $tag =~ /^datetimeoriginal$/i) {
        my $d;
        $d = $exif->GetValue($tag);
        no warnings 'numeric';
        if ($d > 0) {
          $date = $d;
          last;
        }
      }
      my $v = $exif->GetValue($tag);
      $exifdata{$tag} = $v if ($v and $v !~ /0000:00:00/);
    }
    unless ($date) {
      warn "ERROR : no datetime [$srcfile]\n";
      return;
    }

    my $dstfile = $date;
    $dstfile =~ s/\+09:00$//;
    $dstfile =~ tr/: /-_/;
    $dstfile = "$dstdir/$dstfile$DST_EXT";

    if (-f "$dstfile") {
      if ($opts{f}) {
        $force = 'FORCE ';
        unlink "$dstfile";
      } else {
        say ":: skip(exists): $srcfile\n";
        return;
      }
    }
    say "${force}convert: $srcfile => $dstfile";

    if (make_path($dstdir) > 0) {
      say "directory: [$dstdir] created.";
    }
    # # 中間ファイル
    mkdir "$ENV{HOME}/tmp";
    my ($fh, $temp) = tempfile('mtsexifXXXX', DIR=>"$ENV{HOME}/tmp", SUFFIX=>$DST_EXT, UNLINK=>1);

    # mts から mov へ変換
    my @cmd = map {
      if ($_ eq '{SRC}') {
        $srcfile;
      } elsif ($_ eq '{DST}') {
        $temp;
      } else {
        $_;
      }
    } @ffmpeg;
    say join ' ', @cmd;
    system(@cmd);
    # exif情報をコピー
    while (my ($tag, $val) = each %exifdata) {
      $exif->SetNewValue($tag, $val);
    }
    $exif->SetNewValue('CreateDate', $date) unless (exists $exifdata{createdate});
    $exif->WriteInfo($temp, $dstfile);
  }
}
