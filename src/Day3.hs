module Day3 where

import Control.Monad
import Data.Char (isDigit)
import Data.List (sort)
import Data.Vector (Vector, (!?))
import Data.Vector qualified as V
import Test.Hspec

go1 :: IO ()
go1 =
    do
        readFile "data/day3-input.txt"
        >>= print
        . goInternal1
        . lines

-------------------------------------------------------------------------------
--                                   Part1                                   --
-------------------------------------------------------------------------------

goInternal1 :: [[Char]] -> Int
goInternal1 rawInputs =
    let inputs = V.fromList (fmap V.fromList rawInputs)
     in sum $ findNumber inputs $ findDigitsIndex inputs

isSymbol :: Char -> Bool
isSymbol c = not (isDigit c) && c /= '.'

isDot :: Char -> Bool
isDot = (== '.')

-- | Find all indexs of Digits that are adjacent of symbol
findDigitsIndex :: Vector (Vector Char) -> [(Int, Int)]
findDigitsIndex inputs =
    removeIndexesForSameNumber
        $ sort
        $ filter
            ( \(i, j) ->
                case inputs !? i of
                    Just row -> case row !? j of
                        Just e -> not (isDot e)
                        Nothing -> False
                    Nothing -> False
            )
        $ concat
        $ V.toList
        $ V.concat
        $ V.toList
        $ V.imap
            ( \i v ->
                V.imap
                    ( \j a ->
                        if isSymbol a
                            then
                                [ (i - 1, j)
                                , (i - 1, j - 1)
                                , (i - 1, j + 1)
                                , (i + 1, j)
                                , (i + 1, j - 1)
                                , (i + 1, j + 1)
                                , (i, j - 1)
                                , (i, j + 1)
                                ]
                            else []
                    )
                    v
            )
            inputs

removeIndexesForSameNumber :: [(Int, Int)] -> [(Int, Int)]
removeIndexesForSameNumber xs =
    case xs of
        [] -> []
        [x] -> [x]
        (x : y : rest) ->
            [x | not (fst x == fst y && snd y - snd x == 1)]
                ++ removeIndexesForSameNumber (y : rest)

findNumber :: Vector (Vector Char) -> [(Int, Int)] -> [Int]
findNumber inputs = map (findNumberAroundIndex inputs)

findNumberAroundIndex :: Vector (Vector Char) -> (Int, Int) -> Int
findNumberAroundIndex inputs (i, j) =
    read
        $ findNumberAtIndexLeft inputs (i, j) []
        ++ tail (findNumberAtIndexRight inputs (i, j) [])

findNumberAtIndexLeft :: Vector (Vector Char) -> (Int, Int) -> [Char] -> [Char]
findNumberAtIndexLeft inputs (i, j) accum =
    case inputs !? i of
        Just row -> case row !? j of
            Just el -> if isDigit el then findNumberAtIndexLeft inputs (i, j - 1) (el : accum) else accum
            Nothing -> accum
        Nothing -> accum

findNumberAtIndexRight :: Vector (Vector Char) -> (Int, Int) -> [Char] -> [Char]
findNumberAtIndexRight inputs (i, j) accum =
    case inputs !? i of
        Just row -> case row !? j of
            Just el -> if isDigit el then findNumberAtIndexRight inputs (i, j + 1) (accum ++ [el]) else accum
            Nothing -> accum
        Nothing -> accum

-------------------------------------------------------------------------------
--                                   Part2                                   --
-------------------------------------------------------------------------------

go2 :: IO ()
go2 =
    do
        readFile "data/day3-input.txt"
        >>= print
        . goInternal2
        . lines

goInternal2 :: [[Char]] -> Int
goInternal2 rawInputs =
    let inputs = V.fromList (fmap V.fromList rawInputs)
     in sum $ V.map product $ findGearNumber inputs

findGearNumber :: Vector (Vector Char) -> Vector [Int]
findGearNumber inputs =
    V.map sort
        $ V.filter (\xs -> length xs == 2)
        $ fmap
            ( findNumber inputs
                . removeIndexesForSameNumber
                . sort
                . filter
                    ( \(i, j) -> case inputs !? i of
                        Just row -> case row !? j of
                            Just e -> not (isDot e)
                            Nothing -> False
                        Nothing -> False
                    )
            )
        $ V.filter (not . null)
        $ V.concat
        $ V.toList
        $ V.imap
            ( \i v ->
                V.imap
                    ( \j a ->
                        if a == '*'
                            then
                                [ (i - 1, j)
                                , (i - 1, j - 1)
                                , (i - 1, j + 1)
                                , (i + 1, j)
                                , (i + 1, j - 1)
                                , (i + 1, j + 1)
                                , (i, j - 1)
                                , (i, j + 1)
                                ]
                            else []
                    )
                    v
            )
            inputs

-------------------------------------------------------------------------------
--                                    Test                                   --
-------------------------------------------------------------------------------

testMain :: IO ()
testMain = hspec $ do
    describe "Day3" $ do
        let testDataWithIndex =
                zipWith
                    (\(a, b, c) i -> (a, b, c, i))
                    testData
                    ([1 ..] :: [Int])
        forM_ testDataWithIndex $ \(inputs, expected1, expected2, index) -> do
            it (show index) $ do
                goInternal1 inputs `shouldBe` expected1
                goInternal2 inputs `shouldBe` expected2

testData :: [([String], Int, Int)]
testData =
    [ (sampleData, 4361, 467835)
    , (["*67..114.."], 67, 0)
    ,
        (
            [ "67...114.."
            , "+........."
            ]
        , 67
        , 0
        )
    ,
        (
            [ "..9..114.."
            , ".*........"
            , ".81........"
            ]
        , 90
        , 729
        )
    ,
        (
            [ "..9..114.."
            , ".*5......."
            , ".81........"
            ]
        , 95
        , 0
        )
    ,
        (
            [ "&......8.."
            , ".8.....+.."
            ]
        , 16
        , 0
        )
    ,
        (
            [ "362..1......*"
            , ".....*......3"
            , "......605...."
            ]
        , 609
        , 605
        )
    , (["..658.509*378.."], 887, 192402)
    ]

sampleData :: [String]
sampleData =
    [ "467..114.."
    , "...*......"
    , "..35..633."
    , "......#..."
    , "617*......"
    , ".....+.58."
    , "..592....."
    , "......755."
    , "...$.*...."
    , ".664.598.."
    ]
