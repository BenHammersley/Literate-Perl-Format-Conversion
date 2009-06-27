#!/usr/bin/perl

=begin lip

=head1 NAME

Publish and Be Damned

=head1 SYNOPSIS

Takes a fully POD'd Perl script, tidies it, checks it, formats it, and outputs it into various formats. 

=head1 DESCRIPTION

As a writer and developer, I spend a lot of time creating scripts to go into books or onto websites. These scripts need not only to be completely documented, but to be exceptionally easy to follow. After all, there primary purpose isn't to work themselves, but to show the reader how they work.

Furthermore, much of the drudge work of writing technical books comes not from the hacking - which is the fun bit - but from the writing up of the scripts, and the fitting into the publisher's specific Word template or style.

So, this script aims to take a lot of the pain away. It fosters a pseudo-Literate Programming style that allows me to document the script as I write it, it checks the script to make sure it compiles (one final check is always good), it checks that the entire thing is documented, it - optionally - checks the coverage of Unit Tests, it tidies the scripts, and finally it reformats them into the necessary format, choosing between HTML and OpenOffice.org Writer format.

Note that this is not by any means a noweb style Literate Programming system. It's far far simpler than that, and written around my own personal coding and writing style.

=head1 AUTHOR

Ben Hammersley <ben@benhammersley.com>

=head1 USAGE

perl pbd.pl -file= -strip -html

i.e.

perl pdb.pl -file=pbd.pl -html -strip

=head1 TODOs

#TODO Convert to command line app, ie perltidy
#TODO Add in OpenOffice.org writer export
#TODO Add in Pod::Coverage tests

=head1 COPYRIGHT

Copyright 2004 Ben Hammersley. All Rights Reserved.
This program is free software. You may copy or redistribute it under the same terms as Perl itself.

=cut

=head2 Starting the Script

We start by loading up the modules we want. In this case, there are a whole raft of Pod related modules. We'll deal with each of them later on.

We also bring in the parameters we're passing to the script from the command line. We have two parameters that take filenames, and two flags. C<file> is the path to the Perl script. C<append_to> is the path to the OpenOffice.org Writer document we wish to add this script to the bottom of. This is optional, as the C<standalone> flag tells the system to eschew that in favour of creating a standalone document. Finally, C<html> will cause the system to create an HTML output instead.

=cut

use strict;
use warnings;
use Getopt::Long;

my ($incoming_file, $append_to_file, $strip, $html);

GetOptions ("file=s" => \$incoming_file,
            "strip" => \$strip,
            "html" => \$html );

=head2 Controlling the program

This is the core of the program. First we run through a compilation test and a coverage test. From then on, all of the routines require an actual file to work on. We don't want to work on the file we're working on (if you see what I mean) so we make a temporary copy of it, and work with that.

We can then tidy it up, parse it into proper POD from the Literate POD we're using, and then output it in the various formats we want depending on the options set.

It is into this section that we add further calls to functions whenever we want to expand this program.

=cut

compile_test($incoming_file);
coverage_test($incoming_file);

my $tidy_file = tidy_script($incoming_file);
my $parsed_lip_file = parse_lip($tidy_file);


if ($html) { create_html($parsed_lip_file);}
if ($strip) { create_stripped_code($tidy_file);}


print "\n\nThat's it. We're done.\n \n";

=head2 The Functions

Below here be dragons

=cut

=item compile_test() 

Before we get into the dirty business of filtering the script and its Pod, it's probably best to check that the script actually works. Without running a whole test suite, we can't do much but see if it compiles. That's what we do here. If the script doesn't compile correctly, we really don't want to go any further, so we C<die> with displaying the error

=cut

sub compile_test {
my $eval_result = eval (`perl -c $_[0]`);
if ($@) { die "There's a problem with $_[0] \n $@ \n";}
return 1;
}

=item coverage_test()

Not yet implemented, this will use Pod::Coverage to check the documentation is complete.

=cut

sub coverage_test {
print "Coverage test: NOT IMPLEMENTED \n";
return;
}


=item tidy_script()

The C<tidy_script> subroutine fires up the Perl::Tidy module, and passes the script through it. Again, this could be expanded to include fancier formatting options. But we'll keep it simple for the moment.

The filename is passed to the function, which opens it, tidies it, and saves it to disk with .tidy appended to the name. Perl Tidy needs this name change or it won't work. This is ok with us, actually, as we would quite like the Tidied file saved for the --standalone mode.

=cut

sub tidy_script {
use Perl::Tidy;
print "\nRunning Perl Tidy on $_[0] \n";

perltidy ( source => $_[0], 
            destination => "$_[0].tidy"
            );

print "The Tidy version is $_[0].tidy\n";
return("$_[0].tidy");                        
}

=item parse_lip()

I'm writing these scripts in the pseudo-Literate Programming format dictated by the Lip::Pod module. This allows me to incorporate the entire source code inside the POD, which is exactly what I want to do for the sort of documentation I need to produce. This function turns the script into entirely POD format, which we can then go on and convert to the output formats with the pod2* functions.

Lip::Pod is built on top of Pod::Parser, which can't take a scalar as an input. It much prefers filehandles, which it parses line-by-line, as it uses the line numbers for diagnostics. So we point it at the temp file, parse it to another temp file, and then do the delete'n'rename tango to leave us with only one temp file. This will now be entirely POD, and ready for the convertion into other formats.

=cut

sub parse_lip {
use Lip::Pod;
print "\nRunning the Lip::Pod parser on $_[0] \n";
my $lip_parser = new Lip::Pod;
$lip_parser->parseopts( -want_nonPODs => 1,
                        -process_cut_cmd => 1);
                        
$lip_parser->parse_from_file($_[0],"$_[0].lip") or die "Lip::Pod error: $! \n";

print "The Lip::Pod parsed file is $_[0].lip \n";
return("$_[0].lip");
}

=item create_html()

This is an optional filter, turning the Pod file into HTML using Pod::Html. It creates the HTML, then cleans up its own tmp files. 

=cut

sub create_html {
use Pod::Html;
print "\nCreating HTML version of $_[0] \n";
pod2html(   "--infile=$_[0]",
            "--title=$_[0]",
            "--outfile=$incoming_file.html");
            
unlink("pod2htmd.tmp");
unlink("pod2htmi.tmp");      
print "The HTML version is $incoming_file.html \n";      
return("$incoming_file.html");
}

=item create_stripped_code ()

This is an optional filter to strip out all of the Pod, leaving only code. It uses Pod::Stripper, which is another subclass of Pod::Parser

=cut

sub create_stripped_code {
use Pod::Stripper;
print "\nCreating Stripped version of $_[0] \n";
my $pod_stripper = new Pod::Stripper();
$pod_stripper->parse_from_file($_[0], "$_[0].stripped") or die "Pod::Stripper error $! \n";

print "The Stripped Code is $_[0].stripped \n";
return("$_[0].stripped");
}

=end lip

=cut
