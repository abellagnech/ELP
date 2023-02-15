module Main exposing (..)
import Html.Events exposing (onInput)
import Html exposing (..)
import Html.Attributes exposing (..)
import Browser


-- MODEL

type alias Model =
    { word : String
    , definitions : List String
    }


initialModel : Model
initialModel =
    { word = "hello"
    , definitions = [ "used as a greeting or to begin a telephone conversation"
                    , "expressing surprise"
                    , "expressing understanding"
                    ]
    }


-- UPDATE

type Msg
    = NewWord String


update : Msg -> Model -> Model
update msg model =
    case msg of
        NewWord newWord ->
            { model | word = newWord }


-- VIEW

view : Model -> Html Msg
view gameState =
    div []
        [ h1 [] [ text "GuessIt" ]
        , div [] [ text "Guess the word defined below:" ]
        , viewWord gameState.word
        , viewDefinitions gameState.definitions
        , input [ type_ "text", onInput NewWord ] []
        ]


viewWord : String -> Html msg
viewWord word =
    div [] [ text word ]


viewDefinitions : List String -> Html msg
viewDefinitions definitions =
    ul [] (List.map (\definition -> li [] [ text definition ]) definitions)


-- MAIN

main : Program () Model Msg
main =
    Browser.sandbox
        { init = initialModel
        , update = update
        , view = view
        }
