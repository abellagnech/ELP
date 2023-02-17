module Main exposing (main)
import Browser
import Html exposing (..)
import Html.Attributes exposing (placeholder, value, style , type_)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode exposing (Decoder)
import String
import Url
import Url.Builder as UrlBuilder
import Html.Events exposing (onInput, onClick , onCheck)
import Http
import  Task
import Maybe exposing (..)


type alias Model =
    { wordList : List String
    , currentWord : String
    , currentDefinition : String
    , guess : String
    , guessResult : Maybe Bool
    }


init : () -> ( Model, Cmd Msg )
init _ =
    let
        wordList =
            -- Load the word list from a file
            -- In this example, we assume the words are separated by newlines
            "ListOfWords.txt"
                |> Http.post { url = "ListOfWords.txt", body = Http.emptyBody, expect = Http.expectJson FetchWordListReceived wordListDecoder }
                |> Task.perform identity
                |> String.lines
                |> List.filter (String.trim >> (/=) "")
    in
    ( Model wordList "" "" "" Nothing, Cmd.none )

wordListDecoder : Decoder (List String)
wordListDecoder =
    Json.Decode.list Json.Decode.string



type Msg
    = FetchWordListReceived (Result Http.Error String)
    | FetchWordListFailed Http.Error
    | FetchDefinitionReceived (Result Http.Error String)
    | FetchDefinitionFailed Http.Error
    | UpdateGuess String
    | CheckGuess
    | NextWord
    | RestartGame


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchWordListReceived (Ok wordList) ->
            ( { model | wordList = wordList }, Cmd.none )

        FetchWordListReceived (Err _) ->
            ( model, Cmd.none )

        FetchWordListFailed _ ->
            ( model, Cmd.none )

        FetchDefinitionReceived (Ok definition) ->
            ( { model | currentDefinition = definition }, Cmd.none )

        FetchDefinitionReceived (Err _) ->
            ( model, Cmd.none )

        FetchDefinitionFailed _ ->
            ( model, Cmd.none )

        UpdateGuess guess ->
            ( { model | guess = guess }, Cmd.none )

        CheckGuess ->
            let
                isCorrect =
                    model.guess == model.currentWord
            in
            ( { model | guessResult = Just isCorrect }, Cmd.none )

        NextWord ->
            let
                word =
                    List.map2 model.wordList
            in
            if List.isEmpty model.wordList then
                ( model, Cmd.none )
            else
                ( { model | currentWord = word, currentDefinition = "", guess = "", guessResult = Nothing }
                , Http.get ("https://api.dictionaryapi.dev/api/v2/entries/en/" ++ word ++ "?key=YOUR_API_KEY_HERE")
                    |> Http.post { url = "https://api.dictionaryapi.dev/api/v2/entries/en/" ++ word ++ "?key=YOUR_API_KEY_HERE", body = Http.emptyBody, expect = Http.expectJson FetchDefinitionReceived definitionDecoder }

            )

        RestartGame ->
            ( { model | currentWord = "", currentDefinition = "", guess = "", guessResult = Nothing }, NextWord )
definitionDecoder : Decoder (Result Http.Error String)
definitionDecoder =
    Json.Decode.at [ "0", "meanings", "0", "definitions", "0", "definition" ] Json.Decode.string
        |> Json.Decode.map Result.Ok
        |> Json.Decode.oneOf
            [ Json.Decode.at [ "error" ] (Json.Decode.map Http.BadUrl <| Json.Decode.succeed "")
            , Json.Decode.at [ "title" ] (Json.Decode.map Http.Timeout <| Json.Decode.succeed "")
            , Json.Decode.at [ "detail" ] (Json.Decode.map Http.NetworkError <| Json.Decode.succeed "")
            ]


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "Guess It!" ]
        , if List.isEmpty model.wordList then
            p [] [ text "No words available." ]
          else
            div []
                [ if model.currentDefinition == "" then
                    button [ onClick NextWord ] [ text "Start game" ]
                  else
                    div []
                        [ h2 [] [ text model.currentWord ]
                        , p [] [ text model.currentDefinition ]
                        , case model.guessResult of
                            Just True ->
                                p [ style "color" "green" ] [ text "Correct" ]
                            Just False ->
                                p [ style "color" "red" ] [ text "Incorrect" ]
                            Nothing ->
                                Html.Attributes.form [ onInput UpdateGuess, onCheck CheckGuess ]
                                    [ input [ type_ "text", value model.guess ] []
                                    , button [ type_ "submit" ] [ text "Guess" ]
                                    ]
                        ]
                , button [ onClick RestartGame ] [ text "Restart game" ]
                ]
        ]

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
