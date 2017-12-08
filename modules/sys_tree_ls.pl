#!/usr/bin/perl
## File: sys_tree_ls.pl
## Version: 1.0
## Date 2017-12-08
## License: GNU GPL v3 or greater
## Copyright (C) 2017 Harald Hope
##
## Path::Class NOT in standard core modules!!
## https://stackoverflow.com/questions/10606685/display-directory-tree-output-like-tree-command

use strict;
use warnings;
use 5.008;
use Path::Class;

my $dir = Path::Class::Dir->new('/sys');

my $max_depth = $dir->traverse(sub {
  my ($child, $cont, $depth) = @_;
  return max($cont->($depth + 1), $depth);
}, 0);

sub max { my $max = 0; for (@_) { $max = $_ if $_ > $max } $max };

my @output = ( sprintf("%-43s|%s", " Name", " mtime"),
               sprintf("%-43s|%s", '-' x 43, '-' x 11) );

my @tree = (0, 0);
my $last_indent = 0;

$dir->traverse( sub {
  my ($child, $cont, $indent) = @_;
  my $child_basename = $child->basename;
  my $child_stat     = $child->stat();
  my $child_mtime    = $child_stat->[9];

  $indent = 1 if (!defined $indent);
  my $width = 40 - 3 * ($indent - 1);

  if ($last_indent != $indent) {
    if ($last_indent > ($indent + 1)) {
      for my $level (($indent + 1)..($last_indent - 1)) {
        $output[$#output - $_] = 
          substr($output[$#output - $_], 0, 3 * ($level - 1)) . ' ' .
          substr($output[$#output - $_], 3 * ($level - 1) + 1, 65535) 
            for (0..$tree[$level] - 1);
      }
      delete $tree[$_] for $indent..$last_indent;
    }
    $tree[$indent] = 0;
    $last_indent = $indent;
  }

  if ($child->is_dir) {
    push @output, sprintf("%s+- %-${width}s| %d",
      ('|  ' x ($indent - 1)), $child_basename . '/', $child_mtime);
    $tree[$indent] = 0;
  }
  else {
    push @output, sprintf("%s%s- %-${width}s| %d", ('|  ' x ($indent - 1)),
      ($child eq ($child->dir->children)[-1] ? '\\' : '|' ),
      $child_basename, $child_mtime);
    $tree[$indent]++;
  }
  $tree[$_]++ for (1..$indent - 1);

  $cont->($indent + 1);
});

for my $level (1..$last_indent - 1) {
  $output[$#output - $_] = 
    substr($output[$#output - $_], 0, 3 * ($level - 1)) . ' ' .
    substr($output[$#output - $_], 3 * ($level - 1) + 1, 65535)
      for (0..$tree[$level] - 1);
}

print "$_\n" for @output;
