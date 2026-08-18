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

use Test::More tests => 3;
use Test::NoWarnings;

use Koha::Plugin::Com::ByWaterSolutions::EdifactEnhanced::Edifact;

my $class = 'Koha::Plugin::Com::ByWaterSolutions::EdifactEnhanced::Edifact';

# Everything after the service string advice, so each test can vary only the
# UNA. Built inline in the same style as t/Message.t.
my $interchange = join q{},
    q{'UNB+UNOA:4+1697684:31B+3010805:ZZ+260616:0252+662215},
    q{'UNH+3755+INVOIC:D:96A:UN},
    q{'BGM+380+B7249539+43},
    q{'DTM+137:20260615:102},
    q{'NAD+BY+3010805::31B},
    q{'UNS+S},
    q{'ALC+C++6++C&P},
    q{'MOA+8:397.5},
    q{'UNT+8+3755},
    q{'UNZ+1+662215'};

sub _message_count {
    my ($una) = @_;
    my $edi = $class->new( { transmission => $una . $interchange } );
    return scalar @{ $edi->message_array };
}

subtest 'service_string_advice accepts both syntax versions' => sub {
    plan tests => 4;

    my $ssa = \&Koha::Plugin::Com::ByWaterSolutions::EdifactEnhanced::Edifact::service_string_advice;

    ok( $ssa->(q{:+.? '}), 'syntax version 3 defaults, reserved space in position five' );

    # Position five is the repetition separator from syntax version 4 on, where
    # the default is an asterisk. Brodart send this.
    ok( $ssa->(q{:+.?*'}), 'syntax version 4 defaults, asterisk repetition separator' );

    # We never split on the repetition separator, so whatever is declared there
    # is none of our business
    ok( $ssa->(q{:+.?~'}), 'any repetition separator accepted' );

    # A separator we genuinely cannot parse still has to be refused
    my $rejected;
    {
        local $SIG{__WARN__} = sub { };
        $rejected = $ssa->(q{:+.?*~});
    }
    ok( !$rejected, 'a non-default segment terminator is still refused' );
};

subtest 'a syntax version 4 interchange parses' => sub {
    plan tests => 3;

    is( _message_count(q{UNA:+.? }), 1, 'syntax version 3 interchange parses' );

    # Before this was fixed the whole interchange was thrown away and every
    # invoice in the file was silently skipped
    is( _message_count(q{UNA:+.?*}), 1, 'syntax version 4 interchange parses' );

    my $refused;
    {
        local $SIG{__WARN__} = sub { };
        $refused = _message_count(q{UNA:+.?*~});
    }
    is( $refused, 0, 'an unparseable service string advice yields no messages' );
};
