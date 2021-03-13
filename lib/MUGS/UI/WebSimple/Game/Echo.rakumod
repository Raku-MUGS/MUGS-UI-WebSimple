# ABSTRACT: Simple web UI for echo test

use Cro::HTTP::Router;
use Cro::WebApp::Template;

use MUGS::Core;
use MUGS::UI::WebSimple::Genre::Test;
use MUGS::App::WebSimple::Session;
use MUGS::Client::Game::Echo;


#| WebSimple UI for echo test
class MUGS::UI::WebSimple::Game::Echo is MUGS::UI::WebSimple::Genre::Test {
    method game-type()               { 'echo' }
    method game-status($response)    { '' }
    method winloss-status($response) { '' }

    method base-objects(LoggedIn $user, GameID:D $game-id) {
        my ($client, $ui) = self.client-ui($user, $game-id);
        my $topic = %(|self.base-topic, :$user, :$game-id, :echo(''));

        ($client, $ui, $topic)
    }

    method update-topic(::?CLASS:D: $topic, $response) {
        callsame;

        $topic<echo> = $response.data<echo> if $response.data<echo>;
    }

    method game-routes() {
        route {
            include < game echo > => route {
                get -> LoggedIn $user, GameID $game-id where { $user.session.games{$_} }, *@ {
                    my ($client, $ui, $topic) = self.base-objects($user, $game-id);

                    # Sending a NOP rather than using initial state, because the user
                    # can open another browser tab into the game, and should see the
                    # same state in both tabs, not seeing this one reset to the start
                    # for just the first display (as soon as they posted a message, it
                    # would go to the POST route and they'd see the game in progress).
                    # XXXX: Error handling
                    await $client.send-nop: -> $response {
                        $ui.update-topic($topic, $response);
                    }

                    template $ui.ui-game-type ~ '.crotmp', $topic
                }

                post -> LoggedIn $user, GameID $game-id where { $user.session.games{$_} } {
                    request-body -> (:$message is copy) {
                        my ($client, $ui, $topic) = self.base-objects($user, $game-id);

                        $message .= trim;
                        if $message {
                            await $client.send-echo-message: $message, -> $response {
                                $ui.update-topic($topic, $response);
                            }
                        }
                        else {
                            $topic<error> = "Message is empty!";
                        }

                        template $ui.ui-game-type ~ '.crotmp', $topic
                    }
                }
            }
        }
    }
}


# Register this class as a valid game UI
MUGS::UI::WebSimple::Game::Echo.register;
