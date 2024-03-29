{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module Day4 where

import Control.Monad
import Data.List
import Data.Maybe
import Test.Hspec
import Text.Parsec
import Text.Parsec.String (Parser)

data Card = Card
    { cardIndex :: Int
    , winningNumbers :: [Int]
    , possessedNumbers :: [Int]
    }
    deriving (Eq, Show)

instance Ord Card where
    compare c1 c2 = cardIndex c1 `compare` cardIndex c2

calculatePoint :: Card -> Int
calculatePoint card =
    let countWin = calculateMatchNum card
     in if countWin >= 1 then 2 ^ (countWin - 1) else 0

calculateMatchNum :: Card -> Int
calculateMatchNum Card{..} = length (winningNumbers `intersect` possessedNumbers)

parseLine :: String -> Card
parseLine input =
    case parse lineParser "" input of
        Left err -> error (show err)
        Right c -> c

lineParser :: Parser Card
lineParser = do
    _ <- string "Card"
    skipMany1 isRealSpace
    cardIndex <- read <$> many1 digit
    _ <- char ':'
    skipMany1 isRealSpace
    winningNumbers <- parseIntList
    _ <- char '|'
    skipMany1 isRealSpace
    possessedNumbers <- parseIntList
    pure (Card{..})
  where
    isRealSpace :: Parser Char
    isRealSpace = satisfy (== ' ')

    parseIntList :: Parser [Int]
    parseIntList = sepEndBy1 (read <$> many1 digit) (many1 isRealSpace)

-------------------------------------------------------------------------------
--                                   Part 1                                  --
-------------------------------------------------------------------------------

calculateTotalPoints :: [String] -> Int
calculateTotalPoints = sum . fmap (calculatePoint . parseLine)

go1 :: IO ()
go1 =
    readFile "data/day4-input.txt"
        >>= print
        . calculateTotalPoints
        . lines

-------------------------------------------------------------------------------
--                                   Part 2                                  --
-------------------------------------------------------------------------------

calculateScratchCards :: [String] -> Int
calculateScratchCards = calInternal . fmap parseLine

calInternal :: [Card] -> Int
calInternal =
    length
        . calScratchCard
        . fmap (\c -> (cardIndex c, calculateMatchNum c))

-- (CardIndex, MatchNum)
calScratchCard :: [(Int, Int)] -> [(Int, Int)]
calScratchCard [] = []
calScratchCard [x] = [x]
calScratchCard (x : rest) =
    let (cindex, point) = x
        ys = mapMaybe (\j -> find ((== j) . fst) rest) [cindex + i | i <- [1 .. point]]
     in x : calScratchCard (ys ++ rest)

go2 :: IO ()
go2 =
    readFile "data/day4-input.txt"
        >>= print
        . calculateScratchCards
        . lines

-------------------------------------------------------------------------------
--                                    Test                                   --
-------------------------------------------------------------------------------

testMain :: IO ()
testMain = do
    day4Input <- lines <$> readFile "data/day4-input.txt"
    hspec $ do
        describe "Day4 Test" $ do
            let testDataWithIndex =
                    zipWith
                        (\(a, b, c) i -> (a, b, c, i))
                        ((day4Input, 21213, 8549735) : testData)
                        ([1 ..] :: [Int])
            forM_ testDataWithIndex $ \(inputs, expected1, expected2, index) -> do
                it (show index) $ do
                    calculateTotalPoints inputs `shouldBe` expected1
                    calculateScratchCards inputs `shouldBe` expected2

testData :: [([String], Int, Int)]
testData =
    [ (sample, 13, 30)
    ]

sample :: [String]
sample =
    [ "Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53"
    , "Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19"
    , "Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1"
    , "Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83"
    , "Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36"
    , "Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11"
    ]
