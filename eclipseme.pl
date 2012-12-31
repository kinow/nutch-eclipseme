#!/usr/bin/perl 
#
# Bruno P. Kinoshita <brunodepaulak at yahoo dot com dot 
# br dot nospam_excludeme> - 31/12/2012
# 
# OH NOES! I lost my old workspace... Nutch, srly, do I have to add all the 
# plug-in src folders again? Argh! Noes!
#
# Just kidding, soon I believe it will be automated with Maven or in some other 
# way. In the meantime, feel free to use this script to update your project 
# .classpath with all the plug-ins source folders.
#
# This script scans src/plugins and, for each plugin folder, it looks for 
# src/java or src/test. If present, then it creates a hash and later updates 
# the .classpath file accordingly.

use warnings;
use strict;
use feature 'say';
use feature ':5.14';

use XML::Simple;
use Data::Dumper;

# XML parsing from: 
# http://www.techrepublic.com/article/parsing-xml-documents-with-perls-xmlsimple/5363190
# 

# create object
my $xml = new XML::Simple(NoAttr=>0, RootName=>'classpath');

# read XML file
my $data = $xml->XMLin(".classpath");

# get the classpathentry entries
my @entries = $data->{classpathentry};

# create hash from plugins directory
my $plugins_dir = 'src/plugin';

# Perl trim function to remove whitespace from the start and end of the string
sub trim($) {
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}
# Left trim function to remove leading whitespace
sub ltrim($) {
    my $string = shift;
    $string =~ s/^\s+//;
    return $string;
}
# Right trim function to remove trailing whitespace
sub rtrim($) {
    my $string = shift;
    $string =~ s/\s+$//;
    return $string;
}

# Get the source (usually java and test) directories of a plug-in
sub get_src_directories($) {
    my @src_dirs;
    my $plugin_dir = $_[0];
    if (-d "$plugin_dir/src/java") {
        push(@src_dirs, "$plugin_dir/src/java");
    }
    if (-d "$plugin_dir/src/test") {
        push(@src_dirs, "$plugin_dir/src/test");
    }
    return @src_dirs;
};

my @new_entries = ();

opendir (DIR, $plugins_dir) or die $!;
while (my $file = readdir(DIR)) {
	# skip non-directories
	next unless (-d "$plugins_dir/$file");
	# skip this, parent and hidden files
	next if $file eq '.';
	next if $file eq '..';
	next if substr($file, 0, 1) eq '.';
	my @src_dirs = get_src_directories("$plugins_dir/$file");
	if (@src_dirs) {
	   push @new_entries, @src_dirs;
	}
}
closedir(DIR);

# for each new entry, add to the bunch of entries found in the XML, if not 
# present. This 'if not' increases the complexity of this script... but this 
# should still run fine and in less than 1 sec?

for my $new_entry (@new_entries) {
	my $found = 0;
	OUTER_LOOP:
	for my $entry (@entries) {
	    for my $hash (@{$entry}) {
	        if (trim($new_entry) eq trim($hash->{'path'})) {
	        	$found = 1;
	        	last OUTER_LOOP;
	        }
	    }
	}
	if(!$found) {
        my %temp = ('kind', 'src', 'path', $new_entry);
        push $entries[0], \%temp;
    }
}

my $result = $xml->XMLout($data, xmldecl => '<?xml version="1.0" encoding="UTF-8"?>');

# Write to the .classpath
open (CLASSPATH_FILE, ">.classpath");
print CLASSPATH_FILE $result;
close (CLASSPATH_FILE);

exit 0;

