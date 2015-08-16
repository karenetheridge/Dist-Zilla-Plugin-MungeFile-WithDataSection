use strict;
use warnings;
package Dist::Zilla::Plugin::MungeFile::WithDataSection;
# ABSTRACT: Modify files in the build, with templates and DATA section
# KEYWORDS: plugin file content injection modification template DATA __DATA__ section
# vim: set ts=8 sts=4 sw=4 tw=115 et :

our $VERSION = '0.009';

use Moose;
extends 'Dist::Zilla::Plugin::MungeFile';
use namespace::autoclean;

# around dump_config => sub ...  no additional configs to add

sub munge_file
{
    my ($self, $file) = @_;

    my $content = $file->content;

    my $end_pos = $content =~ m/\n__END__\n/g && pos($content);
    pos($content) = undef;

    my $data;
    if ($content =~ m/\n__DATA__\n/spg and (not $end_pos or pos($content) < $end_pos))
    {
        $data = ${^POSTMATCH};
        $data =~ s/\n__END__\n.*$/\n/s;
    }

    $self->next::method(
        $file,
        { DATA => \$data },
    );
}

__PACKAGE__->meta->make_immutable;
__END__

=pod

=head1 SYNOPSIS

In your F<dist.ini>:

    [MungeFile::WithDataSection]
    file = lib/My/Module.pm
    house = maison

And during the build, F<lib/My/Module.pm>:

    my @stuff = qw(
        {{
            join "    \n",
            map { expensive_build_time_sub($_) }
            split(' ', $DATA)   # awk-style whitespace splitting
        }}
    );
    my ${{ $house }} = 'my castle';
    __DATA__
    alpha
    beta
    gamma

Is transformed to:

    my @stuff = qw(
        SOMETHING_WITH_ALPHA
        SOMETHING_WITH_BETA
        SOMETHING_WITH_GAMMA
    );
    my $maison = 'my castle';

=head1 DESCRIPTION

=for stopwords FileMunger

This is a L<FileMunger|Dist::Zilla::Role::FileMunger> plugin for
L<Dist::Zilla> that passes a file(s)
through a L<Text::Template>, with a variable provided that contains the
content from the file's C<__DATA__> section.

L<Text::Template> is used to transform the file by making the C<< $DATA >>
variable available to all code blocks within C<< {{ }} >> sections.

The data section is extracted by scanning the file for C<< qr/^__DATA__$/ >>,
so this may pose a problem for you if you include this string in a here-doc or
some other construct.  However, this method means we do not have to load the
file before applying the template, which makes it much easier to construct
your templates in F<.pm> files (i.e. not having to put C<{{> after a comment
and inside a C<do> block, as was previously required).

The L<Dist::Zilla> object (as C<$dist>) and this plugin (as C<$plugin>) are
also made available to the template, for extracting other information about
the build.

Additionally, any extra keys and values you pass to the plugin are passed
along in variables named for each key.

=for Pod::Coverage munge_files munge_file mvp_aliases

=head1 OPTIONS

=head2 C<finder>

=for stopwords FileFinder

This is the name of a L<FileFinder|Dist::Zilla::Role::FileFinder> for finding
files to modify.

Other pre-defined finders are listed in
L<Dist::Zilla::Role::FileFinderUser/default_finders>.
You can define your own with the
L<[FileFinder::ByName]|Dist::Zilla::Plugin::FileFinder::ByName> plugin.

There is no default.

=head2 C<file>

Indicates the filename in the dist to be operated upon; this file can exist on
disk, or have been generated by some other plugin.  Can be included more than once.

B<At least one of the C<finder> or C<file> options is required.>

=head2 C<arbitrary option>

All other keys/values provided will be passed to the template as is.

=head1 BACKGROUND

=for stopwords syntactual templater

This module was originally a part of the L<Acme::CPANAuthors::Nonhuman>
distribution, used to transform a C<DATA> section containing a list of PAUSE
ids to their corresponding names, as well as embedded HTML with everyone's
avatar images.  It used to only work on F<.pm> files, by first loading the
module and then reading from a filehandle created from C<< \*{"$pkg\::DATA"} >>.
This also required the file to jump through some convoluted syntactual hoops
to ensure that the file was still compilable B<before> the template was run.
(Check it out and roll your eyes:
L<https://github.com/karenetheridge/Acme-CPANAuthors-Nonhuman/blob/v0.005/lib/Acme/CPANAuthors/Nonhuman.pm#L18>)

Now that we support munging all file types, we are forced to parse the file
more dumbly (by scanning for C<qr/^__DATA__/>), which also removes the need
for these silly syntax games. The moral of the story is that simple code
usually B<is> better!

I have also since split off much of this distribution into a superclass
plugin, L<Dist::Zilla::Plugin::MungeFile>, which provides a general-use munger
and templater without the C<__DATA__> support.

=head1 SUPPORT

=for stopwords irc

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-MungeFile::WithDataSection>
(or L<bug-Dist-Zilla-Plugin-MungeFile::WithDataSection@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-MungeFile::WithDataSection@rt.cpan.org>).
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 SEE ALSO

=for :list
* L<Dist::Zilla::Plugin::Substitute>
* L<Dist::Zilla::Plugin::GatherDir::Template>
* L<Dist::Zilla::Plugin::MungeFile>
* L<Dist::Zilla::Plugin::MungeFile::WithConfigFile>

=cut
