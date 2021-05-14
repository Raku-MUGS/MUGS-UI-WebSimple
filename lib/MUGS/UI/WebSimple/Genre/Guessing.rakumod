# ABSTRACT: General simple web UI for simple guessing games

use Cro::HTTP::Router;
use Cro::WebApp::Template;

use MUGS::Core;
use MUGS::UI::WebSimple;
use MUGS::App::WebSimple::Session;
use MUGS::Client::Genre::Guessing;


#| UI for guessing games
class MUGS::UI::WebSimple::Genre::Guessing is MUGS::UI::WebSimple::Game {
    method guess-prompt()            { 'Next guess > ' }
    method guess-status($response)   { ... }
    method game-status($response)    { '' }
    method winloss-status($response) {
        $.client.my-winloss($response) == Win ?? 'You win!' !! ''
    }

    method base-objects(LoggedIn $user, GameID:D $game-id) {
        my ($client, $ui) = self.client-ui($user, $game-id);
        my $topic = %(|self.base-topic, :$user, :$game-id, :tried([]),
                      :prompt($ui.guess-prompt), :guess-status(''));

        ($client, $ui, $topic)
    }

    method update-topic(::?CLASS:D: $topic, $response) {
        callsame;

        $topic<tried>        = $response.data<tried>;
        $topic<guess-status> = self.guess-status($response)
            if $response.data<result>.defined;
    }

    method genre-routes-guessing() {
        route {
            get -> LoggedIn $user, GameID $game-id where { $user.session.games{$_} }, *@ {
                my ($client, $ui, $topic) = self.base-objects($user, $game-id);

                # Sending a NOP rather than using initial state, because the user
                # can open another browser tab into the game, and should see the
                # same state in both tabs, not seeing this one reset to the start
                # for just the first display (as soon as they posted a guess, it
                # would go to the POST route and they'd see the game in progress).
                # XXXX: Error handling
                await $client.send-nop: -> $response {
                    $ui.update-topic($topic, $response);
                }

                template $ui.ui-game-type ~ '.crotmp', $topic
            }

            post -> LoggedIn $user, GameID $game-id where { $user.session.games{$_} } {
                request-body -> (:$guess is copy) {
                    my ($client, $ui, $topic) = self.base-objects($user, $game-id);

                    $guess .= trim;
                    if $client.valid-guess($guess) {
                        await $client.send-guess: $guess, -> $response {
                            $ui.update-topic($topic, $response);
                        }
                    }
                    else {
                        $topic<error> = "That's not a valid guess!";
                    }

                    template $ui.ui-game-type ~ '.crotmp', $topic
                }
            }
        }
    }
}
