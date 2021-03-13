# ABSTRACT: WebSimple UI for IF adventure games

use Cro::HTTP::Router;

use MUGS::Core;
use MUGS::Client::Game::Adventure;
use MUGS::UI::WebSimple::Genre::IF;


#| WebSimple UI for an IF adventure game
class MUGS::UI::WebSimple::Game::Adventure is MUGS::UI::WebSimple::Genre::IF {
    method game-type() { 'adventure' }

    method game-routes() {
        route {
            include < game adventure > => self.genre-routes-IF;
        }
    }
}


# Register this class as a valid game UI
MUGS::UI::WebSimple::Game::Adventure.register;
