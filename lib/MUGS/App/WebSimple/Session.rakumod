# ABSTRACT: Simple session management for MUGS web UI server

use Cro::HTTP::Auth;

use MUGS::Client;
use MUGS::Client::Connection::Supplier;
use MUGS::Client::Connection::WebSocket;
use MUGS::Server;


role UserSession does Cro::HTTP::Auth {
    has Str $.username is rw;

    method login(Str:D :$!username) { }
    method logout()    { $!username = Nil   }
    method logged-in() { defined $!username }
}

subset LoggedIn  is export of UserSession where  *.logged-in;
subset LoggedOut is export of UserSession where !*.logged-in;


class MUGSSession does UserSession {
    has                       $.server;
    has MUGS::Client::Session $.session;

    method !connect($server, :%ca) {
        # XXXX: Error checking
        my $session;

        if $server ~~ MUGS::Server {
            my $connector = MUGS::Client::Connection::Supplier;
            $session = MUGS::Client::Session.connect(:$connector, :$server);
        }
        else {
            my $connector = MUGS::Client::Connection::WebSocket;
            $session = MUGS::Client::Session.connect(:$connector, :$server, :%ca);
        }

        if $session {
            $!session = $session;
            $!server  = $server;
        }
    }

    method login(Str:D :$username!, Str:D :$password!, :$server!, :%ca) {
        self!connect($server, :%ca);

        if $!session {
            try await $!session.authenticate(:$username, :$password);
            $.username = $username if $!session.username;
        }
    }

    method create-account-owner(Str:D :$username!, Str:D :$password!, :$server!, :%ca) {
        self!connect($server, :%ca);

        if $!session {
            try await $!session.create-account-owner(:$username, :$password);
            $.username = $username if $!session.username;
        }
    }

    method logout() {
        $!session.disconnect if $!session;

        $.username = Nil;
        $!server   = Nil;
        $!session  = Nil;
    }
}
