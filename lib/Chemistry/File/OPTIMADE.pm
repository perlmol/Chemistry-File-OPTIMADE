package Chemistry::File::OPTIMADE;

# VERSION
# $Id$


use strict;
use warnings;

use base 'Chemistry::File';

use Chemistry::Mol;
use JSON;

=head1 NAME

Chemistry::File::OPTIMADE - OPTIMADE reader

=head1 SYNOPSIS

    use Chemistry::File::CML;

    # read a molecule
    my $mol = Chemistry::Mol->read('myfile.cml');

=cut

# Format is not registered, as OPTIMADE does not have proper file extension.
# .json is an option, but not sure if it will not clash with anything else.

=head1 DESCRIPTION

OPTIMADE structure representation reader.

=cut

sub parse_string {
    my ($self, $s, %opts) = @_;

    my $mol_class  = $opts{mol_class}  || 'Chemistry::Mol';
    my $atom_class = $opts{atom_class} || $mol_class->atom_class;
    my $bond_class = $opts{bond_class} || $mol_class->bond_class;

    my $json = decode_json $s;

    if( $json->{meta} &&
        $json->{meta}{api_version} &&
        $json->{meta}{api_version} =~ /^[^01]\./ ) {
        warn 'OPTIMADE API version ' . $json->{meta}{api_version} .
             ' encountered, this module supports versions 0 and 1, ' .
             'later versions may not work as expected';
    }

    return () unless $json->{data};

    my @molecule_descriptions;
    if(      ref $json->{data} eq 'HASH' && $json->{data}{attributes} ) {
        @molecule_descriptions = ( $json->{data} );
    } elsif( ref $json->{data} eq 'ARRAY' ) {
        @molecule_descriptions = @{$json->{data}};
    } else {
        return ();
    }

    my @molecules;
    for my $description (@molecule_descriptions) {
        my $mol = $mol_class->new( name => $description->{id} );

        # FIXME: For now we are taking the first chemical symol.
        # PerlMol is not capable to represent mixture sites.
        my %species = map { $_->{name} => $_->{chemical_symbols}[0] }
                          @{$description->{attributes}{species}};
        for my $site (0..$#{$description->{attributes}{cartesian_site_positions}}) {
            my $atom = $mol->new_atom( coords => $description->{attributes}{cartesian_site_positions}[$site],
                                       symbol => $species{$description->{attributes}{species_at_sites}[$site]} );
        }
        push @molecules, $mol;
    }
    return @molecules;
}

1;

=head1 SOURCE CODE REPOSITORY

L<https://github.com/perlmol/Chemistry-File-OPTIMADE>

=head1 SEE ALSO

L<Chemistry::Mol>

=head1 AUTHOR

Andrius Merkys <merkys@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2022 Andrius Merkys. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut
