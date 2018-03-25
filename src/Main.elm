module Main exposing (..)

import Html exposing (Html, text, div, h1, ul, li, input, label, button, Attribute)
import Html.Attributes exposing (class, type_, placeholder, value, checked)
import Html.Events exposing (on, keyCode, onInput, onClick, onCheck)
import Json.Decode as Json


main =
  Html.program
    { init = init
    , view = view
    , update = update
    , subscriptions = \_ -> Sub.none
    }




-- MODEL
type alias Todo =
  { completed: Bool
  , content: String
  , id: Int
  }

type Visibilty
  = All
  | Active
  | Completed


type alias Model =
    { todos : List Todo
    , userInput : String
    , visibility: Visibilty
    }



-- MSG

type Msg
    = KeyDown Int
    | Input String
    | Remove Int
    | Toggle Int
    | ToggleAll
    | SetVisibility Visibilty
    | RemoveCompleted



-- INIT

-- js interop
-- type alias Flags =
--   { user : String
--   , token : String
--   }

-- init : Flags -> ( Model, Cmd Msg )

initialModel : Model
initialModel = Model [] "" All

init : (Model, Cmd Msg)
init = (initialModel, Cmd.none)



onKeyDown : Attribute Msg
onKeyDown =
    on "keydown" (Json.map KeyDown keyCode)


-- VIEW


view : Model -> Html Msg
view model =
  div [ class "todo-list-container" ]
    [ h1 [] [ text "todos" ]
    , todoForm model
    ]



todoForm : Model -> Html Msg
todoForm model =
  div [ class "form" ]
    [ todoHeader model
    , todoList model
    ]


todoHeader : Model -> Html Msg
todoHeader { userInput, todos } =
  let
    toggleAllClass =
      if List.isEmpty todos then
        class "toggle-all hide-toggle"
      else
        class "toggle-all"


    toggleAll = (\_ -> ToggleAll)
  in
    div [ class "todo-header" ]
      [ input [ toggleAllClass, checked (allCompleted todos), onCheck toggleAll, type_ "checkbox" ] []
      , input
        [ class "user-input"
        , type_ "text"
        , placeholder "What needs to be done?"
        , onKeyDown
        , onInput Input
        , value userInput
        ] []
      ]


todoList : Model -> Html Msg
todoList { todos, visibility } =
  if List.isEmpty todos then
    div [] []

  else
    let
      toListItem todo =
        let
          labelClass = class
            (if todo.completed then
              "completed"
            else
              "")
        in
          li [ class "list-item" ]
            [ input [ class "checkbox", type_ "checkbox", checked todo.completed, onCheck (\_ -> Toggle todo.id) ] []
            , label [ labelClass ] [ text todo.content ]
            , button [ class "remove-todo", onClick (Remove todo.id) ] []
            ]

      filterFunc =
        case visibility of
          All ->
            (\_ -> True)
          Active ->
            (\todo -> not todo.completed)
          Completed ->
            (\todo -> todo.completed)

      list =
        List.filter filterFunc todos
        |> List.map toListItem

    in
      div []
        [ ul [] list
        , todoListFooter todos visibility
        ]



todoListFooter : List Todo -> Visibilty -> Html Msg
todoListFooter todos currentVisibility =
  let
    count = List.length <| List.filter (\todo -> not todo.completed) todos
    footerMsg =
      if count == 1 then
        (toString count) ++ " item left"
      else
        (toString count) ++ " items left"


    visibilityOptions =
      let
        btn =
          visibilityButton currentVisibility
      in
        div [ class "visibility-options" ]
          [ btn All
          , btn Active
          , btn Completed
          ]


    clearAllBtn =
      let
        clearBtnClass =
          if List.member True <| List.map (\todo -> todo.completed) todos then
            "clear-completed"
          else
            "clear-completed hide"
      in
        button [ class clearBtnClass, onClick RemoveCompleted ] [ text "Clear completed" ]

  in
    div [ class "todo-footer" ]
      [ div [ class "count-message" ] [ text footerMsg ]
      , visibilityOptions
      , clearAllBtn
      ]



visibilityButton : Visibilty -> Visibilty -> Html Msg
visibilityButton currentViz viz =
  let
    buttonClass = if currentViz == viz then
      class "viz-button active"
    else
      class "viz-button"
  in
    button [ buttonClass, onClick (SetVisibility viz) ] [ text (toString viz) ]








-- UPDATE


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    KeyDown int ->
      let
        enterKey = 13
      in
        if int == enterKey && not (String.isEmpty model.userInput) then
          (addTodo model, Cmd.none)
        else
          (model, Cmd.none)


    Input str ->
      ({ model | userInput = str }, Cmd.none)


    Remove todoId ->
      let
        filteredTodos = List.filter (\todo -> todo.id /= todoId) model.todos
      in
        ({ model | todos = filteredTodos }, Cmd.none)



    Toggle todoId ->
      let
        updatedTodos =
          (flip List.map) model.todos
            (\todo ->
              if todo.id == todoId then
                { todo | completed = not todo.completed }
              else
                todo)
      in
        ({ model | todos = updatedTodos }, Cmd.none)


    ToggleAll ->
      let
        toggled =
          if allCompleted model.todos then
            List.map (\todo -> { todo | completed = False }) model.todos
          else

          (flip List.map)
            model.todos
            (\todo ->
              { todo | completed = if todo.completed then todo.completed else not todo.completed })
      in
        ({ model | todos = toggled }, Cmd.none)


    SetVisibility viz ->
      ({ model | visibility = viz }, Cmd.none)

    RemoveCompleted ->
      let
        uncompleted =
          List.filter (\todo -> not todo.completed) model.todos
      in
        ({ model | todos = uncompleted }, Cmd.none)





addTodo : Model -> Model
addTodo model =
  let
    newTodo =
      { completed = False
      , content = model.userInput
      , id = (List.length model.todos) + 1
      }

    newTodos = Debug.log "TODO" (newTodo :: model.todos)

  in
    { model | todos = newTodos, userInput = "" }








-- UTILS
allCompleted : List Todo -> Bool
allCompleted = not << List.member False << List.map (\todo -> todo.completed)
