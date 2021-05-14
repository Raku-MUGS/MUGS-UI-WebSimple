# ABSTRACT: Simple web UI for Snowman word guessing game

use Cro::HTTP::Router;

use MUGS::Core;
use MUGS::UI::WebSimple::Genre::Guessing;


#| Web UI side of Snowman word guessing game
class MUGS::UI::WebSimple::Game::Snowman is MUGS::UI::WebSimple::Genre::Guessing {
    method game-type()    { 'snowman' }
    method guess-prompt() { 'Enter a letter in this word > ' }

    method guess-status($response) {
        "Guess #{$response.data<turns>} was "
            ~ ($response.data<correct> ?? 'correct'
                                       !! 'not in the word.')
    }

    method winloss-status($response) {
        given $.client.my-winloss($response) {
            when Win  { "You win{', and just in time' if $response.data<misses> == 5}!" }
            when Loss { "Oh no, you didn't figure it out in time!" }
            default   { '' }
        }
    }

    method game-status($response) {
        self.render-picture($response.data<misses>)
        ~ "<p>The word is now: { $response.data<partial>.comb.join(' ') }</p>"
    }

    method render-picture(UInt:D $misses) {
        my @picture = self.picture-background;
        my @stages  = self.picture-stages;
        for ^($misses min +@stages) {
            my @stage := @stages[$_];
            for @stage -> $part {
                @picture[$part[1]].substr-rw($part[2], $part[0].chars) = $part[0];
            }
        }

        '<pre>' ~ @picture.join("\n") ~ '</pre>'
    }

    method picture-background() {
        '            ',
        '            ',
        '            ',
        '            ',
        '            ',
        '============'
    }

    method picture-stages() {
        # '     __     ',
        # '   _|__|_  W',
        # '    (**)   |',
        # '+--(  : )--+',
        # '  (   :  ) |',
        # '============'

        ((  '(   :  )', 4, 2), ),
        ((   '(  : )',  3, 3), ),
        ((    '(**)',   2, 4), ('__',  1, 5)),
        ((   '_|__|_',  1, 3), ('__',  0, 5)),
        (('+--',        3, 0), ('--+', 3, 9)),
        (('W', 1, 11), ('|', 2, 11), ('|', 4, 11)),
    }

    method stage-names() {
        « body shoulders head hat arms broom »
    }

    method game-routes() {
        route {
            include < game snowman > => self.genre-routes-guessing;
        }
    }
}


# Register this class as a valid game UI
MUGS::UI::WebSimple::Game::Snowman.register;
