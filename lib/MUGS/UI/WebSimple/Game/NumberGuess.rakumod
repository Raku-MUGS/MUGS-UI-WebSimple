# ABSTRACT: Simple web UI for number-guess game

use Cro::HTTP::Router;

use MUGS::Core;
use MUGS::UI::WebSimple::Genre::Guessing;


#| Client side of number guessing game
class MUGS::UI::WebSimple::Game::NumberGuess is MUGS::UI::WebSimple::Genre::Guessing {
    method game-type() { 'number-guess' }

    method guess-prompt(::?CLASS:D:) {
        my ($min, $max) = $.client.initial-state< min max >;
        "Enter a natural number between $min and $max > "
    }

    method guess-status($response) {
        my $result = $response.data<result>;
        "Guess #{$response.data<turns>} was "
            ~ ($result == Less ?? 'too low.'  !!
               $result == More ?? 'too high.' !!
                                  'correct.')
    }

    method game-routes() {
        route {
            include < game number-guess > => genre-routes-guessing('number-guess');
        }
    }
}


# Register this class as a valid game UI
MUGS::UI::WebSimple::Game::NumberGuess.register;
