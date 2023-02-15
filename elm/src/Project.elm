module Project exposing(..)
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html exposing (Html, Attribute, div, input, text, button)
import Html.Events exposing (..)
import Http
import Random 
import Json.Decode exposing (..)

type alias Word = String
type alias Definitions = List String
type alias GameState =
    { word : Word
    , definitions : Definitions
    -- Ajoutez d'autres champs ici selon vos besoins
    }
initialState : GameState
initialState =
    { word = "Elm" -- Le mot à deviner initial
    , definitions = ["Un langage de programmation fonctionnelle", "Utilisé pour créer des applications web", "Conçu pour faciliter la création d'applications évolutives"]
    -- Initialisez d'autres champs ici selon vos besoins
    }
viewWord : Word -> Html msg
viewWord word =
    h1 [] [ text word ]
viewDefinitions : Definitions -> Html msg
viewDefinitions definitions =
    ul [] (List.map (\d -> li [] [ text d ]) definitions)

view : GameState -> Html msg
view gameState =
    div []
        [ viewWord gameState.word
        , viewDefinitions gameState.definitions
        ]

main : Program () GameState msg
main =
    beginnerProgram { model = initialState, view = view }

