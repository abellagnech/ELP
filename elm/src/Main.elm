module Main exposing (..)

import Http exposing (..)
import Html.Events exposing (onInput)
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode exposing (..)
import Random
import Browser
import File exposing (..)


-- MODEL

type alias Model =
    { word : String
    , definitions : List String
    }


initialModel : Model
initialModel =
    { word = ""
    , definitions = []
    }


-- UPDATE

type Msg
    = NewWord String
    | WordLoaded (Result Http.Error String)
    | DefinitionsLoaded (Result Http.Error (List String))


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        NewWord word ->
            ( { model | word = word }, Http.post WordLoaded (wordRequest word) )

        WordLoaded (Ok word) ->
            ( model, Http.post DefinitionsLoaded (definitionsRequest word) )

        WordLoaded (Err _) ->
            ( model, Cmd.none )

        DefinitionsLoaded (Ok definitions) ->
            ( { model | definitions = definitions }, Cmd.none )

        DefinitionsLoaded (Err _) ->
            ( model, Cmd.none )


wordRequest : String -> String  
wordRequest word =
    Http.get
        { method = "GET"
        , headers = []
        , url = "http://localhost:8000/randomWord?word=" ++ word
        , body = Http.emptyBody
        , expect = Http.expectString
        , timeout = Nothing
        , withCredentials = False
        }


definitionsRequest : String -> (List String)
definitionsRequest word =
    Http.get
        { method = "GET"
        , headers = []
        , url = "https://api.dictionaryapi.dev/api/v2/entries/en/" ++ word
        , body = Http.emptyBody
        , expect = Http.expectJson decodeDefinitions
        , timeout = Nothing
        , withCredentials = False
        }


decodeDefinitions : Decoder (List String)
decodeDefinitions =
    at [ "0", "meanings" ]
        (Json.Decode.list
            (at [ "definitions", "definition" ]
                string
            )
        )


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


-- API

type alias ApiResponse =
    { word : String
    , definitions : List String
    }


decodeApiResponse : Decoder ApiResponse
decodeApiResponse =
    map2 ApiResponse
        (field "word" string)
        (field "definitions" (Json.Decode.list string))


getDefinitionUrl : String -> String
getDefinitionUrl word =
    "https://api.dictionaryapi.dev/api/v2/entries/en/" ++ word


getDefinitionCmd : String -> Cmd Msg
getDefinitionCmd word =
    Http.get
        { url = getDefinitionUrl word
        , expect = Http.expectJson (WordLoaded << List.head << .definitions) decodeApiResponse
        }


-- MAIN

main : Program () Model Msg
main =
    Browser.element
        { init = (initialModel, getWordFromFileCmd) -- Remplacer getWordCmd par getWordFromFileCmd
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }

-- GET RANDOM WORD

getWordCmd : Cmd Msg
getWordCmd =
    let
        wordGenerator =
            Random.list 1 (Random.map String.words (File.read "ListOfWords.txt"))
                |> Random.generate WordLoaded
    in
    Random.generate wordGenerator


-- HELPER FUNCTIONS

splitByLine : String -> List String
splitByLine input =
    String.lines input
        |> List.filter (\line -> String.trim line /= "")


readFileCmd : String -> Cmd Msg
readFileCmd fileName =
    Http.get
        { url = fileName
        , expect = Http.expectString (WordLoaded << List.head << splitByLine)
        }


-- INTEGRATE FILE READING

getWordFromFileCmd : Cmd Msg
getWordFromFileCmd =
    readFileCmd "ListOfWords.txt"
        |> Cmd.map List.head
        |> Cmd.map (Maybe.withDefault "" >> String.trim)
        |> Cmd.map NewWord


getWordAndDefinitionCmd : String -> Cmd Msg
getWordAndDefinitionCmd word =
    Cmd.batch
        [ NewWord word |> Http.post
        , getDefinitionCmd word ]
