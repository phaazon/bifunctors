-----------------------------------------------------------------------------
-- |
-- Module      :  Data.Semigroup.Foldable
-- Copyright   :  (C) 2011 Edward Kmett
-- License     :  BSD-style (see the file LICENSE)
--
-- Maintainer  :  Edward Kmett <ekmett@gmail.com>
-- Stability   :  provisional
-- Portability :  portable
--
----------------------------------------------------------------------------
module Data.Semigroup.Bifoldable
  ( Bifoldable1(..)
  , bitraverse1_
  , bifor1_
  , bisequenceA1_
  , bifoldMapDefault1
  ) where

import Control.Applicative
import Data.Bifoldable
import Data.Functor.Apply
import Data.Semigroup
import Data.Tagged
import Prelude hiding (foldr)

class Bifoldable t => Bifoldable1 t where
  bifold1 :: Semigroup m => t m m -> m
  bifold1 = bifoldMap1 id id
  {-# INLINE bifold1 #-}

  bifoldMap1 :: Semigroup m => (a -> m) -> (b -> m) -> t a b -> m
  bifoldMap1 f g = maybe (error "bifoldMap1") id . getOption . bifoldMap (Option . Just . f) (Option . Just . g)
  {-# INLINE bifoldMap1 #-}

instance Bifoldable1 Either where
  bifoldMap1 f _ (Left a) = f a
  bifoldMap1 _ g (Right b) = g b
  {-# INLINE bifoldMap1 #-}

instance Bifoldable1 (,) where
  bifoldMap1 f g (a, b) = f a <> g b
  {-# INLINE bifoldMap1 #-}

instance Bifoldable1 ((,,) x) where
  bifoldMap1 f g (_,a,b) = f a <> g b
  {-# INLINE bifoldMap1 #-}

instance Bifoldable1 ((,,,) x y) where
  bifoldMap1 f g (_,_,a,b) = f a <> g b
  {-# INLINE bifoldMap1 #-}

instance Bifoldable1 ((,,,,) x y z) where
  bifoldMap1 f g (_,_,_,a,b) = f a <> g b
  {-# INLINE bifoldMap1 #-}

instance Bifoldable1 Const where
  bifoldMap1 f _ (Const a) = f a
  {-# INLINE bifoldMap1 #-}

instance Bifoldable1 Tagged where
  bifoldMap1 _ g (Tagged b) = g b
  {-# INLINE bifoldMap1 #-}

newtype Act f a = Act { getAct :: f a }

instance Apply f => Semigroup (Act f a) where
  Act a <> Act b = Act (a .> b)
  {-# INLINE (<>) #-}

instance Functor f => Functor (Act f) where
  fmap f (Act a) = Act (f <$> a)
  {-# INLINE fmap #-}
  b <$ Act a = Act (b <$ a)
  {-# INLINE (<$) #-}

bitraverse1_ :: (Bifoldable1 t, Apply f) => (a -> f b) -> (c -> f d) -> t a c -> f ()
bitraverse1_ f g t = getAct (bifoldMap1 (Act . ignore . f) (Act . ignore . g) t)
{-# INLINE bitraverse1_ #-}

bifor1_ :: (Bifoldable1 t, Apply f) => t a c -> (a -> f b) -> (c -> f d) -> f ()
bifor1_ t f g = bitraverse1_ f g t
{-# INLINE bifor1_ #-}

ignore :: Functor f => f a -> f ()
ignore = (() <$)
{-# INLINE ignore #-}

bisequenceA1_ :: (Bifoldable1 t, Apply f) => t (f a) (f b) -> f ()
bisequenceA1_ t = getAct (bifoldMap1 (Act . ignore) (Act . ignore) t)
{-# INLINE bisequenceA1_ #-}

-- | Usable default for foldMap, but only if you define bifoldMap1 yourself
bifoldMapDefault1 :: (Bifoldable1 t, Monoid m) => (a -> m) -> (b -> m) -> t a b -> m
bifoldMapDefault1 f g = unwrapMonoid . bifoldMap (WrapMonoid . f) (WrapMonoid . g)
{-# INLINE bifoldMapDefault1 #-}
