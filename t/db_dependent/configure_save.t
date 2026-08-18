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

use CGI;
use Test::More tests => 2;
use Test::NoWarnings;

use Koha::Database;
use Koha::Plugin::Com::ByWaterSolutions::EdifactEnhanced;

my $schema = Koha::Database->new->schema;

subtest 'a missing parameter must not shift the settings that follow it' => sub {
    plan tests => 3;
    $schema->storage->txn_begin;

    # CGI::param returns an empty list, not undef, for an absent parameter.
    # In the settings hash every entry has to force scalar context, or the
    # missing entry contributes nothing and every later key/value pair shifts
    # by one, storing settings under each other's names. This save leaves out
    # no_update_item_price on purpose.
    my $cgi = CGI->new(
        'save=1&set_nfl_on_receipt=7&pia_limit=10&invoice_adjustment_rules=[]&shipment_charge_filters=[]');
    my $plugin = Koha::Plugin::Com::ByWaterSolutions::EdifactEnhanced->new(
        { enable_plugins => 1, cgi => $cgi } );

    {
        # configure ends by printing a redirect, keep it out of the TAP stream
        local *STDOUT;
        open STDOUT, '>', '/dev/null' or die "Cannot reopen STDOUT: $!";
        $plugin->configure;
    }

    is( $plugin->retrieve_data('no_update_item_price'),
        'update_both', 'the missing parameter got its default' );
    is( $plugin->retrieve_data('set_nfl_on_receipt'),
        '7', 'the next setting kept its own value' );
    is( $plugin->retrieve_data('pia_limit'), '10', 'and so did the one after it' );

    $schema->storage->txn_rollback;
};
