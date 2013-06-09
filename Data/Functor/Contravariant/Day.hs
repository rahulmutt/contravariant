{-# LANGUAGE CPP #-}
{-# LANGUAGE ExistentialQuantification #-}
#if defined(__GLASGOW_HASKELL__) && __GLASGOW_HASKELL__ > 707
{-# LANGUAGE DeriveDataTypeable #-}
#endif
#if defined(__GLASGOW_HASKELL__) && __GLASGOW_HASKELL__ <= 707
{-# LANGUAGE KindSignatures #-}
#endif
-----------------------------------------------------------------------------
-- |
-- Copyright   :  (C) 2013 Edward Kmett, Gershom Bazerman and Derek Elkins
-- License     :  BSD-style (see the file LICENSE)
--
-- Maintainer  :  Edward Kmett <ekmett@gmail.com>
-- Stability   :  provisional
-- Portability :  portable
--
-- The Day convolution of two contravariant functors is a contravariant
-- functor.
--
-- <http://ncatlab.org/nlab/show/Day+convolution>
----------------------------------------------------------------------------

module Data.Functor.Contravariant.Day
  ( Day(..)
  , runDay
  , assoc, disassoc
  , swapped
  , intro1, intro2
  , day1, day2
  ) where

import Control.Applicative
import Data.Functor.Contravariant
import Data.Proxy
import Data.Tuple (swap)
#ifdef __GLASGOW_HASKELL__
import Data.Typeable
#endif

-- | The Day convolution of two contravariant functors.
data Day f g a = forall b c. Day (f b) (g c) (a -> (b, c))
#if defined(__GLASGOW_HASKELL__) && __GLASGOW_HASKELL__ > 707
  deriving Typeable
#endif

#if defined(__GLASGOW_HASKELL__) && __GLASGOW_HASKELL__ <= 707
instance (Typeable1 f, Typeable1 g) => Typeable1 (Day f g) where
    typeOf1 tfga = mkTyConApp dayTyCon [typeOf1 (fa tfga), typeOf1 (ga tfga)]
        where fa :: t f (g :: * -> *) a -> f a
              fa = undefined
              ga :: t (f :: * -> *) g a -> g a
              ga = undefined

dayTyCon :: TyCon
#if MIN_VERSION_base(4,4,0)
dayTyCon = mkTyCon3 "contravariant" "Data.Functor.Contravariant.Day" "Day"
#else
dayTyCon = mkTyCon "Data.Functor.Contravariant.Day.Day"
#endif

#endif

instance Contravariant (Day f g) where
  contramap f (Day fb gc abc) = Day fb gc (abc . f)

-- | Break apart the Day convolution of two contravariant functors.
runDay :: (Contravariant f, Contravariant g) => Day f g a -> (f a, g a)
runDay (Day fb gc abc) =
  ( contramap (fst . abc) fb
  , contramap (snd . abc) gc
  )

-- | Day convolution provides a monoidal product. The associativity
-- of this monoid is witnessed by 'assoc' and 'disassoc'.
--
-- @
-- 'assoc' . 'disassoc' = 'id'
-- 'disassoc' . 'assoc' = 'id'
-- @
assoc :: Day f (Day g h) a -> Day (Day f g) h a
assoc (Day fb (Day gd he cde) abc) = Day (Day fb gd id) he $ \a ->
  case cde <$> abc a of
    (b, (d, e)) -> ((b, d), e)

-- | Day convolution provides a monoidal product. The associativity
-- of this monoid is witnessed by 'assoc' and 'disassoc'.
--
-- @
-- 'assoc' . 'disassoc' = 'id'
-- 'disassoc' . 'assoc' = 'id'
-- @
disassoc :: Day (Day f g) h a -> Day f (Day g h) a
disassoc (Day (Day fd ge bde) hc abc) = Day fd (Day ge hc id) $ \a ->
  case abc a of
    (b, c) -> case bde b of
      (d, e) -> (d, (e, c))

-- | The monoid for Day convolution /in Haskell/ is symmetric.
swapped :: Day f g a -> Day g f a
swapped (Day fb gc abc) = Day gc fb (swap . abc)

-- | Proxy serves as the unit of Day convolution.
--
-- @
-- 'day1' '.' 'intro1' = 'id'
-- @
intro1 :: f a -> Day Proxy f a
intro1 fa = Day Proxy fa $ \a -> ((),a)

-- | Proxy serves as the unit of Day convolution.
--
-- @
-- 'day2' '.' 'intro2' = 'id'
-- @
intro2 :: f a -> Day f Proxy a
intro2 fa = Day fa Proxy $ \a -> (a,())

-- | In Haskell we can do general purpose elim (in a more general setting
-- it is only possible to eliminate the unit)
--
-- @
-- 'day1' '.' 'intro1' = 'id'
-- 'day1' = 'fst' . 'runDay'
-- @
day1 :: Contravariant f => Day f g a -> f a
day1 (Day fb _ abc) = contramap (fst . abc) fb

-- | In Haskell we can do general purpose elim (in a more general setting
-- it is only possible to eliminate the unit)
-- @
-- 'day2' '.' 'intro2' = 'id'
-- 'day2' = 'snd' . 'runDay'
-- @
day2 :: Contravariant g => Day f g a -> g a
day2 (Day _ gc abc) = contramap (snd . abc) gc
