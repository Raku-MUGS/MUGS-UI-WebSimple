use Cro::HTTP::Router;
use Cro::WebApp::Template;

use MUGS::Core;
use MUGS::UI;
use MUGS::App::WebSimple::Session;


sub routes(IO::Path:D :$root!, :$mugs!, :%mugs-ca!, Mu:U :$SessionManager!) is export {
    template-location $root.child('templates');

    route {
        before $SessionManager.new;

        include static-routes(:$root);
        include session-routes(:$mugs, :%mugs-ca);
        include logged-in-routes(:$mugs);

        my $ui-type = 'WebSimple';
        for MUGS::UI.known-games($ui-type) -> $game-type {
            include MUGS::UI.ui-class($ui-type, $game-type).game-routes;
        }
    }
}

sub static-routes(IO::Path:D :$root!) {
    my $css-dir = $root.child('css');
    route {
        get -> 'css', *@path {
            static $css-dir, @path
        }
    }
}

sub session-routes(:$mugs!, :%mugs-ca!) {
    route {
        get -> LoggedOut {
            template 'logged-out-home.crotmp'
        }

        get -> LoggedOut, *@ {
            redirect '/'
        }

        get -> UserSession $s, 'logout' {
            $s.logout;
            redirect '/'
        }

        get -> 'login' {
            template 'login.crotmp', ''
        }

        post -> MUGSSession $s, 'login' {
            request-body -> (:$username, :$password, *%) {
                $s.logout;
                $s.login(:$username, :$password, :server($mugs), :ca(%mugs-ca));
                if $s.logged-in {
                    my $data = await $s.session.get-info-bundle([< available-identities >]);
                    with $data<available-identities> {
                        if .elems {
                            $s.session.default-persona   = .[0]<persona>;
                            $s.session.default-character = .[0]<characters>[0] // '';
                        }
                    }
                    redirect '/', :see-other
                }
                else {
                    template 'login.crotmp', 'Bad username/password'
                }
            }
        }

        get -> 'account', 'new' {
            template 'new-account-owner.crotmp', ''
        }

        post -> MUGSSession $s, 'account', 'new' {
            request-body -> (:$username, :$password, :$confirm, *%) {
                if $username !~~ /^ \w+ $/ {
                    template 'new-account-owner.crotmp', 'Invalid username; only letters, numbers, and underscores allowed.'
                }
                elsif $password ne $confirm {
                    template 'new-account-owner.crotmp', 'Passwords do not match'
                }
                else {
                    $s.logout;
                    $s.create-account-owner(:$username, :$password,
                                            :server($mugs), :ca(%mugs-ca));
                    if $s.logged-in {
                        redirect '/identity', :see-other;
                    }
                    else {
                        template 'new-account-owner.crotmp', "Unable to create user '$username'"
                    }
                }
            }
        }
    }
}

