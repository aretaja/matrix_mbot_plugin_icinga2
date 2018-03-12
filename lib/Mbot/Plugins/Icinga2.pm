package Mbot::Plugins::Icinga2;
use Monitoring::Icinga2::Client::REST;

our $VERSION = '0.2';

=head1 NAME

Mbot::Plugins::Icinga2 - Icinga2 related functionality

=head1 METHODS

=head2 parse - input parser

Reacts to messages beginning with 'icinga'.

    $result = parse($self->in);

=cut

sub parse
{
    my ($self, $in) = @_;

    if ($in->{msg} && $in->{msg} eq 'help')
    {
        my @out = (
            'icinga <command>',
            '  command:',
            '    status overview - responds with host/service overview',
            '    hosts down - responds with list of down hosts',
            '    host <hostname> - responds with detailed host status',
        );
        return join("\n", @out);
    }

    my @out;
    if ($in->{msg} && $in->{msg} =~ m/^icinga\s+(.*)/)
    {
        my $cmd      = $1;
        my $conf     = $in->{conf};
        my $user     = $conf->{ic2_user} || die('Icinga username missing');
        my $pass     = $conf->{ic2_pass} || die('Icinga password missing');
        my $api_host = $conf->{ic2_host} || 'localhost';
        my $params;
        $params->{port}     = $conf->{ic2_port}    || 5665;
        $params->{path}     = $conf->{ic2_path}    || '/';
        $params->{version}  = $conf->{ic2_version} || 1;
        $params->{insecure} = $conf->{ic2_insec}   || 1;
        $params->{cacert} = $conf->{ic2_cacert} if (conf->{ic2_cacert});

        my $icinga = new Monitoring::Icinga2::Client::REST($api_host, %$params);

        die("Login to icinga2 API failed - $icinga->login_status")
          unless ($icinga->login($user, $pass));

        # Returns status summary
        if ($cmd =~ m/^status\s+overview/)
        {
            my $result = _get($icinga, '/status/CIB');
            $icinga->logout;

            my $st;
            foreach (@{$result->{results}})
            {
                if ($_->{name} eq 'CIB')
                {
                    $st = $_->{status} if ($_->{status});
                    last;
                }
            }

            @out = (
                '',
                'Hosts (up / down / unreach / ack / pending)',
"  $st->{num_hosts_up} / $st->{num_hosts_down} / $st->{num_hosts_unreachable} / $st->{num_hosts_acknowledged} / $st->{num_hosts_pending}",
                'Services (ok / crit / warn / unkn / unreach / ack / pending)',
"  $st->{num_services_ok} / $st->{num_services_critical} / $st->{num_services_warning} / $st->{num_services_unknown} / $st->{num_services_unreachable} / $st->{num_services_acknowledged} / $st->{num_services_pending}",
            );

            return (join("\n", @out));
        }
        elsif ($cmd =~ m/^hosts\s+down/)
        {
            my $result = _get($icinga,
'/objects/hosts?attrs=address&attrs=state&attrs=__name&filter=host.state!=0'
            );
            $icinga->logout;

            foreach (@{$result->{results}})
            {
                my $name = $_->{attrs}->{__name};
                my $ip   = $_->{attrs}->{address};
                push(@out, "$name - $ip");
            }

            unshift(@out, '') if (@out && scalar(@out) > 1);
            return (@out) ? join("\n", @out) : "All host are UP";
        }
        elsif ($cmd =~ m/^host\s+(.*)\s*/)
        {
            my $host = $1;
            unless ($host =~ m/[\w\.\-]+/)
            {
                $icinga->logout;
                return ("Veird hostname");
            }

            my $result =
              _get($icinga, "/objects/hosts?host=$host&meta=used_by");

            if (scalar(@{$result->{results}}) == 1)
            {
                my $h = $result->{results}->[0];
                my $h_stat = ($h->{state} != 0) ? 'DOWN' : 'UP';
                push(
                    @out,
                    (
                        '',
"$h->{attrs}->{__name} - $h->{attrs}->{address} - $h_stat",
                    )
                );
                push(@out, "$h->{attrs}->{notes}") if ($h->{attrs}->{notes});

                if ($h->{attrs}->{vars}->{site})
                {
                    push(@out, "  Site: $h->{attrs}->{vars}->{site}");
                    push(@out,
"    Map: https://maps.google.com/?q=$h->{attrs}->{vars}->{geolocation}"
                    ) if ($h->{attrs}->{vars}->{geolocation});
                }

                push(@out, "  Services:");

                foreach (@{$h->{meta}->{used_by}})
                {
                    next unless ($_->{type} eq 'Service');

                    $result =
                      _get($icinga, "/objects/services?service=$_->{name}");

                    if (scalar(@{$result->{results}}) == 1)
                    {
                        my $s      = $result->{results}->[0];
                        my $s_stat = $s->{attrs}->{last_check_result}->{output};
                        $s_stat =~ s/\n.*//ms;
                        push(@out,
                            ("    $s->{attrs}->{name}", "      $s_stat",));
                    }
                }
                return (join("\n", @out));
            }
            $icinga->logout;
        }
        $icinga->logout;
    }
}

1;

sub _get
{
    my ($icinga, $uri) = @_;

    my $r = $icinga->do_request('GET', $uri,);
    unless ($r)
    {
        $icinga->logout;
        die(    'Icinga2 API fail - '
              . $icinga->request_code . ': '
              . $icinga->request_status_line);
    }

    return ($r);
}

__END__

=head1 AUTHOR

Marko Punnar <marko@aretaja.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Marko Punnar.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>

=cut
