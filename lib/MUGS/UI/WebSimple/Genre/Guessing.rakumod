# ABSTRACT: General simple web UI for simple guessing games

use Cro::HTTP::Router;
use Cro::WebApp::Template;

use MUGS::Core;
use MUGS::Client::Genre::Guessing;
use MUGS::UI;

use MUGS::App::WebSimple::Session;


#| UI for guessing games
class MUGS::UI::WebSimple::Genre::Guessing is MUGS::UI::Game {
    method ui-type()                     { 'WebSimple' }
    method guess-prompt()                { 'Next guess > ' }
    method guess-status($response)       { ... }
    method game-status($response)        { '' }
    method winloss-status($response) {
        $response.data<winloss> == Win ?? 'You win!' !! ''
    }
}


sub genre-routes-guessing(Str:D $game-type) is export {
    my $ui-type = 'WebSimple';
    die "No $ui-type UI class exists for game type '$game-type'"
        unless MUGS::UI.ui-exists($ui-type, $game-type);

    my sub client-ui(LoggedIn $user, GameID:D $game-id) {
        my $client    = $user.session.games{$game-id};
        my $game-type = $client.game-type;

        # XXXX: There's now an exception type for this
        die "Game type for game $game-id ({ $client.game-type }) does not match request game-type ($game-type)"
            unless $game-type eq $client.game-type;

        # XXXX: Modernize as per LocalUI
        my $ui = MUGS::UI.ui-class($ui-type, $game-type).new(:$client)
            or die "Unable to create $ui-type UI for game type '$game-type'";

        ($client, $ui)
    }

    my sub base-objects(LoggedIn $user, GameID:D $game-id) {
        my ($client, $ui) = client-ui($user, $game-id);
        my $topic = { :$user, :$game-type, :$game-id, :!done,
                      :tried([]), :error(''), :prompt($ui.guess-prompt),
                      :guess-status(''), :game-status(''), :winloss-status('') };

        ($client, $ui, $topic)
    }

    my sub update-topic($ui, $topic, $response) {
        $topic<tried> = $response.data<tried>;
        $topic<done>  = $response.data<gamestate> >= Finished;

        $topic<guess-status> = $ui.guess-status($response)
            if $response.data<result>.defined;

        $topic<game-status>    = $ui.game-status($response);
        $topic<winloss-status> = $ui.winloss-status($response);
    }

    route {
        get -> LoggedIn $user, GameID $game-id where { $user.session.games{$_} }, *@ {
            my ($client, $ui, $topic) = base-objects($user, $game-id);

            # Sending a NOP rather than using initial state, because the user
            # can open another browser tab into the game, and should see the
            # same state in both tabs, not seeing this one reset to the start
            # for just the first display (as soon as they posted a guess, it
            # would go to the POST route and they'd see the game in progress).
            # XXXX: Error handling
            await $client.send-nop: -> $response { update-topic($ui, $topic, $response) };

            template $ui-type.lc ~ '-' ~ $game-type ~ '.crotmp', $topic
        }

        post -> LoggedIn $user, GameID $game-id where { $user.session.games{$_} } {
            request-body -> (:$guess is copy) {
                my ($client, $ui, $topic) = base-objects($user, $game-id);

                $guess .= trim;
                if $client.valid-guess($guess) {
                    await $client.send-guess: $guess, -> $response {
                        update-topic($ui, $topic, $response);
                    };
                }
                else {
                    $topic<error> = "That's not a valid guess!";
                }

                template $ui-type.lc ~ '-' ~ $game-type ~ '.crotmp', $topic
            }
        }
    }
}
