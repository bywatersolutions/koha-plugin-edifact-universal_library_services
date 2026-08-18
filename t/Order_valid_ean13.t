#!/usr/bin/perl

# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Koha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Koha; if not, see <http://www.gnu.org/licenses>.

use Modern::Perl;

use Test::More tests => 1;

use Koha::Plugin::Com::ByWaterSolutions::EdifactEnhanced::Edifact::Order;

my $valid = \&Koha::Plugin::Com::ByWaterSolutions::EdifactEnhanced::Edifact::Order::_valid_ean13;

subtest '_valid_ean13 replaces Business::Barcode::EAN13::valid_barcode' => sub {
    plan tests => 12;

    ok( $valid->('9780063158719'), 'a real bookland EAN validates' );
    ok( $valid->('5023965006028'), 'a real product EAN validates' );
    ok( $valid->('0000000000000'), 'all zeroes has a valid check digit' );
    ok( $valid->('1111111111116'), 'check digit six computed correctly' );

    ok( !$valid->('9780063158718'), 'a wrong check digit is refused' );
    ok( !$valid->('978006315871'),  'twelve digits is too short' );
    ok( !$valid->('97800631587190'), 'fourteen digits is too long' );
    ok( !$valid->('0063158719'),    'an ISBN-10 is not an EAN' );
    ok( !$valid->('006315871X'),    'an ISBN-10 with an X check digit is not an EAN' );
    ok( !$valid->('978-0-06-315871-9'), 'hyphens are not stripped' );
    ok( !$valid->(''),              'the empty string is refused' );
    ok( !$valid->(undef),           'undef is refused without warning' );
};
