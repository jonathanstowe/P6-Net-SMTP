use v5;
use Test;

plan 4;

class SMTPSocket {
    my @server-send = 
      "220 your.domain.here ESMTP Postfix",
      "250-Hello clientdomain.com",
      "250 AUTH PLAIN LOGIN",
      "235 OK",
      "334 UGFzc3dvcmQ6",
      "235 OK",
      "221 Bye"
      ;
    my @server-get = 
      "EHLO clientdomain.com",
      "AUTH PLAIN dXNlcgB1c2VyAHBhc3M=", # "user\0user\0pass"
      "AUTH LOGIN dXNlcg==", # "user"
      "cGFzcw==", # "pass"
      "QUIT"
      ;

    has $.host;
    has $.port;
    has $.input-line-separator is rw = "\n";
    method new(:$host, :$port) {
        self.bless(:$host, :$port);
    }
    method get {
        return @server-send.shift;
    }
    method send($string is copy) {
        $string .= substr(0,*-2); # strip \r\n
        die "Bad client-send: $string" unless $string eq @server-get.shift;
    }
    method close { }
}

use Net::SMTP;

my $client = Net::SMTP.new(:server('foo.com'), :port(25), :hostname('clientdomain.com'), :socket-class(SMTPSocket));
ok $client ~~ Net::SMTP, "Created object";
ok $client.auth('user', 'pass', :methods("PLAIN", "LOGIN")), 'PLAIN auth';
ok $client.auth('user', 'pass', :methods("LOGIN")), 'LOGIN auth';
ok $client.quit, "QUIT";
