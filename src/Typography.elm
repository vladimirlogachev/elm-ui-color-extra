module Typography exposing
    ( nbsp, prepareString, preparedText
    , TextStyle, textStyleFromFigma, paragraphAttrs
    )

{-| This module helps you to prepare text for display on a web page.
The implementation and features are far from perfect, but better than nothing.

If you are looking for a more advanced solution, consider using (or porting) <https://github.com/typograf/typograf>

"Prepare" in this module means to prevent typographic mistakes:

  - Add non-breaking spaces after specific words, so that
  - `a cat` will always be wrapped together and not leave `a` on one line and `cat` on the other.
  - `a + b` will be wrapped as `a` and `+ b`

Note: Ideally all text lines which are subject to typographic conversion
should be stored in some database (and served from the backend) in **both clean and processed forms**.
This would allow us to edit the text in a clean form and display it in a processed form.

@docs nbsp, prepareString, preparedText


# TextStyle

This module also provides a helper for creating text styles from Figma properties.

@docs TextStyle, textStyleFromFigma, paragraphAttrs

-}

import Element exposing (..)
import Element.Font as Font
import Set exposing (Set)


{-| Non-breaking space character.

You will need it only occasionally when constructing the text manually.

-}
nbsp : String
nbsp =
    "\u{00A0}"


{-|

1.  Splits a string into lines on newline characters
2.  Applies transformations to each line separately:
      - Replaces spaces after specific words with nbsp
3.  Glues the lines back together

-}
prepareString : String -> String
prepareString x =
    String.lines x
        |> List.map processIndividualLine
        |> String.join "\n"


{-| Wraps `Element.text` from `elm-ui`, applying `prepareString` before it.
-}
preparedText : String -> Element msg
preparedText =
    prepareString >> text


processIndividualLine : String -> String
processIndividualLine =
    String.words
        >> List.foldr
            (\word resultString ->
                if Set.member (String.toLower word) dictionary then
                    word ++ nbsp ++ resultString

                else if resultString == "" then
                    word

                else
                    word ++ " " ++ resultString
            )
            ""


dictionary : Set String
dictionary =
    [ -- punctuation
      "-"
    , "—"
    , "+"

    -- english
    , "a"
    , "about"
    , "an"
    , "and"
    , "any"
    , "are"
    , "as"
    , "at"
    , "au"
    , "be"
    , "bi"
    , "but"
    , "by"
    , "can"
    , "de"
    , "do"
    , "et"
    , "fit"
    , "for"
    , "from"
    , "give"
    , "go"
    , "going"
    , "had"
    , "he"
    , "i"
    , "if"
    , "in"
    , "is"
    , "it"
    , "just"
    , "know"
    , "la"
    , "let"
    , "made"
    , "may"
    , "me"
    , "my"
    , "no"
    , "not"
    , "of"
    , "on"
    , "or"
    , "part"
    , "real"
    , "see"
    , "seek"
    , "sent"
    , "so"
    , "than"
    , "that"
    , "the"
    , "them"
    , "there"
    , "this"
    , "to"
    , "up"
    , "upon"
    , "watch"
    , "wd"
    , "we"
    , "what"
    , "whether"
    , "which"
    , "who"
    , "why"
    , "will"
    , "with"
    ]
        |> Set.fromList


{-| This helper type and functions allow you to quickly configure TextStyles from Figma properties.

In elm-ui you can't specify the `line-height`, instead, you specify the paragraph spacing.
However, including the `spacing` attribute to common text styles could lead to unexpected results
when the text style is used not on a paragraph, but on a column or row.

So, a good practice would be to calculate the `paragraphSpacing` from Figma values,
but use it carefully and only in paragraphs.

As for `region` we assume that setting it for text styles like "headline" and "headers" is reasonable
because `h1`, `h2` and other header regions are easy to guess from the font size,
while for "body" or "lead" it better be unset here and set from the client code ad hoc.

-}
type alias TextStyle msg =
    { attrs : List (Attribute msg)
    , paragraphSpacing : Attribute msg
    }


{-| Creates `TextStyle`.
-}
textStyleFromFigma :
    { fontFamily : List Font.Font
    , fontWeight : Attribute msg
    , fontSizePx : Int
    , lineHeightPx : Int
    , letterSpacingPercent : Float
    , region : Maybe (Attribute msg)
    }
    -> TextStyle msg
textStyleFromFigma props =
    { attrs =
        [ Font.family props.fontFamily
        , props.fontWeight
        , Font.size props.fontSizePx
        , Font.letterSpacing (toFloat props.fontSizePx * (props.letterSpacingPercent / 100))
        ]
            ++ (case props.region of
                    Just x ->
                        [ x ]

                    Nothing ->
                        []
               )
    , paragraphSpacing = spacing <| props.lineHeightPx - props.fontSizePx
    }


{-| Combines `attrs` and `paragraphSpacing` into a list of attributes.

This helper should only be used in paragraphs.

-}
paragraphAttrs : TextStyle msg -> List (Attribute msg)
paragraphAttrs style =
    style.paragraphSpacing :: style.attrs
