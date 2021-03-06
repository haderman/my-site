import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode exposing (Value)
import Url
import Url.Parser as Parser exposing (Parser, (</>), custom, map, oneOf, s, top)


-- PROJECT IMPORTS

import Page.Home as Home
import Page.About as About
import Page.Blog as Blog
import Page.Post as Post
import Skeleton exposing (..)


-- MAIN


main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }



-- MODEL
 

type alias Flags
    = Json.Decode.Value


type alias Model =
    { key : Nav.Key
    , page : Page
    , flags : Json.Decode.Value
    }


type Page
    = NotFound
    | Home Home.Model
    | About About.Model
    | Blog Blog.Model
    | Post Post.Model


init : Flags -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    stepUrl url
        { key = key
        , page = NotFound
        , flags = flags
        }



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | HomeMsg Home.Msg
    | AboutMsg About.Msg
    | BlogMsg Blog.Msg
    | PostMsg Post.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            stepUrl url model

        HomeMsg msg ->
            case model.page of
                Home home -> stepHome model (Home.update msg home)
                _         -> ( model, Cmd.none )    

        _ ->
            ( model, Cmd.none )


stepHome : Model -> ( Home.Model, Cmd Home.Msg ) -> ( Model, Cmd Msg )
stepHome model (home, cmds) =
    ( { model | page = Home home }
    , Cmd.map HomeMsg cmds
    )


stepAbout : Model -> ( About.Model, Cmd About.Msg ) -> ( Model, Cmd Msg )
stepAbout model (about, cmds) =
    ( { model | page = About about }
    , Cmd.map AboutMsg cmds
    )


stepBlog : Model -> ( Blog.Model, Cmd Blog.Msg ) -> ( Model, Cmd Msg )
stepBlog model (blog, cmds) =
    ( { model | page = Blog blog }
    , Cmd.map BlogMsg cmds
    )


stepPost : Model -> ( Post.Model, Cmd Post.Msg ) -> ( Model, Cmd Msg )
stepPost model (post, cmds) =
    ( { model | page = Post post }
    , Cmd.map PostMsg cmds
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.page of
        Home home ->
            Sub.map HomeMsg (Home.subscriptions home)
    
        _ ->
            Sub.none
                



-- VIEW


view : Model -> Browser.Document Msg
view model =
    case model.page of
        NotFound ->
            { title = "Not found"
            , body =
                [ text "Not Found" ]
            }

        Home home ->
            Skeleton.view Skeleton.Home HomeMsg (Home.view home)

        About about ->
            Skeleton.view Skeleton.About AboutMsg (About.view about)

        Blog blog ->
            Skeleton.view Skeleton.Blog BlogMsg (Blog.view blog)    

        Post post ->
            Skeleton.view Skeleton.Post PostMsg (Post.view post)



-- ROUTER


stepUrl : Url.Url -> Model -> ( Model, Cmd Msg )
stepUrl url model =
    let
        parser =
            oneOf
                [ route top
                    ( stepHome model (Home.init model.flags "Home")
                    )
                , route (s "about" )
                    ( stepAbout model (About.init model.flags "About")
                    )
                , route (s "blog" )
                    ( stepBlog model (Blog.init  "Blog")
                    )
                , route (s "blog" </> post_)
                    (\post ->
                        stepPost model (Post.init post "Post")
                    )
                ]

    in
    case Parser.parse parser url of
        Just answer ->
            answer
    
        Nothing ->
            ( model, Cmd.none )


route : Parser a b -> a -> Parser (b -> c) c
route parser handler =
    Parser.map handler parser


post_ : Parser (String -> a) a
post_ =
    custom "POST" Just

