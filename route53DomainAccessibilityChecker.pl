#!/usr/bin/perl --

use strict;
use warnings;
use LWP::UserAgent;
use lib qw|p5-AWS-Route53-Simple/lib|;
use AWS::Route53::Simple;
use Data::Dumper;

my %credentials = (
    AccessKey => $ENV{"AWS_ACCESS_KEY"},
    SecretAccessKey => $ENV{"AWS_SECRET_KEY"}
);
$credentials{"use_ntp"} = 1;
$credentials{"ntp_server"} = "ntp.nict.jp";
my $r53 = AWS::Route53::Simple->new(%credentials);
my $hz = $r53->action("ListHostedZones")->returnType("perl")->send();
my %domains;
foreach (@{$hz->{HostedZones}->{HostedZone}}) {
    (my $id = $_->{"Id"}) =~ s/^\/[^\/]*\///msxi;
    my $rrs = $r53->action("ListResourceRecordSets")->returnType("perl")->send({ZoneID => $id});
    foreach (@{$rrs->{"ResourceRecordSets"}->{"ResourceRecordSet"}}) {
        if ($_->{"Type"} eq "A" or $_->{"Type"} eq "CNAME") {
            $domains{$_->{"Name"}} = 1;
        }
    }
}

my $ua = LWP::UserAgent->new();
$ua->timeout(2);
foreach (keys(%domains)) {
    my $url = $_;
    $url =~ s/\.$//msxi;
    my $res = $ua->get("http://".$url);
    if ($res->code =~ /2../msx) {
        print $_." is accessible.";
    }
}