sub logged-in-routes(:$mugs!) {
    subset KnownGameType of Str where { MUGS::UI.ui-exists('WebSimple', $_) };

    sub available-game-types($session) {
        my $data = await $session.get-info-bundle([ <available-game-types > ]);
        with $data<available-game-types> {
            my @available = .grep: { MUGS::Client.implementation-exists(.<game-type>)
                                     && MUGS::UI.ui-exists('WebSimple', .<game-type>) };
        }
        else { Empty }
    }

    route {
        get -> LoggedIn $user {
            my $s                 = $user.session;
            my @available-games   = available-game-types($s).sort:
                                    { .<genre-tags>, .<game-type> };
            my @joined-games      = $s.games.values.sort:
                                    { .game-type, .game-id };
            my $default-persona   = $s.default-persona   // '';
            my $default-character = $s.default-character // '';
            my $has-identities    = $default-persona && $default-character;
            template 'logged-in-home.crotmp', { :$user, :$has-identities,
                                                :$default-persona,
                                                :$default-character,
                                                :@available-games, :@joined-games }
        }

        get -> LoggedIn, *@ {
            redirect '/'
        }

        get -> LoggedIn $user, 'identity' {
            my $s    = $user.session;
            my $data = await $s.get-info-bundle([< available-identities >]);
            with $data<available-identities> {
                if .elems {
                    $s.default-persona   //= .[0]<persona>;
                    $s.default-character //= .[0]<characters>[0] // '';
                }
                my $available         = $_;
                my $default-persona   = $s.default-persona   // '';
                my $default-character = $s.default-character // '';
                my $has-identities    = $default-persona && $default-character;
                template 'choose-identities.crotmp', { :$user, :$available,
                                                       :$has-identities,
                                                       :$default-persona,
                                                       :$default-character }
            }
            else {
                redirect '/'
            }
        }

        get -> LoggedIn $user, 'identity', 'persona', 'new' {
            template 'new-persona.crotmp', { :$user, :error('') }
        }

        post -> LoggedIn $user, 'identity', 'persona', 'new' {
            request-body -> (:$name, *%) {
                my $screen-name = $name.trim;
                if $screen-name !~~ /^ [\w+]+ % ' ' $/ {
                    template 'new-persona.crotmp',
                        { :$user, :error('Invalid screen name; only letters, numbers, underscores, and single spaces allowed.') }
                }
                else {
                    CATCH {
                        default {
                            template 'new-persona.crotmp',
                                { :$user, :error("Unable to create persona '$screen-name'") }
                        }
                    }
                    my $s = $user.session;
                    await $s.create-persona(:$screen-name);
                    redirect '/identity', :see-other
                }
            }
        }

        get -> LoggedIn $user, 'identity', 'persona', $persona-name, 'character', 'new' {
            template 'new-character.crotmp', { :$persona-name, :$user, :error('') }
        }

        post -> LoggedIn $user, 'identity', 'persona', $persona-name, 'character', 'new' {
            request-body -> (:$name, *%) {
                my $screen-name = $name.trim;
                if $screen-name !~~ /^ [\w+]+ % ' ' $/ {
                    template 'new-character.crotmp',
                        { :$persona-name, :$user,
                          :error('Invalid screen name; only letters, numbers, underscores, and single spaces allowed.') }
                }
                else {
                    CATCH {
                        default {
                            template 'new-character.crotmp',
                                { :$persona-name, :$user,
                                  :error("Unable to create character '$screen-name'") }
                        }
                    }
                    my $s = $user.session;
                    await $s.create-character(:$persona-name, :$screen-name);
                    redirect '/identity', :see-other
                }
            }
        }

        get -> LoggedIn $user, 'game', KnownGameType $game-type, 'new' {
            my $s       = $user.session;
            # XXXX: What about posting %config?
            # XXXX: awaits OK here?
            # XXXX: Error checking?
            my $game-id = await $s.new-game(:$game-type);
            my $client  = await $s.join-game(:$game-type, :$game-id);
            redirect "/game/$game-type/$game-id", :see-other
        }

        get -> LoggedIn $user, 'game', KnownGameType $game-type,
               GameID $game-id where { !$user.session.games{$_} }, *@ {
            template 'not-in-game.crotmp', { :$user, :$game-type, :$game-id }
        }

        get -> LoggedIn $user, 'game', KnownGameType $game-type,
               GameID $game-id where { $user.session.games{$_} }, 'leave' {
            my $s = $user.session;
            # XXXX: Any more error handling if game-type doesn't match?
            $s.leave-game(:$game-id)
                if $s.games{$game-id}.game-type eq $game-type;
            redirect '/', :see-other
        }

        # get -> LoggedIn $user, 'game', KnownGameType $game-type,
        #        GameID $game-id where { $user.session.games{$_} }, *@ {
        #     template 'play-game.crotmp', { :$user, :$game-type, :$game-id }
        # }
    }
}
