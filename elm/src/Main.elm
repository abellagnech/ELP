module Main exposing (..)

import Browser exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Random
import Array exposing (..)
import Dict exposing (Dict)
import Json.Decode exposing (Decoder, map4, map2, field, int, string, list, decodeString)
import File
import Task
-- MODEL


type alias Model = 
  { text : String
  , answer : String
  , show : Bool
  , state : State
  , random : Int
  , errorMessage : String
  , word : String
  ,wordsList : List String
  }

type State
  = Failure Http.Error
  | Loading
  | Success (List (List Definitions))

type alias Definitions = 
  { partOfSpeech : String
  , definitions : (List String)
  }

init : () -> (Model, Cmd Msg)
init _ =
  ( 
        {
        text = "" 
        , answer =  "" 
        ,show = False 
        ,state= Loading
        , random = 0
        , errorMessage = ""
        , word= "" 
        ,wordsList = []
        } 
        , Http.get
        { url = "http://localhost:8000/ListOfWords.txt"
        , expect = Http.expectString WordsLoaded 
        }
        
  )

type Msg
  = NewRandomNumber Int
  | GetRandomWord
  | GotQuote (Result Http.Error (List (List Definitions)))
  | Answer String
  | Show
  | More
  | WordsLoaded (Result Http.Error (String))

url : String
url =
    "http://localhost:8000/ListOfWords.txt"
update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NewRandomNumber newnbr ->
        let
            wordArr = Array.fromList model.wordsList
            wordNew = Array.get newnbr wordArr
            a = Maybe.withDefault "........." wordNew
        in
            ( {model |  random = newnbr } ,   Http.get
                { url = "https://api.dictionaryapi.dev/api/v2/entries/en/" ++ a      
                , expect = Http.expectJson GotQuote quoteDecoder
                }
                
            )

    GetRandomWord ->
            ( model, Random.generate NewRandomNumber (Random.int 0 999) )
    GotQuote result ->
      case result of
        Ok quote ->
          ({model | state = Success quote}, Cmd.none)
        Err err ->
          ({model | state = Failure err}, Cmd.none)
          
    Answer usranswer ->
      ({model | answer=usranswer}, Cmd.none)
      
    Show ->
      ({model | show = not model.show}, Cmd.none)
      
    More ->
      (model, Random.generate NewRandomNumber (Random.int 0 999) )
    
    WordsLoaded (Ok wordsListStr) ->
            let
                wordsList = String.split " " wordsListStr
            in
            ( { model | wordsList = wordsList}, Cmd.none )

    WordsLoaded (Err httpError) ->
            ( 
                { model| errorMessage = "Problem with loading data "}, Cmd.none
            )
    
-- Decode Json
 
 
quoteDecoder : Decoder (List (List Definitions))
quoteDecoder =
    (Json.Decode.list typeDefinitionsDecoder)
    
typeDefinitionsDecoder : Decoder (List Definitions)
typeDefinitionsDecoder = 
    (field "meanings" listDefinitionDecoder)

listDefinitionDecoder : Decoder (List Definitions)
listDefinitionDecoder = 
    Json.Decode.list definitionDecoder
    
definitionDecoder : Decoder Definitions
definitionDecoder =
  map2 Definitions
    (field "partOfSpeech" string)
    (field "definitions" (Json.Decode.list definitionOnlyDecoder))
    
definitionOnlyDecoder : Decoder String
definitionOnlyDecoder = 
    (field "definition" string)



-- VIEW


view : Model -> Html Msg
view model =
  case model.state of
    -- to see what reason cause the failure
    Failure err ->
      case err of
        Http.BadUrl string ->
          div []
            [ text "I was unable to load the quote."
            , pre[][text "\n"]
            , text ("BadUrl: "++string)
            , button [ onClick More, style "display" "block" ] [text "try again"]
            ]
        Http.Timeout ->
          div []
            [ text "I was unable to load the quote."
            , pre[][text "\n"]
            , text ("Timeout")
            , button [ onClick More, style "display" "block" ] [text "try again"]
            ]
        Http.NetworkError ->
          div []
            [ text "I was unable to load the quote."
            , pre[][text "\n"]
            , text ("NetworkError")
            , button [ onClick More, style "display" "block" ] [text "try again"]
            ]
        Http.BadStatus int ->
          div []
            [ text "I was unable to load the quote."
            , pre[][text "\n"]
            , text ("BadStatus: "++(String.fromInt int))
            , button [ onClick More, style "display" "block" ] [text "try again"]
            ]
        Http.BadBody string ->
          div []
            [ text "I was unable to load the quote."
            , pre[][text "\n"]
            , text ("BadBody: "++string)
            , button [ onClick More, style "display" "block" ] [text "try again"]
            ]
            
    Loading ->
      text "Loading..."

    Success quote->
      div[style "padding-left" "200px"]
      [ viewTitle model
      , ol[][ h3[][text "meaning"]
            , getDefinition quote 0
            ]
      , viewInput "text" "Answer" model.answer Answer
      , viewValidation model
      , checkbox Show "show it !"
      , div[style "padding-left" "80px"] 
        [ button [ onClick More, style "display" "block" ] [text "Another round"] ]
      ]


viewTitle : Model -> Html msg
viewTitle model = 
  if model.show == True then
    h1 [ style "color" "green" ] [ text model.word ]
  else
    h2 [] [ text "Guess it !" ]
    
   
viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
  div[style "padding-left" "80px"] [ input [ type_ t, placeholder p, value v, onInput toMsg ] [] ]
  
  
viewValidation : Model -> Html msg
viewValidation model =
  if String.toLower(model.answer) == model.word then
    div [ style "padding-left" "80px", style "color" "green" ] [ text "Correct! Good job !!! " ]
  else
    div [ style "padding-left" "80px", style "color" "red" ] [ text "wrong word ! " ]
    

checkbox : msg -> String -> Html msg
checkbox msg name =
  label
    [ style "padding-left" "100px" ]
    [ input [ type_ "checkbox", onClick msg ] []
    , text name
    ]
    

-- get partOfSpeechs and definisions  


getDefinition : (List (List Definitions)) -> Int -> Html Msg
getDefinition quote int =
  let
    array_ListDefinition = fromList(quote)
    maybe_ListDefinition = (get 0 array_ListDefinition)
    listDefinition = Maybe.withDefault [] maybe_ListDefinition
    array_Definitions = fromList(listDefinition)          --inside is list of (partOfSpeech and definitions)
    maybe_Definition = (get int array_Definitions)
    definitions = Maybe.withDefault (Definitions "" [""]) maybe_Definition
    array_Definition = fromList(definitions.definitions)
  in
    if definitions /= Definitions "" [""] then
      div[]
      [ ol[][ text definitions.partOfSpeech
            , ol[][ fetchAllDefinitions array_Definition 0 ]
            ]
      , getDefinition quote (int+1)
      ]
    else
      div[][]

fetchAllDefinitions : Array String -> Int -> Html Msg
fetchAllDefinitions array_Definition nbr = 
  let
    maybe_Definition = (get nbr array_Definition)
    definition = Maybe.withDefault "" maybe_Definition
  in
    if definition /= "" then
      pre[] [text (String.fromInt (nbr+1) ++ ". ")
      , text definition
      , fetchAllDefinitions array_Definition (nbr+1) 
      ]
    else 
      pre[] [text (Maybe.withDefault "" maybe_Definition)]


-- MAIN

main =
  Browser.element
    { init = init
    , update = update
    , subscriptions = \_ -> Sub.none
    , view = view
    }
