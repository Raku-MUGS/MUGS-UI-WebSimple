# ABSTRACT: General WebSimple UI genre for Interactive Fiction games

use Cro::HTTP::Router;
use Cro::WebApp::Template;

use MUGS::Core;
use MUGS::UI::WebSimple;
use MUGS::App::WebSimple::Session;
use MUGS::Client::Genre::IF;


#| WebSimple UI genre for Interactive Fiction games
class MUGS::UI::WebSimple::Genre::IF is MUGS::UI::WebSimple::Game {
    method game-status($response) { '' }

    method winloss-status($response) {
        given $.client.my-winloss($response) {
            when Loss { 'You have lost.' }
            when Win  { 'You have won!'  }
            default   { ''               }
        }
    }

    method base-objects(LoggedIn $user, GameID:D $game-id) {
        my ($client, $ui) = self.client-ui($user, $game-id);
        my $topic = %(|self.base-topic, :$user, :$game-id, :prompt(''));

        ($client, $ui, $topic)
    }

    method update-topic(::?CLASS:D: $topic, $response, :$data = $response.data) {
        callsame;

        for < pre-title pre-message message > {
            $topic{$_} = $data{$_} // '';
        }

        with $data<inventory> {
            $topic<inventory> = $_ ?? 'Inventory: ' ~ .join(', ')
                                   !! 'Nothing in your inventory.';
        }
        orwith $data<location> {
            my @not-me = (.<characters> || []).grep(* ne $.client.character-name);

            $topic<location> = %(
                name        => .<name>,
                description => .<description>,
                things      => (.<things> ?? 'Things: '    ~ .<things>.join(', ') !! ''),
                exits       => (.<exits>  ?? 'Exits: '     ~ .<exits>.join(', ')  !! ''),
                not-me      => (@not-me   ?? 'Also here: ' ~ @not-me.join(', ')   !! ''),
            );
        }
    }

    method genre-routes-IF() {
        route {
            get -> LoggedIn $user, GameID $game-id where { $user.session.games{$_} }, *@ {
                my ($client, $ui, $topic) = self.base-objects($user, $game-id);

                # Sending a NOP rather than using initial state, because the user
                # can open another browser tab into the game, and should see the
                # same state in both tabs, not seeing this one reset to the start
                # for just the first display (as soon as they posted a turn, it
                # would go to the POST route and they'd see the game in progress).
                # XXXX: Error handling
                await $client.send-nop: -> $response {
                    my $data = $response.data<turns> ?? $response.data
                                                     !! $client.initial-state;
                    $ui.update-topic($topic, $response, :$data);
                }

                template $ui.ui-game-type ~ '.crotmp', $topic
            }

            post -> LoggedIn $user, GameID $game-id where { $user.session.games{$_} } {
                request-body -> (:$input is copy) {
                    my ($client, $ui, $topic) = self.base-objects($user, $game-id);

                    $input .= trim;
                    if $input {
                        await $client.send-unparsed-input($input, -> $response {
                            $ui.update-topic($topic, $response);
                        }).then: {
                            if .status == Broken {
                                my $invalid = .cause ~~ X::MUGS::Response::InvalidRequest;
                                $topic<error> = $invalid ?? .cause.error !! .cause.message;
                            }
                        }
                    }

                    template $ui.ui-game-type ~ '.crotmp', $topic
                }
            }
        }
    }
}
