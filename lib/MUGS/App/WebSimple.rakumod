# ABSTRACT: Core logic to set up and run a MUGS web UI server

use Cro::HTTP::Session::InMemory;

use MUGS::App::CroServer;
use MUGS::App::WebSimple::Session;
use MUGS::App::WebSimple::Routes;
use MUGS::Client;
use MUGS::Server::Stub;


# Use subcommand MAIN args
%PROCESS::SUB-MAIN-OPTS = :named-anywhere;


#| Launch a MUGS web UI server on host:port, using a MUGS backend at server
sub MAIN(# Web gateway host:port
         Str:D  :$host        = %*ENV<MUGS_WEB_SIMPLE_HOST> || 'localhost',
         UInt:D :$port        = %*ENV<MUGS_WEB_SIMPLE_PORT> || 20_000,

         # TLS keys/certs
         :$private-key-file   = %*ENV<MUGS_WEB_SIMPLE_TLS_KEY>       ||
                                %?RESOURCES<fake-tls/server-key.pem> ||
                                 'resources/fake-tls/server-key.pem',
         :$certificate-file   = %*ENV<MUGS_WEB_SIMPLE_TLS_CERT>      ||
                                %?RESOURCES<fake-tls/server-crt.pem> ||
                                 'resources/fake-tls/server-crt.pem',
         :$server-ca-file     = %*ENV<MUGS_WEBSOCKET_TLS_CA>         ||
                                %?RESOURCES<fake-tls/ca-crt.pem>     ||
                                 'resources/fake-tls/ca-crt.pem',

         # WebSocket backend MUGS server
         Str:D  :$server-host = %*ENV<MUGS_WEBSOCKET_HOST> || 'localhost',
         UInt:D :$server-port = %*ENV<MUGS_WEBSOCKET_PORT> || 0,
         Str:D  :$server      = $server-host && $server-port
                                ?? "wss://$server-host:$server-port/mugs-ws" !! '',

         # Boolean flags
         Bool:D :$secure      = False,
         Bool:D :$debug       = False,
        ) is export {

    $PROCESS::DEBUG = $debug;

    my $mugs-server = do if $server {
        put-flushed "Using server '$server'\n";
        $server
    }
    else {
        put-flushed "Using internal stub server.\n";
        my $stub = create-stub-mugs-server;
        load-plugins('server', $stub);
        $stub
    }

    load-plugins('client', MUGS::Client);
    load-plugins('UI', MUGS::UI, 'WebSimple');

    my %mugs-ca        = ca-file => $server-ca-file;
    my $SessionManager = Cro::HTTP::Session::InMemory[MUGSSession];
    my $application    = routes(:root($*PROGRAM.parent(2)), :mugs($mugs-server),
                                :%mugs-ca, :$SessionManager);
    my $ui-server      = create-cro-server(:$application, :$host, :$port,
                                           :$secure, :$private-key-file,
                                           :$certificate-file);

    $ui-server.start;
    my $url = "http{'s' if $secure}://$host:$port/";
    put-flushed "Listening at $url";

    react {
        whenever signal(SIGINT) {
            put-flushed 'Shutting down.';
            $ui-server.stop;
            done;
        }
    }
}
